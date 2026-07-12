import 'package:flutter/foundation.dart';

/// Un site suivi (un « website » côté Umami/Plausible).
@immutable
class Site {
  const Site({
    required this.id,
    required this.accountId,
    required this.name,
    required this.domain,
  });

  final String id;
  final String accountId;
  final String name;
  final String domain;

  /// Initiale pour la pastille (comme la maquette).
  String get initial {
    final base = name.trim().isNotEmpty ? name.trim() : domain.trim();
    return base.isEmpty ? '•' : base[0].toUpperCase();
  }

  Site copyWith({String? name}) =>
      Site(id: id, accountId: accountId, name: name ?? this.name, domain: domain);

  @override
  bool operator ==(Object other) =>
      other is Site && other.id == id && other.accountId == accountId;

  @override
  int get hashCode => Object.hash(id, accountId);
}

/// Résumé agrégé sur une fenêtre. Valeurs dérivées (rebond, durée) déjà
/// calculées par le provider pour rester agnostique du format d'origine.
@immutable
class StatsSummary {
  const StatsSummary({
    required this.visitors,
    required this.pageviews,
    required this.visits,
    required this.bounceRatePct,
    required this.avgVisitSec,
    this.prevVisitors,
    this.prevPageviews,
  });

  final int visitors;
  final int pageviews;
  final int visits;
  final double bounceRatePct; // 0..100
  final int avgVisitSec;
  final int? prevVisitors;
  final int? prevPageviews;

  static const empty = StatsSummary(
    visitors: 0,
    pageviews: 0,
    visits: 0,
    bounceRatePct: 0,
    avgVisitSec: 0,
  );

  /// Delta visiteurs vs période précédente, en %. null si non calculable.
  double? get visitorsDeltaPct => _delta(visitors, prevVisitors);

  static double? _delta(int cur, int? prev) {
    if (prev == null || prev == 0) return null;
    return (cur - prev) / prev * 100;
  }

  Duration get avgVisit => Duration(seconds: avgVisitSec);
}

/// Un point de la série temporelle.
@immutable
class SeriesPoint {
  const SeriesPoint(this.t, this.visitors, this.pageviews, {this.visits});
  final DateTime t;

  /// Visiteurs *uniques* par bucket. Toujours présent — c'est la courbe verte
  /// de référence (série `sessions` d'Umami = uniques ; `visitors` de Plausible).
  final double visitors;
  final double pageviews;

  /// Visites (`visit_id`) par bucket : navigations distinctes (≥ visiteurs, car
  /// une même personne peut ouvrir plusieurs sessions). `null` quand non calculé :
  /// Umami ne fournit **pas** les visites en série (la série `sessions` compte les
  /// visiteurs, pas les visites) → un appel `/stats` par point, réservé au détail
  /// d'un site. Plausible les renvoie directement dans [series].
  final double? visits;
}

/// Une ligne de métrique (page, source, pays…), avec barre relative.
@immutable
class MetricRow {
  const MetricRow({required this.label, required this.value, this.code});
  final String label;
  final int value;
  final String? code; // ex: code pays "FR"
}

/// Une page vue en direct.
@immutable
class LivePage {
  const LivePage(this.path, this.count);
  final String path;
  final int count;
}

/// Bundle complet pour l'écran de détail (évite N appels séparés côté UI).
@immutable
class SiteDetail {
  const SiteDetail({
    required this.summary,
    required this.series,
    required this.unit,
    required this.topPages,
    required this.sources,
    required this.countries,
    required this.live,
    required this.livePages,
  });

  final StatsSummary summary;
  final List<SeriesPoint> series;
  final String unit; // 'hour' | 'day' | 'month'
  final List<MetricRow> topPages;
  final List<MetricRow> sources;
  final List<MetricRow> countries;
  final int live;
  final List<LivePage> livePages;
}

/// Série temporelle d'un seul nom d'événement (nombre par bucket porté par
/// [SeriesPoint.visitors] — champ réutilisé comme « compte »).
@immutable
class EventSeries {
  const EventSeries({
    required this.name,
    required this.points,
    required this.total,
  });
  final String name;
  final List<SeriesPoint> points;
  final int total;
}

/// Données d'événements personnalisés pour un site sur une fenêtre : une série
/// par nom d'événement (triées par total décroissant).
@immutable
class EventsData {
  const EventsData({
    required this.total,
    required this.series,
    required this.unit,
  });

  final int total;
  final List<EventSeries> series; // triées par total desc
  final String unit;

  bool get isEmpty => series.isEmpty;

  /// Répartition par nom d'événement (dérivée des totaux).
  List<MetricRow> get breakdown =>
      series.map((e) => MetricRow(label: e.name, value: e.total)).toList();
}
