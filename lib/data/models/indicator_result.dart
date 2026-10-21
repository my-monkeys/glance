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
  const RatioPoint(this.t, this.value);
  final DateTime t;

  /// Null quand le dénominateur est nul et que l'indicateur veut un trou.
  final double? value;
}

/// Résultat d'un indicateur, selon son genre.
@immutable
sealed class IndicatorData {
  const IndicatorData();
}

/// Jours de cohortes réellement affichés quand la fenêtre d'une métrique de
/// site a été décalée (bornes incluses).
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
  const CounterData(this.points, this.total, {this.cohorts});
  final List<SeriesPoint> points;
  final int total;

  /// Non null quand la fenêtre a été décalée (métrique de site).
  final CohortSpan? cohorts;
}

class RatioData extends IndicatorData {
  const RatioData({
    required this.points,
    required this.overall,
    required this.numeratorTotal,
    required this.denominatorTotal,
    this.cohorts,
    this.pending = false,
  });

  final List<RatioPoint> points;
  final double? overall;
  final int numeratorTotal;
  final int denominatorTotal;

  /// Non null quand la fenêtre a été décalée (métrique de site).
  final CohortSpan? cohorts;

  /// Aucun point mesurable, alors que des gens y comptent : les cohortes ne
  /// sont pas terminées. À distinguer de « rien ne s'est passé ».
  final bool pending;
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
