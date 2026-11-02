import 'package:flutter/foundation.dart';

import '../../../core/internal_traffic.dart' show normDomain;
import '../../../data/models/indicator.dart';
import '../../../data/models/metrics_source.dart';
import '../../../data/models/workspace.dart';
import '../../../l10n/l10n.dart';
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

/// Au-delà, les couleurs des courbes se répètent (une est prise par le total).
const int kSiteLinesMax = 6;

/// Ligne d'un tableau « Sites » dont le site reste à choisir.
const SiteLine kEmptySiteLine = SiteLine(site: SiteRef('', ''), label: '');

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
    this.siteLines = const [],
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

  /// Lignes d'un tableau « Sites ». Une ligne sans site choisi a un
  /// [SiteRef] vide.
  final List<SiteLine> siteLines;

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
      SitesIndicator() =>
        IndicatorDraft(kind: i.kind, name: i.name, siteLines: i.lines),
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
    List<SiteLine>? siteLines,
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
        siteLines: siteLines ?? this.siteLines,
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
      IndicatorKind.external || IndicatorKind.sites => const EventQuery(''),
    };
    if (carried.event.isEmpty) return _withFirstLine(copyWith(kind: next));
    return switch (next) {
      IndicatorKind.external => copyWith(kind: next),
      IndicatorKind.sites => _withFirstLine(copyWith(kind: next)),
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

  /// Un tableau « Sites » s'ouvre sur une ligne à remplir.
  static IndicatorDraft _withFirstLine(IndicatorDraft d) =>
      d.kind == IndicatorKind.sites && d.siteLines.isEmpty
          ? d.copyWith(siteLines: const [kEmptySiteLine])
          : d;

  /// Nom proposé tant que le champ « Nom » reste vide.
  String suggestedName(AppLocalizations l10n) {
    final parts = switch (kind) {
      IndicatorKind.counter => [_label(query)],
      IndicatorKind.ratio => [_label(query), _label(denominator)],
      IndicatorKind.funnel => [steps.first.event, steps.last.event],
      IndicatorKind.breakdown => [breakdownEvent, breakdownProperty],
      IndicatorKind.external => [metricLabel],
      IndicatorKind.sites => [for (final l in siteLines) l.label.trim()],
    }.where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return l10n.editorNameFallback;
    if (parts.length == 1) return parts.single;
    return switch (kind) {
      IndicatorKind.sites => parts.join(' · '),
      IndicatorKind.ratio => '${parts[0]} / ${parts[1]}',
      IndicatorKind.funnel => '${parts[0]} → ${parts[1]}',
      _ => l10n.editorNameBy(parts[0], parts[1]),
    };
  }

  static String _label(EventQuery q) => q.event.isEmpty ? '' : queryLabel(q);

  /// Raison courte pour laquelle le brouillon ne peut pas être enregistré, ou
  /// null s'il est valide.
  String? validationError(AppLocalizations l10n) {
    switch (kind) {
      case IndicatorKind.counter:
        return query.event.isEmpty
            ? l10n.editorErrChooseEvent
            : _filtersError(l10n, query);
      case IndicatorKind.ratio:
        if (query.event.isEmpty) return l10n.editorErrChooseCountEvent;
        if (denominator.event.isEmpty) return l10n.editorErrChooseRefEvent;
        return _filtersError(l10n, query) ?? _filtersError(l10n, denominator);
      case IndicatorKind.funnel:
        return _funnelError(l10n);
      case IndicatorKind.breakdown:
        if (breakdownEvent.isEmpty) return l10n.editorErrChooseEvent;
        if (breakdownProperty.isEmpty) return l10n.editorErrChooseProperty;
        return null;
      case IndicatorKind.external:
        return metricId.isEmpty ? l10n.editorErrChooseMetric : null;
      case IndicatorKind.sites:
        return _sitesError(l10n);
    }
  }

  String? _sitesError(AppLocalizations l10n) {
    if (siteLines.isEmpty) return l10n.editorErrAddSite;
    if (siteLines.length > kSiteLinesMax) {
      return l10n.editorErrSitesMax(kSiteLinesMax);
    }
    for (final l in siteLines) {
      if (l.site.siteId.isEmpty) return l10n.editorErrChooseLineSite;
      if (l.label.trim().isEmpty) return l10n.editorErrNameLines;
      if (l.mode != ReferrerMode.all && normDomain(l.referrer).isEmpty) {
        return l10n.editorErrReferrer;
      }
    }
    return null;
  }

  String? _funnelError(AppLocalizations l10n) {
    if (steps.length < kFunnelMinSteps) {
      return l10n.editorErrFunnelMin(kFunnelMinSteps);
    }
    if (steps.length > kFunnelMaxSteps) {
      return l10n.editorErrFunnelMax(kFunnelMaxSteps);
    }
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].event.isEmpty) return l10n.editorErrStepEvent(i + 1);
    }
    for (final s in steps) {
      final e = _filtersError(l10n, s);
      if (e != null) return e;
      if (s.filters.any((f) => !kFunnelOps.contains(f.op))) {
        return l10n.editorErrFunnelNumeric;
      }
    }
    return windowMinutes == null ? l10n.editorErrWindow : null;
  }

  /// Délai en minutes, null s'il n'est pas un entier de 1 à 1440.
  int? get windowMinutes {
    final m = int.tryParse(windowText.trim());
    return m != null && m >= kFunnelMinWindow && m <= kFunnelMaxWindow ? m : null;
  }

  static String? _filtersError(AppLocalizations l10n, EventQuery q) {
    for (final f in q.filters) {
      if (f.value.trim().isEmpty) return l10n.editorErrFilterValueMissing;
      if (f.type == PropertyType.number && num.tryParse(f.value.trim()) == null) {
        return l10n.editorErrFilterNotNumber;
      }
    }
    return null;
  }

  /// Null tant que [validationError] en trouve une. Un nom laissé vide prend
  /// [suggestedName].
  Indicator? toIndicator(String id, AppLocalizations l10n) {
    if (validationError(l10n) != null) return null;
    final label = name.trim().isEmpty ? suggestedName(l10n) : name.trim();
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
      IndicatorKind.sites => SitesIndicator(
          id: id,
          name: label,
          lines: [
            for (final l in siteLines)
              l.copyWith(
                label: l.label.trim(),
                // Umami range le référent sans schéma ni `www.`.
                referrer: l.mode == ReferrerMode.all ? '' : normDomain(l.referrer),
              ),
          ],
        ),
    };
  }
}
