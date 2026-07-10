import 'package:dio/dio.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../core/countries.dart';
import '../models/models.dart';
import '../models/period.dart';
import 'analytics_provider.dart';

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

  Future<dynamic> _get(String path, [Map<String, dynamic>? query]) async {
    if (_token == null) await _login();
    Options opts() => Options(headers: {'Authorization': 'Bearer $_token'});
    try {
      final r = await _dio.get(path, queryParameters: query, options: opts());
      return r.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _token = null;
        await _login();
        final r = await _dio.get(path, queryParameters: query, options: opts());
        return r.data;
      }
      rethrow;
    }
  }

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
    // Période précédente de même durée pour le delta (le champ `comparison` de
    // v3 n'est pas peuplé sans params dédiés → on interroge nous-mêmes).
    final span = w.end.difference(w.start);
    final prevStart = w.start.subtract(span).millisecondsSinceEpoch;

    final results = await Future.wait([
      _get('/api/websites/${site.id}/stats', {
        'startAt': w.startMs,
        'endAt': w.endMs,
      }),
      _get('/api/websites/${site.id}/stats', {
        'startAt': prevStart,
        'endAt': w.startMs,
      }).catchError((_) => <String, dynamic>{}),
    ]);
    final d = results[0] as Map;
    final prev = results[1] as Map;

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
    final sessions = _bin(d['sessions'], w.unit);

    // Buckets continus (Umami renvoie une série creuse) → chart propre.
    return _buckets(w)
        .map(
          (b) => SeriesPoint(
            b,
            sessions[b.millisecondsSinceEpoch] ?? 0,
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
    final apiType = switch (type) {
      MetricType.pages => 'path', // v3 : `url` a été renommé `path`
      MetricType.sources => 'referrer',
      MetricType.countries => 'country',
      MetricType.events => 'event',
    };
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
  Future<List<SeriesPoint>> eventSeries(Site site, DateWindow w) async {
    final tz = await _timezone();
    final d = await _get('/api/websites/${site.id}/events/series', {
      'startAt': w.startMs,
      'endAt': w.endMs,
      'unit': w.unit.api,
      'timezone': tz,
    });
    // La série renvoie {x:nom, t:date, y:nombre} : on somme par bucket temporel
    // (le champ date est `t`, pas `x`).
    final byBucket = <int, double>{};
    if (d is List) {
      for (final e in d) {
        final t = _parseX((e['t'] ?? '').toString());
        if (t == null) continue;
        final key = _truncate(t, w.unit).millisecondsSinceEpoch;
        final y = (e['y'] as num?)?.toDouble() ?? 0;
        byBucket.update(key, (v) => v + y, ifAbsent: () => y);
      }
    }
    return _buckets(w)
        .map((b) => SeriesPoint(b, byBucket[b.millisecondsSinceEpoch] ?? 0, 0))
        .toList(growable: false);
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
        return MetricRow(label: x.isEmpty ? '/' : x, value: y);
      case MetricType.sources:
        if (x.isEmpty) return MetricRow(label: 'Accès direct', value: y);
        final host = x.replaceFirst(RegExp(r'^https?://'), '').split('/').first;
        return MetricRow(label: host.isEmpty ? 'Accès direct' : host, value: y);
      case MetricType.countries:
        return MetricRow(label: countryName(x), value: y, code: x);
      case MetricType.events:
        return MetricRow(label: x.isEmpty ? '(sans nom)' : x, value: y);
    }
  }

  Map<int, double> _bin(dynamic series, TimeUnit unit) {
    final out = <int, double>{};
    if (series is! List) return out;
    for (final e in series) {
      final t = _parseX((e['x'] ?? '').toString());
      if (t == null) continue;
      final key = _truncate(t, unit).millisecondsSinceEpoch;
      final y = (e['y'] as num?)?.toDouble() ?? 0;
      out.update(key, (v) => v + y, ifAbsent: () => y);
    }
    return out;
  }

  DateTime? _parseX(String x) {
    if (x.isEmpty) return null;
    return DateTime.tryParse(x) ?? DateTime.tryParse(x.replaceFirst(' ', 'T'));
  }

  DateTime _truncate(DateTime t, TimeUnit u) => switch (u) {
    TimeUnit.hour => DateTime(t.year, t.month, t.day, t.hour),
    TimeUnit.day => DateTime(t.year, t.month, t.day),
    TimeUnit.month => DateTime(t.year, t.month, 1),
  };

  DateTime _advance(DateTime t, TimeUnit u) => switch (u) {
    TimeUnit.hour => t.add(const Duration(hours: 1)),
    TimeUnit.day => DateTime(t.year, t.month, t.day + 1),
    TimeUnit.month => DateTime(t.year, t.month + 1, 1),
  };

  List<DateTime> _buckets(DateWindow w) {
    final out = <DateTime>[];
    var c = _truncate(w.start, w.unit);
    // Borne de fin exclusive : `w.end` est plafonné au début de l'unité
    // suivante, donc on s'arrête avant (pas de bucket futur vide).
    final end = _truncate(w.end, w.unit);
    var guard = 0;
    while (c.isBefore(end) && guard < 2000) {
      out.add(c);
      c = _advance(c, w.unit);
      guard++;
    }
    return out;
  }
}
