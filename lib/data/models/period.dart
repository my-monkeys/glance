import 'package:flutter/foundation.dart';

/// Granularité des points de série renvoyés par le provider.
///
/// Pas de `year` : Umami la ramène de toute façon à `month` côté serveur, et
/// recoller les 12 mois côté client surcompterait les visiteurs uniques (la
/// même personne compte dans plusieurs mois) — la courbe ne collerait plus au
/// total affiché juste au-dessus.
enum TimeUnit { hour, day, month }

extension TimeUnitApi on TimeUnit {
  String get api => switch (this) {
    TimeUnit.hour => 'hour',
    TimeUnit.day => 'day',
    TimeUnit.month => 'month',
  };

  /// Libellé du sélecteur de granularité.
  String get label => switch (this) {
    TimeUnit.hour => 'Heure',
    TimeUnit.day => 'Jour',
    TimeUnit.month => 'Mois',
  };

  /// Durée indicative d'un bucket, pour estimer leur nombre.
  Duration get nominal => switch (this) {
    TimeUnit.hour => const Duration(hours: 1),
    TimeUnit.day => const Duration(days: 1),
    TimeUnit.month => const Duration(days: 30),
  };

  static TimeUnit? fromApi(String? s) => switch (s) {
    'hour' => TimeUnit.hour,
    'day' => TimeUnit.day,
    'month' => TimeUnit.month,
    _ => null,
  };
}

/// Fenêtre temporelle résolue à un instant donné.
@immutable
class DateWindow {
  const DateWindow(this.start, this.end, this.unit, {this.allTime = false});
  final DateTime start;
  final DateTime end;
  final TimeUnit unit;

  /// Fenêtre « tout l'historique ». Elle ne se compare à rien (pas de période
  /// précédente) et son début peut être arbitraire — l'information voyage avec
  /// la fenêtre plutôt que d'être redevinée à partir de sa durée, qui vaut
  /// trois mois pour un site jeune comme dix ans pour un site ancien.
  final bool allTime;

  int get startMs => start.millisecondsSinceEpoch;
  int get endMs => end.millisecondsSinceEpoch;

  /// Nombre de buckets que la fenêtre représente (estimation : un mois vaut
  /// 30 jours). Sert à écarter les granularités qui donneraient une série
  /// illisible ou trop lourde.
  int get bucketCount {
    final n = end.difference(start).inMinutes / unit.nominal.inMinutes;
    return n.ceil().clamp(1, 1 << 20);
  }

  @override
  bool operator ==(Object other) =>
      other is DateWindow &&
      other.startMs == startMs &&
      other.endMs == endMs &&
      other.unit == unit &&
      other.allTime == allTime;

  @override
  int get hashCode => Object.hash(startMs, endMs, unit, allTime);
}

/// Granularité la plus fine qu'Umami accepte pour une durée donnée — règle
/// relevée dans son code (`getMinimumUnit`) : l'heure jusqu'à 30 jours, le jour
/// jusqu'à 7 mois, le mois au-delà.
TimeUnit minUnitFor(Duration span) {
  if (span.inDays <= 30) return TimeUnit.hour;
  if (span.inDays <= 214) return TimeUnit.day; // ~7 mois
  return TimeUnit.month;
}

/// Granularité « naturelle » d'une durée quelconque (période personnalisée) :
/// plus large que [minUnitFor], qui donne le plus fin que l'API tolère.
TimeUnit _naturalUnitForSpan(Duration span) {
  if (span.inDays <= 2) return TimeUnit.hour;
  if (span.inDays <= 120) return TimeUnit.day;
  return TimeUnit.month;
}

/// Granularités proposables pour [w] : celles au moins aussi larges que le
/// minimum accepté par l'API, et qui donnent une série lisible.
///
/// [maxBuckets] n'est pas cosmétique : au-delà, la série pèse plus que ce que
/// le graphique peut montrer (un mois en heures fait déjà 744 points pour
/// ~350 points de large) et le fournisseur finit par tronquer. [minBuckets]
/// écarte l'inverse — proposer « Mois » sur sept jours donnerait une seule
/// barre.
List<TimeUnit> allowedUnits(
  DateWindow w, {
  int maxBuckets = 800,
  int minBuckets = 3,
}) {
  final min = minUnitFor(w.end.difference(w.start));
  final out = <TimeUnit>[];
  for (final u in TimeUnit.values) {
    if (u.index < min.index) continue;
    final n = DateWindow(w.start, w.end, u).bucketCount;
    if (n > maxBuckets || n < minBuckets) continue;
    out.add(u);
  }
  // L'unité affichée figure toujours dans la liste : un sélecteur qui n'offre
  // pas ce qui est à l'écran serait incompréhensible.
  if (!out.contains(w.unit)) {
    out.add(w.unit);
    out.sort((a, b) => a.index.compareTo(b.index));
  }
  return out;
}

/// Périodes de la maquette. Les bornes sont calculées à la volée (dépendent de
/// « maintenant »).
enum Period {
  today('today', "Aujourd'hui"),
  h24('24h', '24 h'),
  d7('7j', '7 jours'),
  d30('30j', '30 j'),
  thisMonth('mois', 'Ce mois-ci'),
  m12('12m', '12 m'),
  thisYear('annee', 'Cette année'),
  allTime('tout', 'Tout'),
  custom('perso', 'Perso');

