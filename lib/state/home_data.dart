import '../data/models/models.dart';

/// Stats d'un site sur une fenêtre (chargées indépendamment du live).
class SiteStats {
  const SiteStats({
    required this.summary,
    required this.series,
    this.refSeries,
    this.daily,
  });
  final StatsSummary summary;
  final List<SeriesPoint> series;

  /// Série de la période précédente équivalente (profil pour la prévision).
  /// Null quand la fenêtre n'en a pas besoin (cf. `forecastReferenceWindow`).
  final List<SeriesPoint>? refSeries;

  /// Visiteurs par jour des dernières semaines, pour la prévision jour par
  /// jour. Null quand la fenêtre n'en a pas besoin (cf. `forecastHistoryWindow`).
  final List<SeriesPoint>? daily;
}

/// Agrégat de la home pendant le chargement incrémental : totaux calculés sur
/// les sites déjà chargés + nombre de sites encore en attente.
class HomeTotals {
  const HomeTotals({
    required this.data,
    required this.pending,
    required this.siteCount,
    required this.loading,
  });

  final HomeData data;
  final int pending; // sites dont les stats ne sont pas encore arrivées
  final int siteCount;
  final bool loading;

  bool get hasAny => data.cards.isNotEmpty;
}

/// Données d'une carte de site sur la home.
class SiteCard {
  SiteCard({
    required this.site,
    required this.summary,
    required this.series,
    required this.live,
    this.refSeries,
    this.daily,
    this.compareSeries,
  });

  final Site site;
  final StatsSummary summary;
  final List<SeriesPoint> series;
  final int live;
  final List<SeriesPoint>? refSeries;
  final List<SeriesPoint>? daily;

  /// Série de la période précédente équivalente, superposée sur le graphique
  /// quand la comparaison est activée (cf. `PeriodState.compare`). Null tant
  /// qu'elle n'a pas été demandée ou que la période n'a pas d'équivalent.
  final List<SeriesPoint>? compareSeries;

  double? get deltaPct => summary.visitorsDeltaPct;
  bool get up => (deltaPct ?? 0) >= 0;
}

/// Agrégat pour la home : total tous sites + série cumulée + cartes.
class HomeData {
  HomeData({
    required this.cards,
    required this.totalVisitors,
    required this.prevTotalVisitors,
    required this.totalVisits,
    required this.totalPageviews,
    required this.totalLive,
    required this.totalSeries,
    this.totalRefSeries,
    this.totalDaily,
    this.totalCompareSeries,
  });

  final List<SiteCard> cards;
  final int totalVisitors;
  final int? prevTotalVisitors;
  final int totalVisits;
  final int totalPageviews;
  final int totalLive;
  final List<SeriesPoint> totalSeries;

  /// Agrégat sans aucun site chargé — ce que montre un écran en attente.
  static final empty = HomeData(
    cards: const [],
    totalVisitors: 0,
    prevTotalVisitors: null,
    totalVisits: 0,
    totalPageviews: 0,
    totalLive: 0,
    totalSeries: const [],
  );

  /// Série de référence cumulée (profil pour la prévision de la courbe totale).
  final List<SeriesPoint>? totalRefSeries;

  /// Visiteurs par jour cumulés (prévision de la courbe totale).
  final List<SeriesPoint>? totalDaily;

  /// Série de comparaison cumulée (période précédente, toutes cartes).
  final List<SeriesPoint>? totalCompareSeries;

  double? get totalDeltaPct {
    final p = prevTotalVisitors;
    if (p == null || p == 0) return null;
    return (totalVisitors - p) / p * 100;
  }

  bool get up => (totalDeltaPct ?? 0) >= 0;

  bool get isEmpty => cards.isEmpty;

  /// Construit l'agrégat à partir des cartes déjà chargées.
  static HomeData fromCards(List<SiteCard> cards) {
    var totalVisitors = 0;
    var prevTotal = 0;
    var hasPrev = false;
    var totalVisits = 0;
    var totalPageviews = 0;
    var totalLive = 0;
    for (final c in cards) {
      totalVisitors += c.summary.visitors;
      totalVisits += c.summary.visits;
      totalPageviews += c.summary.pageviews;
      if (c.summary.prevVisitors != null) {
        prevTotal += c.summary.prevVisitors!;
        hasPrev = true;
      }
      totalLive += c.live;
    }

    // Série cumulée par bucket (fenêtres alignées) : visiteurs + pages vues.
    final buckets = cards.isEmpty ? <SeriesPoint>[] : cards.first.series;
    final total = <SeriesPoint>[];
    for (var i = 0; i < buckets.length; i++) {
      var vu = 0.0;
      var pv = 0.0;
      for (final c in cards) {
        if (i < c.series.length) {
          vu += c.series[i].visitors;
          pv += c.series[i].pageviews;
        }
      }
      total.add(SeriesPoint(buckets[i].t, vu, pv));
    }

    // Référence cumulée (mêmes fenêtres de référence pour toutes les cartes).
    final refBuckets = cards.isEmpty
        ? null
        : cards
            .firstWhere((c) => c.refSeries != null, orElse: () => cards.first)
            .refSeries;
    List<SeriesPoint>? totalRef;
    if (refBuckets != null) {
      totalRef = <SeriesPoint>[];
      for (var i = 0; i < refBuckets.length; i++) {
        var vu = 0.0;
        for (final c in cards) {
          final r = c.refSeries;
          if (r != null && i < r.length) vu += r[i].visitors;
        }
        totalRef.add(SeriesPoint(refBuckets[i].t, vu, 0));
      }
    }

    // Comparaison cumulée (même principe que la référence de prévision
    // ci-dessus, mais indépendante : demandée explicitement par l'utilisateur,
    // pas seulement pour les 3 périodes calendaires).
    final compareBuckets = cards.isEmpty
        ? null
        : cards
            .firstWhere((c) => c.compareSeries != null, orElse: () => cards.first)
            .compareSeries;
    List<SeriesPoint>? totalCompare;
    if (compareBuckets != null) {
      totalCompare = <SeriesPoint>[];
      for (var i = 0; i < compareBuckets.length; i++) {
        var vu = 0.0;
        for (final c in cards) {
          final cs = c.compareSeries;
          if (cs != null && i < cs.length) vu += cs[i].visitors;
        }
        totalCompare.add(SeriesPoint(compareBuckets[i].t, vu, 0));
      }
    }

    return HomeData(
      cards: cards,
      totalVisitors: totalVisitors,
      prevTotalVisitors: hasPrev ? prevTotal : null,
      totalVisits: totalVisits,
      totalPageviews: totalPageviews,
      totalLive: totalLive,
      totalSeries: total,
      totalRefSeries: totalRef,
      totalDaily: _sumByDate([for (final c in cards) c.daily]),
      totalCompareSeries: totalCompare,
    );
  }
}

/// Somme par date — et non par index : chaque site a récupéré son historique
/// à son heure, un chargement à cheval sur minuit décalerait les index d'un jour.
/// Null si aucun site n'en a.
List<SeriesPoint>? _sumByDate(List<List<SeriesPoint>?> all) {
  final byDate = <DateTime, double>{};
  var any = false;
  for (final s in all) {
    if (s == null) continue;
    any = true;
    for (final p in s) {
      byDate[p.t] = (byDate[p.t] ?? 0) + p.visitors;
    }
  }
  if (!any) return null;
  final dates = byDate.keys.toList()..sort();
  return [for (final d in dates) SeriesPoint(d, byDate[d]!, 0)];
}
