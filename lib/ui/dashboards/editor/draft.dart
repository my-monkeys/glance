import 'package:flutter/foundation.dart';

import '../../../data/models/indicator.dart';
import '../../../data/models/metrics_source.dart';
import '../labels.dart';

/// Opérateurs que l'API d'entonnoir d'Umami accepte : elle ne sait pas
/// comparer des nombres. Un filtre `≥` y serait ignoré sans erreur, donc
/// l'entonnoir compterait trop de monde.
const Set<FilterOp> kFunnelOps = {
  FilterOp.eq,
  FilterOp.neq,
  FilterOp.contains,
  FilterOp.notContains,
};

const int kFunnelMinSteps = 2;
const int kFunnelMaxSteps = 8;
const int kFunnelMinWindow = 1;
const int kFunnelMaxWindow = 1440;
const int kFunnelDefaultWindow = 60;

const String _fallbackName = 'Sans titre';

/// Un indicateur en cours d'édition. Tous les champs de tous les genres
/// coexistent : changer de genre ne perd rien, et revenir en arrière retrouve
/// ce qui avait été saisi. Seuls ceux du genre courant servent à
/// [toIndicator] et à [validationError].
@immutable
class IndicatorDraft {
  const IndicatorDraft({
    this.kind = IndicatorKind.counter,
    this.name = '',
    this.query = const EventQuery(''),
    this.denominator = const EventQuery(''),
    this.steps = const [EventQuery(''), EventQuery('')],
    // Texte et non int : un champ à moitié saisi doit pouvoir être invalide
    // sans que le brouillon perde ce que l'utilisateur a tapé.
    this.windowText = '$kFunnelDefaultWindow',
    this.breakdownEvent = '',
    this.breakdownProperty = '',
    this.gapsWhenEmpty = false,
    this.breakdownOverTime = false,
    this.metricId = '',
    this.metricLabel = '',
    this.metricUnit = MetricUnit.count,
    this.metricFamily = '',
  });

  final IndicatorKind kind;
  final String name;

  /// Requête du compteur, ou numérateur du taux.
  final EventQuery query;
  final EventQuery denominator;
  final List<EventQuery> steps;
  final String windowText;
  final String breakdownEvent;
  final String breakdownProperty;
  final bool gapsWhenEmpty;
  final bool breakdownOverTime;

  /// Métrique de la source du site ; libellé et unité viennent du catalogue.
  final String metricId;
  final String metricLabel;
  final MetricUnit metricUnit;

  /// Vide = une métrique seule ; sinon la famille, dont [metricId] est le
  /// membre de repli.
  final String metricFamily;

  factory IndicatorDraft.fromIndicator(Indicator i) {
    return switch (i) {
      CounterIndicator() =>
        IndicatorDraft(kind: i.kind, name: i.name, query: i.query),
      RatioIndicator() => IndicatorDraft(
          kind: i.kind,
          name: i.name,
          query: i.numerator,
          denominator: i.denominator,
          gapsWhenEmpty: i.gapsWhenEmpty,
        ),
      FunnelIndicator() => IndicatorDraft(
          kind: i.kind,
          name: i.name,
          steps: i.steps,
          windowText: '${i.windowMinutes}',
        ),
      BreakdownIndicator() => IndicatorDraft(
          kind: i.kind,
          name: i.name,
          breakdownEvent: i.event,
          breakdownProperty: i.property,
          breakdownOverTime: i.overTime,
        ),
      ExternalIndicator() => IndicatorDraft(
          kind: i.kind,
          name: i.name,
          metricId: i.metricId,
          metricLabel: i.label,
          metricUnit: i.unit,
          metricFamily: i.familyId ?? '',
        ),
    };
  }

  IndicatorDraft copyWith({
    IndicatorKind? kind,
    String? name,
    EventQuery? query,
    EventQuery? denominator,
    List<EventQuery>? steps,
    String? windowText,
    String? breakdownEvent,
    String? breakdownProperty,
    bool? gapsWhenEmpty,
    bool? breakdownOverTime,
    String? metricId,
    String? metricLabel,
    MetricUnit? metricUnit,
    String? metricFamily,
  }) =>
      IndicatorDraft(
        kind: kind ?? this.kind,
        name: name ?? this.name,
        query: query ?? this.query,
        denominator: denominator ?? this.denominator,
        steps: steps ?? this.steps,
        windowText: windowText ?? this.windowText,
        breakdownEvent: breakdownEvent ?? this.breakdownEvent,
        breakdownProperty: breakdownProperty ?? this.breakdownProperty,
        gapsWhenEmpty: gapsWhenEmpty ?? this.gapsWhenEmpty,
        breakdownOverTime: breakdownOverTime ?? this.breakdownOverTime,
        metricId: metricId ?? this.metricId,
        metricLabel: metricLabel ?? this.metricLabel,
        metricUnit: metricUnit ?? this.metricUnit,
        metricFamily: metricFamily ?? this.metricFamily,
      );

