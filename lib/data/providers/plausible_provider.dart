import 'package:dio/dio.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';

import '../../core/countries.dart';
import '../models/models.dart';
import '../models/period.dart';
import 'analytics_provider.dart';

/// Client Plausible (Stats API v2 — `POST /api/v2/query`). La Stats API ne liste
/// pas les sites → on tente la **Sites API** (`GET /api/v1/sites`) pour lister
/// automatiquement (self-hosted ou plan Enterprise) ; sinon on retombe sur le
/// domaine saisi manuellement. Chaque requête cible `site.id` (le domaine).
class PlausibleProvider extends AnalyticsProvider {
  PlausibleProvider(super.account, super.creds) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _normalizeBase(account.baseUrl),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 25),
        headers: {
          'accept': 'application/json',
          'content-type': 'application/json',
          'Authorization': 'Bearer ${creds['apiKey']}',
        },
      ),
    );
  }

  late final Dio _dio;
  String? _tz;

  /// Domaine saisi manuellement (facultatif). Vide → on tente la Sites API.
  String get _configuredSite => (creds['siteId'] ?? '').trim();

  static String _normalizeBase(String raw) {
    var s = raw.trim().isEmpty ? 'plausible.io' : raw.trim();
    if (!s.startsWith('http://') && !s.startsWith('https://')) s = 'https://$s';
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

  static final _dateFmt = DateFormat('yyyy-MM-dd');
  static final _dtFmt = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  Future<Map<String, dynamic>> _query(Map<String, dynamic> body) async {
    final r = await _dio.post('/api/v2/query', data: body);
    return (r.data as Map).cast<String, dynamic>();
  }

  List<dynamic> _rows(Map<String, dynamic> res) =>
      (res['results'] as List?) ?? const [];

  @override
  Future<int> verify() async {
    final api = await _listViaApi();
    if (api.isNotEmpty) return api.length;
    // Pas de Sites API (clé Stats simple) → on valide le domaine saisi.
    final id = _configuredSite;
    if (id.isEmpty) {
      throw StateError(
        'Renseignez un domaine, ou utilisez une clé avec accès « Sites » '
        'pour lister automatiquement.',
      );
    }
    await _query({'site_id': id, 'metrics': ['visitors'], 'date_range': '7d'});
    return 1;
  }

  @override
  Future<List<Site>> listSites() async {
    final api = await _listViaApi();
    if (api.isNotEmpty) return api;
    final id = _configuredSite;
    if (id.isEmpty) return const [];
    return [Site(id: id, accountId: account.id, name: id, domain: id)];
  }

  /// Liste les sites via la **Sites API** de Plausible (`GET /api/v1/sites`,
  /// paginée). Nécessite une clé avec accès « Sites » (self-hosted ou plan
  /// Enterprise) : renvoie une liste vide si l'endpoint n'est pas disponible.
  Future<List<Site>> _listViaApi() async {
    final out = <Site>[];
    String? after;
    for (var guard = 0; guard < 20; guard++) {
      try {
        final r = await _dio.get('/api/v1/sites', queryParameters: {
          'limit': 100,
          if (after != null && after.isNotEmpty) 'after': after,
        });
        final data = (r.data as Map).cast<String, dynamic>();
        final sites = (data['sites'] as List?) ?? const [];
        for (final s in sites) {
          final d = (s['domain'] ?? '').toString();
          if (d.isNotEmpty) {
            out.add(Site(id: d, accountId: account.id, name: d, domain: d));
          }
        }
        after = (data['meta'] as Map?)?['after']?.toString();
        if (sites.isEmpty || after == null || after.isEmpty) break;
      } on DioException {
        // 401/402/403/404 : Sites API indisponible pour cette clé/ce plan.
        return const [];
      }
    }
    return out;
  }

  Future<int> _visitorsFor(String siteId, List<String> range) async {
    final res = await _query({
      'site_id': siteId,
      'metrics': ['visitors'],
      'date_range': range,
    });
    final rows = _rows(res);
    if (rows.isEmpty) return 0;
    return ((rows.first['metrics'] as List).first as num).round();
  }

  @override
  Future<StatsSummary> summary(Site site, DateWindow w) async {
    final metrics = [
      'visitors',
      'pageviews',
      'visits',
      'bounce_rate',
      'visit_duration',
    ];
    final res = await _query({
      'site_id': site.id,
      'metrics': metrics,
      'date_range': [_dateFmt.format(w.start), _dateFmt.format(w.end)],
      'timezone': await _timezone(),
    });
    final rows = _rows(res);
    final m = rows.isEmpty
        ? List.filled(metrics.length, 0)
        : (rows.first['metrics'] as List);
    num at(int i) => (m.length > i ? m[i] as num? : null) ?? 0;

    // Période précédente (même durée) pour le delta.
    final span = w.end.difference(w.start);
    int? prevVisitors;
    try {
      prevVisitors = await _visitorsFor(site.id, [
        _dateFmt.format(w.start.subtract(span)),
        _dateFmt.format(w.start),
      ]);
    } catch (_) {
      prevVisitors = null;
    }

    return StatsSummary(
      visitors: at(0).round(),
      pageviews: at(1).round(),
      visits: at(2).round(),
      bounceRatePct: at(3).toDouble(),
      avgVisitSec: at(4).round(),
      prevVisitors: prevVisitors,
    );
  }

  @override
  Future<List<SeriesPoint>> series(Site site, DateWindow w) async {
    final dim = switch (w.unit) {
      TimeUnit.hour => 'time:hour',
      TimeUnit.day => 'time:day',
      TimeUnit.month => 'time:month',
    };
    final res = await _query({
      'site_id': site.id,
      // Deux séries pour le graphe : visiteurs uniques (vert) + pages vues (gris).
      'metrics': ['visitors', 'pageviews'],
      'date_range': [_dtFmt.format(w.start), _dtFmt.format(w.end)],
      'dimensions': [dim],
      'timezone': await _timezone(),
    });
    return _rows(res)
        .map((r) {
          final dims = r['dimensions'] as List;
          final mm = r['metrics'] as List;
          final t = DateTime.tryParse(dims.first.toString()) ??
              DateTime.tryParse('${dims.first}T00:00:00');
          if (t == null) return null;
          return SeriesPoint(
            t,
            (mm[0] as num).toDouble(), // visiteurs
            (mm[1] as num).toDouble(), // pages vues
          );
        })
        .whereType<SeriesPoint>()
        .toList(growable: false);
  }

  @override
  Future<int> active(Site site) async {
    final r = await _dio.get(
      '/api/v1/stats/realtime/visitors',
      queryParameters: {'site_id': site.id},
    );
    return (r.data as num?)?.round() ?? 0;
  }

  @override
  Future<List<MetricRow>> metric(
    Site site,
    DateWindow w,
    MetricType type, {
    int limit = 8,
  }) async {
    final dim = switch (type) {
      MetricType.pages => 'event:page',
      MetricType.sources => 'visit:source',
      MetricType.countries => 'visit:country',
      MetricType.events => 'event:name',
    };
    final metric = type == MetricType.events ? 'events' : 'visitors';
    final res = await _query({
      'site_id': site.id,
      'metrics': [metric],
      'date_range': [_dateFmt.format(w.start), _dateFmt.format(w.end)],
      'dimensions': [dim],
      'limit': limit + (type == MetricType.events ? 1 : 0),
    });
    final rows = _rows(res).map((r) {
      final label = (r['dimensions'] as List).first.toString();
      final value = ((r['metrics'] as List).first as num).round();
      if (type == MetricType.countries) {
        return MetricRow(label: countryName(label), value: value, code: label);
      }
      return MetricRow(label: label.isEmpty ? '/' : label, value: value);
    }).toList();
    if (type == MetricType.events) {
      // « pageview » n'est pas un événement personnalisé.
      return rows.where((r) => r.label != 'pageview').take(limit).toList();
    }
    return rows;
  }

  @override
  Future<List<EventSeries>> eventSeries(Site site, DateWindow w) async {
    final timeDim = switch (w.unit) {
      TimeUnit.hour => 'time:hour',
      TimeUnit.day => 'time:day',
      TimeUnit.month => 'time:month',
    };
    final res = await _query({
      'site_id': site.id,
      'metrics': ['events'],
      'date_range': [_dtFmt.format(w.start), _dtFmt.format(w.end)],
      'dimensions': [timeDim, 'event:name'],
      'timezone': await _timezone(),
    });
    // Regroupe par nom d'événement (exclut « pageview »).
    final byName = <String, Map<int, double>>{};
    for (final r in _rows(res)) {
      final dims = r['dimensions'] as List;
      final name = dims.length > 1 ? dims[1].toString() : '';
      if (name == 'pageview') continue;
      final t = DateTime.tryParse(dims.first.toString()) ??
          DateTime.tryParse('${dims.first}T00:00:00');
      if (t == null) continue;
      final v = ((r['metrics'] as List).first as num).toDouble();
      (byName[name] ??= {}).update(
        t.millisecondsSinceEpoch,
        (x) => x + v,
        ifAbsent: () => v,
      );
    }
    final out = byName.entries.map((entry) {
      final points = entry.value.entries
          .map((e) => SeriesPoint(
              DateTime.fromMillisecondsSinceEpoch(e.key), e.value, 0))
          .toList()
        ..sort((a, b) => a.t.compareTo(b.t));
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

  @override
  Future<List<LivePage>> livePages(Site site) async {
    final res = await _query({
      'site_id': site.id,
      'metrics': ['visitors'],
      'date_range': 'realtime',
      'dimensions': ['event:page'],
      'limit': 5,
    });
    return _rows(res).map((r) {
      final path = (r['dimensions'] as List).first.toString();
      final n = ((r['metrics'] as List).first as num).round();
      return LivePage(path.isEmpty ? '/' : path, n);
    }).toList(growable: false);
  }
}
