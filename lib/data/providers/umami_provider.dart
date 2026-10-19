import 'package:dio/dio.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../core/countries.dart';
import '../../core/entities.dart';
import '../models/indicator.dart';
import '../models/indicator_result.dart';
import '../models/models.dart';
import '../models/period.dart';
import 'analytics_provider.dart';
import 'buckets.dart';
import 'umami_filters.dart';

/// Client Umami (self-hosted). Auth par login username/mot de passe → token JWT
/// Bearer, réutilisé et rafraîchi automatiquement sur 401.
class UmamiProvider extends AnalyticsProvider {
  UmamiProvider(super.account, super.creds) {
    _dio = Dio(
      BaseOptions(
        baseUrl: normalizeBase(account.baseUrl),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 25),
        headers: const {'accept': 'application/json'},
      ),
    );
  }

  late final Dio _dio;
  String? _token;
  bool _isAdmin = false;
  String? _tz;

  /// Ajoute https:// si absent et retire tout chemin/slash final.
  static String normalizeBase(String raw) {
    var s = raw.trim();
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'https://$s';
    }
    final u = Uri.parse(s);
    return '${u.scheme}://${u.host}${u.hasPort ? ':${u.port}' : ''}';
  }

  Future<String> _timezone() async {
    if (_tz != null) return _tz!;
    try {
      _tz = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {
      _tz = 'UTC';
    }
    return _tz!;
  }

  Future<void> _login() async {
    final r = await _dio.post(
      '/api/auth/login',
      data: {'username': creds['username'], 'password': creds['password']},
    );
    final data = r.data;
    final token = (data is Map) ? data['token'] : null;
    if (token is! String || token.isEmpty) {
      throw StateError('Réponse de login Umami inattendue');
    }
    _token = token;
    final user = (data is Map) ? data['user'] : null;
    _isAdmin = user is Map && (user['isAdmin'] == true || user['role'] == 'admin');
  }

  /// Exécute [call] avec le Bearer ; sur 401, un seul re-login puis un rejeu.
  Future<dynamic> _authed(
    Future<Response<dynamic>> Function(Options) call,
  ) async {
    if (_token == null) await _login();
    Options opts() => Options(headers: {'Authorization': 'Bearer $_token'});
    try {
      return (await call(opts())).data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _token = null;
        await _login();
        return (await call(opts())).data;
      }
      rethrow;
    }
  }

  Future<dynamic> _get(String path, [Map<String, dynamic>? query]) =>
      _authed((o) => _dio.get(path, queryParameters: query, options: o));

  Future<dynamic> _post(String path, Map<String, dynamic> body) =>
      _authed((o) => _dio.post(path, data: body, options: o));

  @override
  Future<int> verify() async {
    final sites = await listSites();
    return sites.length;
  }

  @override
  Future<List<Site>> listSites() async {
    // v3 : `/api/websites` ne renvoie que les sites possédés/partagés. Un compte
    // admin doit passer par `/api/admin/websites` pour tout voir.
    if (_token == null) await _login();
    final path = _isAdmin ? '/api/admin/websites' : '/api/websites';
    final data = await _get(path, {'pageSize': 500});
    final list = data is Map ? (data['data'] ?? data['websites'] ?? []) : data;
    return (list as List)
        .map(
          (w) => Site(
            id: w['id'].toString(),
            accountId: account.id,
            name: (w['name'] ?? w['domain'] ?? '').toString(),
            domain: (w['domain'] ?? '').toString(),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<StatsSummary> summary(Site site, DateWindow w) async {
    final d = await _get('/api/websites/${site.id}/stats', {
      'startAt': w.startMs,
      'endAt': w.endMs,
    }) as Map;
    // v3 peuple `comparison` avec la période précédente de même durée — vérifié
    // au chiffre près contre un appel manuel. Un 2e aller-retour serait payé
    // pour chaque site de l'accueil, à chaque rafraîchissement.
    final prev = d['comparison'] is Map
        ? (d['comparison'] as Map)
        : await _get('/api/websites/${site.id}/stats', {
            'startAt': w.start.subtract(w.end.difference(w.start)).millisecondsSinceEpoch,
            'endAt': w.startMs,
          }).catchError((_) => <String, dynamic>{}) as Map;

    int n(dynamic v) => _vp(v).$1;
    final visits = n(d['visits']);
    return StatsSummary(
      visitors: n(d['visitors'] ?? d['uniques']),
      prevVisitors: prev.isEmpty ? null : n(prev['visitors'] ?? prev['uniques']),
      pageviews: n(d['pageviews']),
      prevPageviews: prev.isEmpty ? null : n(prev['pageviews']),
      visits: visits,
      bounceRatePct: visits == 0 ? 0 : n(d['bounces']) / visits * 100,
      avgVisitSec: visits == 0 ? 0 : n(d['totaltime']) ~/ visits,
    );
  }

  @override
  Future<List<SeriesPoint>> series(Site site, DateWindow w) async {
    final tz = await _timezone();
    final d = await _get('/api/websites/${site.id}/pageviews', {
      'startAt': w.startMs,
      'endAt': w.endMs,
      'unit': w.unit.api,
      'timezone': tz,
    }) as Map;

    final views = _bin(d['pageviews'], w.unit);
    // La série `sessions` d'Umami compte les visiteurs *uniques* par bucket (et
    // non les visites/`visit_id`) → c'est la courbe verte « Visiteurs ».
    final visitors = _bin(d['sessions'], w.unit);

    // Buckets continus (Umami renvoie une série creuse) → chart propre.
    return bucketsOf(w)
        .map(
          (b) => SeriesPoint(
            b,
            visitors[b.millisecondsSinceEpoch] ?? 0,
            views[b.millisecondsSinceEpoch] ?? 0,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<int> active(Site site) async {
    final d = await _get('/api/websites/${site.id}/active');
    if (d is List) {
      if (d.isEmpty) return 0;
      final first = d.first;
      return ((first is Map ? first['x'] : first) as num?)?.round() ?? 0;
    }
    if (d is Map) {
      return ((d['visitors'] ?? d['x'] ?? 0) as num).round();
    }
    if (d is num) return d.round();
    return 0;
  }

  @override
  Future<List<MetricRow>> metric(
    Site site,
    DateWindow w,
    MetricType type, {
    int limit = 8,
  }) async {
    // Les clés de dimension sont exactement celles de l'API v3 (`url` y a été
    // renommé `path`).
    final apiType = type.key;
    final d = await _get('/api/websites/${site.id}/metrics', {
      'startAt': w.startMs,
      'endAt': w.endMs,
      'type': apiType,
      'limit': limit,
    });
    final list = (d is List) ? d : const [];
    return list
        .map((e) => _row(type, (e['x'] ?? '').toString(), (e['y'] as num?)?.round() ?? 0))
        .toList(growable: false);
  }

  @override
  Future<DataRange?> dataRange(Site site) async {
    final d = await _get('/api/websites/${site.id}/daterange');
    if (d is! Map) return null;
    final start = DateTime.tryParse('${d['startDate']}');
    final end = DateTime.tryParse('${d['endDate']}');
    if (start == null || end == null) return null;
    return DataRange(start.toLocal(), end.toLocal());
  }

  @override
  Future<List<LivePage>> livePages(Site site) async {
    final now = DateTime.now();
    final w = DateWindow(
      now.subtract(const Duration(minutes: 5)),
      now,
      TimeUnit.hour,
    );
    final rows = await metric(site, w, MetricType.pages, limit: 5);
    return rows.map((r) => LivePage(r.label, r.value)).toList(growable: false);
  }

  @override
  Future<List<EventSeries>> eventSeries(Site site, DateWindow w) async {
    final tz = await _timezone();
    final d = await _get('/api/websites/${site.id}/events/series', {
      'startAt': w.startMs,
      'endAt': w.endMs,
      'unit': w.unit.api,
      'timezone': tz,
    });
    // La série renvoie {x:nom, t:date, y:nombre} : on regroupe par nom
    // d'événement, puis par bucket temporel (le champ date est `t`).
    final byName = <String, Map<int, double>>{};
    if (d is List) {
      for (final e in d) {
        final name = (e['x'] ?? '').toString();
        final t = _parseX((e['t'] ?? '').toString());
        if (t == null) continue;
        final key = truncateBucket(t, w.unit).millisecondsSinceEpoch;
        final y = (e['y'] as num?)?.toDouble() ?? 0;
        (byName[name] ??= {}).update(key, (v) => v + y, ifAbsent: () => y);
      }
    }
    final buckets = bucketsOf(w);
    final out = byName.entries.map((entry) {
      final points = buckets
          .map((b) =>
              SeriesPoint(b, entry.value[b.millisecondsSinceEpoch] ?? 0, 0))
          .toList(growable: false);
      final total = entry.value.values.fold<double>(0, (a, b) => a + b).round();
      return EventSeries(
        name: entry.key.isEmpty ? '(sans nom)' : entry.key,
        points: points,
        total: total,
      );
    }).toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return out;
  }

  // --- indicateurs -----------------------------------------------------------

  @override
  Set<IndicatorKind> get supportedIndicators => IndicatorKind.values.toSet();

  @override
  Future<List<SeriesPoint>> eventCountSeries(
    Site site,
    DateWindow w,
    EventQuery q,
  ) async {
    final tz = await _timezone();
    final d = await _get('/api/websites/${site.id}/events/series', {
      'startAt': w.startMs,
      'endAt': w.endMs,
      'unit': w.unit.api,
      'timezone': tz,
      'event': q.event,
      ...umamiEventFilterParams(q.filters),
    });
    final counts = <int, double>{};
    if (d is List) {
      for (final e in d) {
        // Garde-fou : ne sommer que l'événement demandé.
        if ((e['x'] ?? '').toString() != q.event) continue;
        final t = _parseX((e['t'] ?? '').toString());
        if (t == null) continue;
        final key = truncateBucket(t, w.unit).millisecondsSinceEpoch;
        final y = (e['y'] as num?)?.toDouble() ?? 0;
        counts.update(key, (v) => v + y, ifAbsent: () => y);
      }
    }
    return bucketsOf(w)
        .map((b) => SeriesPoint(b, counts[b.millisecondsSinceEpoch] ?? 0, 0))
        .toList(growable: false);
  }

  @override
  Future<List<FunnelStepResult>> funnel(
    Site site,
    DateWindow w,
    FunnelIndicator f,
  ) async {
    final d = await _post('/api/reports/funnel', {
      'websiteId': site.id,
      'type': 'funnel',
      'filters': <String, dynamic>{},
      'parameters': {
        'startDate': w.start.toUtc().toIso8601String(),
        'endDate': w.end.toUtc().toIso8601String(),
        'window': f.windowMinutes,
        'steps': [
          for (final s in f.steps)
            {
              'type': 'event',
              'value': s.event,
              if (s.filters.isNotEmpty)
                'filters': [for (final x in s.filters) _funnelFilter(x)],
            },
        ],
      },
    });
    final rows = d is List ? d : const [];
    return [
      for (var i = 0; i < rows.length && i < f.steps.length; i++)
        FunnelStepResult(
          event: f.steps[i].event,
          filters: f.steps[i].filters,
          visitors: (rows[i]['visitors'] as num?)?.round() ?? 0,
          remaining: (rows[i]['remaining'] as num?)?.toDouble() ?? 0,
          dropoff: (rows[i]['dropoff'] as num?)?.toDouble(),
        ),
    ];
  }

  /// Les filtres d'étape d'Umami n'acceptent que du texte : pas de comparaison
  /// numérique.
  static Map<String, String> _funnelFilter(EventFilter x) {
    const allowed = {
      FilterOp.eq,
      FilterOp.neq,
      FilterOp.contains,
      FilterOp.notContains,
    };
    if (!allowed.contains(x.op)) {
      throw ArgumentError(
        "Opérateur « ${x.op.label} » indisponible dans un entonnoir Umami",
      );
    }
    return {'property': x.property, 'operator': x.op.api, 'value': x.value};
  }

  @override
  Future<List<MetricRow>> propertyValues(
    Site site,
    DateWindow w,
    String event,
    String property, {
    int limit = 30,
  }) async {
    final d = await _get('/api/websites/${site.id}/event-data/values', {
      'startAt': w.startMs,
      'endAt': w.endMs,
      'event': event,
      'propertyName': property,
    });
    final list = d is List ? d : const [];
    final rows = [
      for (final e in list)
        MetricRow(
          label: (e['value'] ?? '').toString(),
          value: (e['total'] as num?)?.round() ?? 0,
          code: (e['value'] ?? '').toString(),
        ),
    ]..sort((a, b) => b.value.compareTo(a.value));
    return rows.take(limit).toList(growable: false);
  }

  @override
  Future<List<EventProperty>> eventProperties(
    Site site,
    DateWindow w,
    String event,
  ) async {
    final d = await _get('/api/websites/${site.id}/event-data/properties', {
      'startAt': w.startMs,
      'endAt': w.endMs,
      'event': event,
    });
    final seen = <String, EventProperty>{};
    if (d is List) {
      for (final e in d) {
        final name = (e['propertyName'] ?? '').toString();
        if (name.isEmpty) continue;
        seen.putIfAbsent(
          name,
          () => EventProperty(name, PropertyType.fromCode(e['dataType'] as int?)),
        );
      }
    }
    return seen.values.toList(growable: false);
  }

  // --- helpers ---------------------------------------------------------------

  /// Extrait (value, prev) d'un champ Umami qui peut être {value,prev} ou un nombre.
  (int, int?) _vp(dynamic v) {
    if (v is Map) {
      return (
        (v['value'] as num?)?.round() ?? 0,
        (v['prev'] as num?)?.round(),
      );
    }
    if (v is num) return (v.round(), null);
    return (0, null);
  }

  MetricRow _row(MetricType type, String x, int y) {
    switch (type) {
      case MetricType.pages:
      case MetricType.entryPages:
      case MetricType.exitPages:
        return MetricRow(label: x.isEmpty ? '/' : x, value: y, code: x);
      case MetricType.referrers:
        if (x.isEmpty) return MetricRow(label: 'Accès direct', value: y);
        final host = x.replaceFirst(RegExp(r'^https?://'), '').split('/').first;
        if (host.isEmpty) return MetricRow(label: 'Accès direct', value: y);
        return MetricRow(label: host, value: y, code: host);
      case MetricType.channels:
        return MetricRow(label: channelName(x), value: y, code: x);
      case MetricType.countries:
        return MetricRow(label: countryName(x), value: y, code: x);
      case MetricType.browsers:
        return MetricRow(label: browserName(x), value: y, code: x);
      case MetricType.devices:
        return MetricRow(label: deviceName(x), value: y, code: x);
      case MetricType.languages:
        return MetricRow(label: languageName(x), value: y, code: x);
      case MetricType.operatingSystems:
        return MetricRow(
          label: x.isEmpty ? 'Inconnu' : x,
          value: y,
          code: x,
        );
      case MetricType.pageTitles:
      case MetricType.queries:
      case MetricType.screens:
      case MetricType.regions:
      case MetricType.cities:
      case MetricType.events:
        return MetricRow(
          label: x.isEmpty ? 'Inconnu' : x,
          value: y,
          code: x,
        );
    }
  }

  Map<int, double> _bin(dynamic series, TimeUnit unit) {
    final out = <int, double>{};
    if (series is! List) return out;
    for (final e in series) {
      final t = _parseX((e['x'] ?? '').toString());
      if (t == null) continue;
      final key = truncateBucket(t, unit).millisecondsSinceEpoch;
      final y = (e['y'] as num?)?.toDouble() ?? 0;
      out.update(key, (v) => v + y, ifAbsent: () => y);
    }
    return out;
  }

  DateTime? _parseX(String x) {
    if (x.isEmpty) return null;
    return DateTime.tryParse(x) ?? DateTime.tryParse(x.replaceFirst(' ', 'T'));
  }
}