  const Period(this.key, this.label);
  final String key;
  final String label;

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Plafond de [d] au début de l'unité suivante. La fenêtre est ainsi alignée
  /// sur la grille (heure/jour/mois) : sa clé reste stable pendant toute l'unité
  /// courante, donc l'auto-refresh réutilise le même provider (pas de flash ni
  /// d'accumulation d'instances). Le bucket courant grandit au fil des données.
  static DateTime _ceil(DateTime d, TimeUnit u) => switch (u) {
    TimeUnit.hour => DateTime(d.year, d.month, d.day, d.hour + 1),
    TimeUnit.day => DateTime(d.year, d.month, d.day + 1),
    TimeUnit.month => DateTime(d.year, d.month + 1, 1),
  };

  /// Début de l'unité qui contient [d].
  static DateTime _floor(DateTime d, TimeUnit u) => switch (u) {
    TimeUnit.hour => DateTime(d.year, d.month, d.day, d.hour),
    TimeUnit.day => DateTime(d.year, d.month, d.day),
    TimeUnit.month => DateTime(d.year, d.month, 1),
  };

  /// Granularité de « Tout » selon l'ancienneté réelle du site. Jamais l'heure :
  /// même un mois y ferait 720 points.
  static TimeUnit _allTimeUnit(DateTime start, DateTime now) {
    final months = (now.year - start.year) * 12 + now.month - start.month;
    return months <= 6 ? TimeUnit.day : TimeUnit.month;
  }

  /// Résout la fenêtre. Pour [custom], passer [customStart]/[customEnd].
  /// [dayOffset] décale d'un nombre de jours pour [today] (0 = aujourd'hui).
  /// [monthOffset]/[yearOffset] font de même pour [thisMonth]/[thisYear] :
  /// naviguer mois par mois ou année par année (0 = période courante).
  ///
  /// [unit] force la granularité (sélecteur au-dessus du graphique) : elle est
  /// appliquée **avant** le calcul des bornes, sinon la fin resterait alignée
  /// sur l'unité naturelle — une journée demandée en granularité jour donnerait
  /// une fenêtre plus courte qu'un bucket, donc une série vide.
  ///
  /// [allTimeStart] est la date de première donnée réelle (cf.
  /// `AnalyticsProvider.dataRange`) ; sans elle, [allTime] cadre large et la
  /// série est rognée à l'affichage.
  DateWindow window({
    DateTime? now,
    DateTime? customStart,
    DateTime? customEnd,
    int dayOffset = 0,
    int monthOffset = 0,
    int yearOffset = 0,
    TimeUnit? unit,
    DateTime? allTimeStart,
  }) {
    final n = now ?? DateTime.now();
    switch (this) {
      case Period.today:
        final u = unit ?? TimeUnit.hour;
        if (dayOffset < 0) {
          // Jour passé complet : [00:00, 00:00 lendemain).
          final day = DateTime(n.year, n.month, n.day + dayOffset);
          return DateWindow(day, DateTime(day.year, day.month, day.day + 1), u);
        }
        return DateWindow(_startOfDay(n), _ceil(n, u), u);
      case Period.h24:
        final u = unit ?? TimeUnit.hour;
        final end = _ceil(n, u);
        return DateWindow(end.subtract(const Duration(hours: 24)), end, u);
      case Period.d7:
        final u = unit ?? TimeUnit.day;
        final end = _ceil(n, u);
        return DateWindow(end.subtract(const Duration(days: 7)), end, u);
      case Period.d30:
        final u = unit ?? TimeUnit.day;
        final end = _ceil(n, u);
        return DateWindow(end.subtract(const Duration(days: 30)), end, u);
      case Period.thisMonth:
        final u = unit ?? TimeUnit.day;
        final start = DateTime(n.year, n.month + monthOffset, 1);
        // Mois courant (offset 0) : fin qui grandit avec « aujourd'hui ».
        // Mois passé : fin figée au 1er du mois suivant.
        final end = monthOffset == 0
            ? _ceil(n, u)
            : DateTime(n.year, n.month + monthOffset + 1, 1);
        return DateWindow(start, end, u);
      case Period.m12:
        final u = unit ?? TimeUnit.month;
        return DateWindow(DateTime(n.year, n.month - 11, 1), _ceil(n, u), u);
      case Period.thisYear:
        final u = unit ?? TimeUnit.month;
        final start = DateTime(n.year + yearOffset, 1, 1);
        final end = yearOffset == 0
            ? _ceil(n, u)
            : DateTime(n.year + yearOffset + 1, 1, 1);
        return DateWindow(start, end, u);
      case Period.allTime:
        // Seul le DÉBUT vient de l'API : sa fin, elle, bougerait à chaque visite
        // enregistrée, donc la clé des providers changerait sans cesse et le
        // rafraîchissement boucherait. La fin reste alignée sur la grille comme
        // pour toutes les autres périodes.
        final start = allTimeStart ?? DateTime(n.year - 10, 1, 1);
        final u = unit ?? _allTimeUnit(start, n);
        return DateWindow(_floor(start, u), _ceil(n, u), u, allTime: true);
      case Period.custom:
        final s = customStart ?? _startOfDay(n).subtract(const Duration(days: 29));
        final e = customEnd ?? n;
        final u = unit ?? _naturalUnitForSpan(e.difference(s));
        // Fin plafonnée comme partout ailleurs : sans ça, une sélection qui
        // s'arrête à 23 h 59 exclut son dernier jour de la courbe, alors qu'il
        // compte dans les totaux.
        return DateWindow(s, _ceil(e, u), u);
    }
  }

  static Period fromKey(String k) =>
      Period.values.firstWhere((p) => p.key == k, orElse: () => Period.d7);
}
