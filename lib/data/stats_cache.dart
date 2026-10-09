import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/dimension.dart';
import 'models/models.dart';
import 'models/period.dart';
import '../state/home_data.dart';

/// Cache disque des stats (résumé + série + métriques) pour un affichage
/// instantané au **démarrage à froid** : on montre la dernière valeur connue tout
/// de suite, puis le provider rafraîchit derrière (stale-while-revalidate).
///
/// Le cache mémoire de session (`cacheSession`) couvre déjà la navigation en
/// cours ; celui-ci survit à la fermeture de l'app.
///
/// **Clé stable par période et granularité** (`7j@day`, `7j@hour`…), pas par
/// fenêtre absolue : la fenêtre alignée bouge chaque jour, donc on garde « le
/// dernier 7 j connu » et le refetch corrige les chiffres. Les fenêtres de
/// navigation jour-à-jour, personnalisées ou « Tout » ne sont pas persistées
/// (elles renvoient un bucket null).
class StatsCache {
  StatsCache(this._prefs);
  final SharedPreferences _prefs;

  static const _prefix = 'glance.cache2.';

  /// Périodes « live » (offset 0) persistables. Une fenêtre qui n'égale aucune
  /// de leurs fenêtres courantes est une navigation ponctuelle → non persistée.
  static const _buckets = [
    Period.today,
    Period.h24,
    Period.d7,
    Period.d30,
    Period.thisMonth,
    Period.m12,
    Period.thisYear,
  ];

  /// Au-delà de cet âge, la donnée cachée est ignorée (on repart sur un
  /// squelette) : plus la granularité est fine, plus vite elle devient trompeuse.
  static Duration _maxAge(TimeUnit u) => switch (u) {
    TimeUnit.hour => const Duration(hours: 6),
    TimeUnit.day => const Duration(days: 3),
    TimeUnit.month => const Duration(days: 10),
  };

  String? _bucket(DateWindow w) {
    for (final per in _buckets) {
      // La granularité fait partie de l'identité : « 7 j en heures » et
      // « 7 j en jours » sont deux séries différentes. Sans elle, une
      // granularité forcée ne trouverait aucune correspondance et le cache
      // disque s'éteindrait sans rien dire.
      if (per.window(unit: w.unit) == w) return '${per.key}@${w.unit.api}';
    }
    return null;
  }

  String _key(String kind, Site s, String bucket) =>
      '$_prefix$kind.${s.accountId}.${s.id}.$bucket';

  Map<String, dynamic>? _read(
    String kind,
    Site s,
    DateWindow w, {
    bool ignoreAge = false,
  }) {
    final bucket = _bucket(w);
    if (bucket == null) return null;
    final raw = _prefs.getString(_key(kind, s, bucket));
    if (raw == null) return null;
    final env = jsonDecode(raw) as Map<String, dynamic>;
    if (!ignoreAge) {
      final age =
          DateTime.now().millisecondsSinceEpoch - (env['at'] as int? ?? 0);
      if (age > _maxAge(w.unit).inMilliseconds) return null;
    }
    return env['d'] as Map<String, dynamic>;
  }

  void _write(String kind, Site s, DateWindow w, Map<String, dynamic> data) {
    final bucket = _bucket(w);
    if (bucket == null) return;
    _prefs.setString(
      _key(kind, s, bucket),
      jsonEncode({'at': DateTime.now().millisecondsSinceEpoch, 'd': data}),
    );
  }

  // --- Home (résumé + série) ---

  SiteStats? readStats(Site s, DateWindow w) {
    final d = _read('stats', s, w);
    return d == null ? null : _statsFromJson(d);
  }

  void writeStats(Site s, DateWindow w, SiteStats v) =>
      _write('stats', s, w, _statsToJson(v));

  // --- Métriques, une entrée par dimension ---
  //
  // Un seul enregistrement par (site, période), indexé par dimension : une clé
  // de préférences par dimension ferait ~2 000 entrées pour vingt sites, dans
  // un fichier relu et réécrit à chaque écriture.

  List<MetricRow>? readMetric(Site s, DateWindow w, MetricType type) {
    final entry = _read('m', s, w)?[type.key];
    if (entry is! Map) return null;
    // Horodatage **par dimension** : écrire les navigateurs ne doit pas
    // rajeunir des chemins récupérés cinq heures plus tôt.
    final age = DateTime.now().millisecondsSinceEpoch - (entry['at'] as int? ?? 0);
    if (age > _maxAge(w.unit).inMilliseconds) return null;
    return _rowsFromJson(entry['r'] as List<dynamic>);
  }

  void writeMetric(
    Site s,
    DateWindow w,
    MetricType type,
    List<MetricRow> rows,
  ) {
    final data = _read('m', s, w, ignoreAge: true) ?? <String, dynamic>{};
    data[type.key] = {
      'at': DateTime.now().millisecondsSinceEpoch,
      'r': _rowsToJson(rows),
    };
    _write('m', s, w, data);
  }
}

// --- Sérialisation (clés courtes, live/livePages non persistés) ---

Map<String, dynamic> _summaryToJson(StatsSummary s) => {
  'v': s.visitors,
  'p': s.pageviews,
  'vi': s.visits,
  'b': s.bounceRatePct,
  'a': s.avgVisitSec,
  if (s.prevVisitors != null) 'pv': s.prevVisitors,
  if (s.prevPageviews != null) 'pp': s.prevPageviews,
};

StatsSummary _summaryFromJson(Map<String, dynamic> j) => StatsSummary(
  visitors: j['v'] as int,
  pageviews: j['p'] as int,
  visits: j['vi'] as int,
  bounceRatePct: (j['b'] as num).toDouble(),
  avgVisitSec: j['a'] as int,
  prevVisitors: j['pv'] as int?,
  prevPageviews: j['pp'] as int?,
);

List<Map<String, dynamic>> _seriesToJson(List<SeriesPoint> pts) => [
  for (final p in pts)
    {'t': p.t.millisecondsSinceEpoch, 'v': p.visitors, 'p': p.pageviews},
];

List<SeriesPoint> _seriesFromJson(List<dynamic> j) => [
  for (final e in j.cast<Map<String, dynamic>>())
    SeriesPoint(
      DateTime.fromMillisecondsSinceEpoch(e['t'] as int),
      (e['v'] as num).toDouble(),
      (e['p'] as num).toDouble(),
    ),
];

List<Map<String, dynamic>> _rowsToJson(List<MetricRow> rows) => [
  for (final r in rows)
    {'l': r.label, 'v': r.value, if (r.code != null) 'c': r.code},
];

List<MetricRow> _rowsFromJson(List<dynamic> j) => [
  for (final e in j.cast<Map<String, dynamic>>())
    MetricRow(label: e['l'] as String, value: e['v'] as int, code: e['c'] as String?),
];

Map<String, dynamic> _statsToJson(SiteStats v) => {
  's': _summaryToJson(v.summary),
  'se': _seriesToJson(v.series),
  if (v.refSeries != null) 'rf': _seriesToJson(v.refSeries!),
  if (v.daily != null) 'dh': _seriesToJson(v.daily!),
};

SiteStats _statsFromJson(Map<String, dynamic> j) => SiteStats(
  summary: _summaryFromJson(j['s'] as Map<String, dynamic>),
  series: _seriesFromJson(j['se'] as List<dynamic>),
  refSeries:
      j['rf'] == null ? null : _seriesFromJson(j['rf'] as List<dynamic>),
  daily: j['dh'] == null ? null : _seriesFromJson(j['dh'] as List<dynamic>),
);
