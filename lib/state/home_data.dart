import '../data/models/models.dart';

/// Stats d'un site sur une fenêtre (chargées indépendamment du live).
class SiteStats {
  const SiteStats({required this.summary, required this.series});
  final StatsSummary summary;
  final List<SeriesPoint> series;
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
  });

  final Site site;
  final StatsSummary summary;
  final List<SeriesPoint> series;
  final int live;

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
  });

  final List<SiteCard> cards;
  final int totalVisitors;
  final int? prevTotalVisitors;
  final int totalVisits;
  final int totalPageviews;
  final int totalLive;
  final List<SeriesPoint> totalSeries;

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

    // Série cumulée par bucket (fenêtres alignées) : visiteurs + pages vues
    // toujours ; visites seulement si *tous* les sites chargés les portent
    // (Umami ne fournit pas les visites en série → agrégat honnête).
    final buckets = cards.isEmpty ? <SeriesPoint>[] : cards.first.series;
    final total = <SeriesPoint>[];
    for (var i = 0; i < buckets.length; i++) {
      var vu = 0.0;
      var pv = 0.0;
      var vs = 0.0;
      var allVisits = cards.isNotEmpty;
      for (final c in cards) {
        if (i < c.series.length) {
          vu += c.series[i].visitors;
          pv += c.series[i].pageviews;
          final sv = c.series[i].visits;
          if (sv == null) {
            allVisits = false;
          } else {
            vs += sv;
          }
        }
      }
      total.add(SeriesPoint(buckets[i].t, vu, pv, visits: allVisits ? vs : null));
    }

    return HomeData(
      cards: cards,
      totalVisitors: totalVisitors,
      prevTotalVisitors: hasPrev ? prevTotal : null,
      totalVisits: totalVisits,
      totalPageviews: totalPageviews,
      totalLive: totalLive,
      totalSeries: total,
    );
  }
}
