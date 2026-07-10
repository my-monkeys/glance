import 'package:dio/dio.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';

import '../../core/countries.dart';
import '../models/models.dart';
import '../models/period.dart';
import 'analytics_provider.dart';

/// Client Plausible (Stats API v2 — `POST /api/v2/query`). Un compte Plausible
/// = un domaine (`site_id`), Plausible n'exposant pas de liste de sites via la
/// Stats API. Implémenté d'après la doc officielle ; à valider sur instance.
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

  String get _siteId => creds['siteId'] ?? account.baseUrl;

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
    await _query({
      'site_id': _siteId,
      'metrics': ['visitors'],
      'date_range': '7d',
    });
    return 1;
  }

  @override
  Future<List<Site>> listSites() async {
    return [
      Site(id: _siteId, accountId: account.id, name: _siteId, domain: _siteId),
    ];
  }

  Future<int> _visitorsFor(List<String> range) async {
    final res = await _query({
      'site_id': _siteId,
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
      'site_id': _siteId,
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
      prevVisitors = await _visitorsFor([
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
      'site_id': _siteId,
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
            (mm[0] as num).toDouble(),
            (mm[1] as num).toDouble(),
          );
        })
        .whereType<SeriesPoint>()
        .toList(growable: false);
  }

  @override
  Future<int> active(Site site) async {
    final r = await _dio.get(
      '/api/v1/stats/realtime/visitors',
      queryParameters: {'site_id': _siteId},
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
      'site_id': _siteId,
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
  Future<List<SeriesPoint>> eventSeries(Site site, DateWindow w) async {
    final dim = switch (w.unit) {
      TimeUnit.hour => 'time:hour',
      TimeUnit.day => 'time:day',
      TimeUnit.month => 'time:month',
    };
    final res = await _query({
      'site_id': _siteId,
      'metrics': ['events'],
      'date_range': [_dtFmt.format(w.start), _dtFmt.format(w.end)],
      'dimensions': [dim],
      'timezone': await _timezone(),
    });
    return _rows(res)
        .map((r) {
          final dims = r['dimensions'] as List;
          final t = DateTime.tryParse(dims.first.toString()) ??
              DateTime.tryParse('${dims.first}T00:00:00');
          if (t == null) return null;
          final v = ((r['metrics'] as List).first as num).toDouble();
          return SeriesPoint(t, v, 0);
        })
        .whereType<SeriesPoint>()
        .toList(growable: false);
  }

  @override
  Future<List<LivePage>> livePages(Site site) async {
    final res = await _query({
      'site_id': _siteId,
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
