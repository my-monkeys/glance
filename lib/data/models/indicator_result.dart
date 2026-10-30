import 'package:flutter/foundation.dart';

import 'indicator.dart';
import 'models.dart';

/// Propriété d'un événement, telle que la liste le fournisseur.
@immutable
class EventProperty {
  const EventProperty(this.name, this.type);
  final String name;
  final PropertyType type;
}

/// Une étape d'entonnoir mesurée.
@immutable
class FunnelStepResult {
  const FunnelStepResult({
    required this.event,
    required this.filters,
    required this.visitors,
    required this.remaining,
    this.dropoff,
  });

  final String event;
  final List<EventFilter> filters;
  final int visitors;

  /// Part des visiteurs de la 1re étape encore présents ici, 0..1.
  final double remaining;

  /// Part perdue depuis l'étape précédente, 0..1 ; null pour la 1re étape.
  final double? dropoff;
}

@immutable
class RatioPoint {
  const RatioPoint(this.t, this.value, {this.cohort});
  final DateTime t;

  /// Jour de la cohorte mesurée à [t], pour une métrique à délai.
  final DateTime? cohort;

  /// Null quand le dénominateur est nul et que l'indicateur veut un trou.
  final double? value;
}

/// Résultat d'un indicateur, selon son genre.
@immutable
sealed class IndicatorData {
  const IndicatorData();
}

/// Première et dernière cohortes mesurées d'une métrique à délai (bornes
/// incluses).
@immutable
class CohortSpan {
  const CohortSpan(this.first, this.last);
  final DateTime first;
  final DateTime last;

  @override
  bool operator ==(Object other) =>
      other is CohortSpan && other.first == first && other.last == last;

  @override
  int get hashCode => Object.hash(first, last);
}

/// Fin des données publiées d'une métrique de site en retard.
@immutable
class Unpublished {
  const Unpublished({required this.until, required this.from});

  /// Dernier jour publié, tel que le dit la source.
  final DateTime until;

  /// Premier bucket de la fenêtre qui n'est pas encore publié : lui et les
  /// suivants sont des trous.
  final DateTime from;

  bool covers(DateTime t) => !t.isBefore(from);
}

/// Une part d'un compteur découpé (une plateforme), alignée sur ses points.
class CounterSegment {
  const CounterSegment({
    required this.label,
    required this.values,
    this.estimated = false,
    this.periodTotal,
  });

  final String label;
  final bool estimated;

  /// Un par point du compteur. Null = bucket que la source ne savait pas
  /// encore découper : un trou, jamais un zéro.
  final List<double?> values;

  /// Distinct sur toute la période (`totaux`), null si la source ne le donne
  /// pas. Les parts se calculent sur ces totaux, pas sur la somme des points.
  final int? periodTotal;
}

class CounterData extends IndicatorData {
  const CounterData(this.points, this.total,
      {this.cohorts, this.member, this.unpublished, this.segments = const []});
  final List<SeriesPoint> points;
  final int total;

  /// Non null pour une métrique à délai ayant au moins une mesure.
  final CohortSpan? cohorts;

  /// Membre retenu d'une famille (« J7 »), null pour une métrique seule.
  final String? member;

  /// Non null quand la fenêtre dépasse les données publiées : les points
  /// couverts valent 0 dans [points] mais se dessinent en trou.
  final Unpublished? unpublished;

  /// Découpage par part (métrique de site à `segments`), vide sinon.
  final List<CounterSegment> segments;
}

class RatioData extends IndicatorData {
  const RatioData({
    required this.points,
    required this.overall,
    required this.numeratorTotal,
    required this.denominatorTotal,
    this.cohorts,
    this.member,
    this.pending = false,
    this.delayDays = 0,
    this.unpublished,
  });

  final List<RatioPoint> points;
  final double? overall;
  final int numeratorTotal;
  final int denominatorTotal;

  /// Non null pour une métrique à délai ayant au moins une mesure.
  final CohortSpan? cohorts;

  /// Membre retenu d'une famille (« J7 »), null pour une métrique seule.
  final String? member;

  /// Aucun point mesurable, alors que des gens y comptent : les cohortes ne
  /// sont pas terminées. À distinguer de « rien ne s'est passé ».
  final bool pending;

  /// Recul nécessaire avant la mesure (J7 → 7), pour dire à l'attente combien
  /// de temps elle dure. 0 hors métrique à délai.
  final int delayDays;

  /// Non null quand la fenêtre dépasse les données publiées (trous à la fin).
  final Unpublished? unpublished;
}

class FunnelData extends IndicatorData {
  const FunnelData(this.steps);
  final List<FunnelStepResult> steps;
}

/// Lignes d'une répartition : au-delà, la carte deviendrait une liste.
const int kBreakdownRows = 8;

class BreakdownData extends IndicatorData {
  const BreakdownData(this.rows, this.total, [this.series]);
  final List<MetricRow> rows;
  final int total;

  /// Une série par valeur (les [kBreakdownRows] premières), dans l'ordre de
  /// [rows]. Null sans l'option « évolution dans le temps ».
  final List<EventSeries>? series;
}
