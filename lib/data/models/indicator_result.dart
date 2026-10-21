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

class CounterData extends IndicatorData {
  const CounterData(this.points, this.total, {this.cohorts, this.member});
  final List<SeriesPoint> points;
  final int total;

  /// Non null pour une métrique à délai ayant au moins une mesure.
  final CohortSpan? cohorts;

  /// Membre retenu d'une famille (« J7 »), null pour une métrique seule.
  final String? member;
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
}

class FunnelData extends IndicatorData {
  const FunnelData(this.steps);
  final List<FunnelStepResult> steps;
}

class BreakdownData extends IndicatorData {
  const BreakdownData(this.rows, this.total);
  final List<MetricRow> rows;
  final int total;
}