  /// Change de genre en reportant ce qui a un sens de l'un à l'autre : la
  /// requête du compteur devient le numérateur du taux, la première étape de
  /// l'entonnoir, l'événement de la répartition — et inversement. On ne
  /// reporte que vers un champ encore vide, jamais par-dessus une saisie.
  IndicatorDraft withKind(IndicatorKind next) {
    if (next == kind) return this;
    // L'événement le plus significatif du genre quitté.
    final carried = switch (kind) {
      IndicatorKind.counter || IndicatorKind.ratio => query,
      IndicatorKind.funnel => steps.first,
      IndicatorKind.breakdown => EventQuery(breakdownEvent),
      IndicatorKind.external => const EventQuery(''),
    };
    if (carried.event.isEmpty) return copyWith(kind: next);
    return switch (next) {
      IndicatorKind.external => copyWith(kind: next),
      IndicatorKind.counter || IndicatorKind.ratio => copyWith(
          kind: next,
          query: query.event.isEmpty ? carried : query,
        ),
      IndicatorKind.funnel => copyWith(
          kind: next,
          steps: steps.first.event.isEmpty
              ? [carried, ...steps.skip(1)]
              : steps,
        ),
      IndicatorKind.breakdown => copyWith(
          kind: next,
          breakdownEvent:
              breakdownEvent.isEmpty ? carried.event : breakdownEvent,
        ),
    };
  }

  /// Nom proposé tant que le champ « Nom » reste vide.
  String suggestedName() {
    final parts = switch (kind) {
      IndicatorKind.counter => [_label(query)],
      IndicatorKind.ratio => [_label(query), _label(denominator)],
      IndicatorKind.funnel => [steps.first.event, steps.last.event],
      IndicatorKind.breakdown => [breakdownEvent, breakdownProperty],
      IndicatorKind.external => [metricLabel],
    }.where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return _fallbackName;
    if (parts.length == 1) return parts.single;
    return switch (kind) {
      IndicatorKind.ratio => '${parts[0]} / ${parts[1]}',
      IndicatorKind.funnel => '${parts[0]} → ${parts[1]}',
      _ => '${parts[0]} par ${parts[1]}',
    };
  }

  static String _label(EventQuery q) => q.event.isEmpty ? '' : queryLabel(q);

  /// Raison courte pour laquelle le brouillon ne peut pas être enregistré, ou
  /// null s'il est valide.
  String? validationError() {
    switch (kind) {
      case IndicatorKind.counter:
        return query.event.isEmpty
            ? 'Choisissez un événement'
            : _filtersError(query);
      case IndicatorKind.ratio:
        if (query.event.isEmpty) return 'Choisissez l\'événement à compter';
        if (denominator.event.isEmpty) {
          return 'Choisissez l\'événement de référence';
        }
        return _filtersError(query) ?? _filtersError(denominator);
      case IndicatorKind.funnel:
        return _funnelError();
      case IndicatorKind.breakdown:
        if (breakdownEvent.isEmpty) return 'Choisissez un événement';
        if (breakdownProperty.isEmpty) return 'Choisissez une propriété';
        return null;
      case IndicatorKind.external:
        return metricId.isEmpty ? 'Choisissez une métrique' : null;
    }
  }

  String? _funnelError() {
    if (steps.length < kFunnelMinSteps) {
      return 'Un entonnoir compte au moins $kFunnelMinSteps étapes';
    }
    if (steps.length > kFunnelMaxSteps) {
      return 'Un entonnoir compte au plus $kFunnelMaxSteps étapes';
    }
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].event.isEmpty) return 'Choisissez l\'événement de l\'étape ${i + 1}';
    }
    for (final s in steps) {
      final e = _filtersError(s);
      if (e != null) return e;
      if (s.filters.any((f) => !kFunnelOps.contains(f.op))) {
        return 'Un entonnoir ne compare pas les nombres : retirez ce filtre';
      }
    }
    return windowMinutes == null ? 'Délai invalide' : null;
  }

  /// Délai en minutes, null s'il n'est pas un entier de 1 à 1440.
  int? get windowMinutes {
    final m = int.tryParse(windowText.trim());
    return m != null && m >= kFunnelMinWindow && m <= kFunnelMaxWindow ? m : null;
  }

  static String? _filtersError(EventQuery q) {
    for (final f in q.filters) {
      if (f.value.trim().isEmpty) return 'Valeur du filtre manquante';
      if (f.type == PropertyType.number && num.tryParse(f.value.trim()) == null) {
        return 'Valeur de filtre non numérique';
      }
    }
    return null;
  }

  /// Null tant que [validationError] en trouve une. Un nom laissé vide prend
  /// [suggestedName].
  Indicator? toIndicator(String id) {
    if (validationError() != null) return null;
    final label = name.trim().isEmpty ? suggestedName() : name.trim();
    return switch (kind) {
      IndicatorKind.counter =>
        CounterIndicator(id: id, name: label, query: query),
      IndicatorKind.ratio => RatioIndicator(
          id: id,
          name: label,
          numerator: query,
          denominator: denominator,
          gapsWhenEmpty: gapsWhenEmpty,
        ),
      IndicatorKind.funnel => FunnelIndicator(
          id: id,
          name: label,
          steps: steps,
          windowMinutes: windowMinutes!,
        ),
      IndicatorKind.breakdown => BreakdownIndicator(
          id: id,
          name: label,
          event: breakdownEvent,
          property: breakdownProperty,
          overTime: breakdownOverTime,
        ),
      IndicatorKind.external => ExternalIndicator(
          id: id,
          name: label,
          metricId: metricId,
          label: metricLabel,
          unit: metricUnit,
          familyId: metricFamily.isEmpty ? null : metricFamily,
        ),
    };
  }
}
