import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/external_metrics.dart';
import '../../core/format.dart';
import '../../data/models/indicator.dart';
import '../../data/models/indicator_result.dart';
import '../../data/models/models.dart';
import '../../data/models/period.dart';
import '../../state/indicators.dart';
import '../../theme/motion.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../widgets/common.dart';
import '../widgets/events_chart.dart';
import '../widgets/motion.dart';
import 'breakdown_body.dart';
import 'card_stat.dart';
import 'funnel_bars.dart';
import 'indicator_chart.dart';
import 'indicator_menu.dart';
import 'labels.dart';
import 'segments_body.dart';

/// En deçà, l'en-tête n'affiche plus le genre de la carte.
const double _kindLabelMinWidth = 180;

const _kindLabels = {
  IndicatorKind.counter: 'Compteur',
  IndicatorKind.ratio: 'Taux',
  IndicatorKind.funnel: 'Entonnoir',
  IndicatorKind.breakdown: 'Répartition',
  IndicatorKind.external: 'Métrique',
  IndicatorKind.sites: 'Sites',
};

/// Une carte = un indicateur = une clé de `indicatorDataProvider` : chaque
/// carte s'affiche dès que SA donnée arrive, une en échec ne bloque pas les
/// autres.
class IndicatorCard extends ConsumerWidget {
  const IndicatorCard({
    super.key,
    required this.site,
    required this.window,
    required this.indicator,
    this.menu = true,
    this.title,
    this.fill = false,
    this.editing = false,
  });

  final Site site;
  final DateWindow window;
  final Indicator indicator;

  /// Faux pour l'aperçu de l'éditeur, qui n'est pas encore un tableau.
  final bool menu;

  /// En-tête à afficher à la place du nom : l'aperçu y met le nom en cours de
  /// saisie sans que celui-ci entre dans la clé du provider.
  final String? title;

  /// La grille impose la taille de la carte : la courbe prend la hauteur qui
  /// reste, et ce qui dépasse est coupé. Sinon la carte prend sa hauteur
  /// naturelle (aperçu de l'éditeur).
  final bool fill;

  /// Mode « Organiser » : une poignée remplace le menu (la grille capte les
  /// gestes, la carte ne fait que les dessiner).
  final bool editing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final key = (site, window, indicator);
    // `.value` garde la donnée précédente pendant un rafraîchissement : pas de
    // flash de squelette à chaque tick.
    final async = ref.watch(indicatorDataProvider(key));
    final data = async.value;
    Widget loose(Widget w) => fill ? CardLoose(child: w) : w;
    final body = GlanceSwap(
      dy: 0,
      child: KeyedSubtree(
        key: ValueKey(data == null),
        child: data == null
            ? loose(async.hasError
                ? _CardError(
                    message: metricsErrorMessage(async.error!),
                    onRetry: () => ref.invalidate(indicatorDataProvider(key)),
                  )
                : _CardSkeleton(kind: indicator.kind))
            : _CardBody(
                name: title ?? indicator.name,
                indicator: indicator,
                data: data,
                window: window,
                fill: fill,
              ),
      ),
    );

    return GlanceCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, c) => Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    title ?? indicator.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GT.body(14.5, weight: 600, color: p.fg),
                  ),
                ),
                // Une carte étroite de la grille garde la place pour son titre.
                if (c.maxWidth >= _kindLabelMinWidth) ...[
                  const SizedBox(width: 10),
                  SectionLabel(_kindLabels[indicator.kind]!, color: p.fg3),
                ],
                if (editing)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.drag_indicator_rounded,
                        size: 20, color: p.fg2, semanticLabel: 'Déplacer le tableau'),
                  )
                else if (menu)
                  GestureDetector(
                    onTap: () => showIndicatorMenu(context, ref, site, indicator),
                    behavior: HitTestBehavior.opaque,
                    // Zone de tap élargie : l'icône seule fait 18 px.
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.more_horiz_rounded,
                          size: 20, color: p.fg2, semanticLabel: 'Options du tableau'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (fill)
            Expanded(child: ClipRect(child: body))
          else
            ClipRect(
              child: AnimatedSize(
                duration: kMotionBase,
                curve: kCurveOutCubic,
                alignment: Alignment.topCenter,
                child: body,
              ),
            ),
        ],
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.name,
    required this.indicator,
    required this.data,
    required this.window,
    required this.fill,
  });

  /// Titre affiché de la carte : une ligne de contexte qui le répète est
  /// omise.
  final String name;
  final Indicator indicator;
  final IndicatorData data;
  final DateWindow window;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final body = _body();
    return fill && body is! CardStat ? CardLoose(child: body) : body;
  }

  Widget _body() {
    return switch ((indicator, data)) {
      (CounterIndicator(:final query), CounterData d) =>
        _counterStat(d, sub: _unlessName(queryLabel(query)), unit: window.unit),
      (RatioIndicator(:final numerator, :final denominator), RatioData d) =>
        _ratioStat(
          d,
          detail: _unlessName('${queryLabel(numerator)} ÷ ${queryLabel(denominator)}'),
          unit: window.unit,
        ),
      // Le libellé de la métrique EST le titre : pas de ligne de contexte.
      (ExternalIndicator(), RatioData d) =>
        _ratioStat(d, unit: d.unit ?? externalUnitOf(window.unit)),
      (ExternalIndicator(), CounterData d) =>
        _counterStat(d, unit: d.unit ?? externalUnitOf(window.unit)),
      (SitesIndicator(), CounterData d) => _counterStat(d, unit: window.unit),
      (FunnelIndicator(), FunnelData d) => d.steps.isEmpty || d.steps.first.visitors == 0
          ? const _NoData()
          : CardStat(
              fill: fill,
              keepChildHeight: true,
              big: fmtPct(d.steps.last.remaining * 100),
              sub: '${fmtInt(d.steps.last.visitors)} / '
                  '${fmtInt(d.steps.first.visitors)} visiteurs',
              child: FunnelBars(steps: d.steps),
            ),
      (BreakdownIndicator(:final event, :final property), BreakdownData d) =>
        d.rows.isEmpty
            ? const _NoData()
            : CardStat(
                fill: fill,
                big: fmtInt(d.total),
                sub: _unlessName('$event · $property'),
                child: BreakdownBody(
                  series: d.series,
                  unit: window.unit,
                  bars: MetricBars(
                    dense: true,
                    rows: [
                      for (final (i, r) in d.rows.take(kBreakdownRows).indexed)
                        MetricBarRow(
                          label: r.label,
                          value: r.value,
                          // Même couleur que la courbe de cette valeur.
                          color: d.series == null ? null : eventColorAt(i),
                        ),
                    ],
                    // Ici le dénominateur est la somme des lignes, pas les
                    // visiteurs du résumé comme dans le détail : chaque ligne est
                    // un nombre d'événements d'UNE propriété, qui partitionne
                    // l'événement. Leur somme est donc bien l'univers de la part.
                    total: d.total,
                  ),
                ),
              ),
      // Résultat d'un autre genre (indicateur modifié pendant un rechargement).
      _ => _CardSkeleton(kind: indicator.kind),
    };
  }

  /// Le nom par défaut d'une carte reprend sa requête (« a / b » pour « a ÷ b »,
  /// « e par p » pour « e · p ») : on compare sans les séparateurs.
  String? _unlessName(String line) {
    String norm(String t) => t.replaceAll(RegExp(r'\s*[÷/·]\s*| par '), ' ');
    return norm(line) == norm(name) ? null : line;
  }

  Widget _counterStat(
    CounterData d, {
    String? sub,
    required TimeUnit unit,
  }) {
    final gaps = d.unpublished;
    if (gaps != null && d.points.every((s) => gaps.covers(s.t))) {
      return _NoData(_unpublishedMessage(gaps));
    }
    if (d.total == 0 && d.points.every((s) => s.visitors == 0)) {
      return CardStat(big: '0', sub: 'Aucun événement sur la période', fill: fill);
    }
    final values = [
      for (final s in d.points)
        gaps != null && gaps.covers(s.t) ? null : s.visitors,
    ];
    return CardStat(
      fill: fill,
      big: fmtInt(d.total),
      sub: sub,
      notes: _notes(d.cohorts, d.member, gaps),
      child: hasSegmentData(d)
          ? SegmentsBody(data: d, totals: values, unit: unit)
          : _plots(values)
              ? IndicatorChart(
                  points: [
                    for (var i = 0; i < d.points.length; i++)
                      IndicatorPoint(d.points[i].t, values[i]),
                  ],
                  unit: unit,
                )
              : null,
    );
  }

  static String _unpublishedMessage(Unpublished u) =>
      'Pas encore publiées : données jusqu\'au ${fmtDay(u.until)}';

  static String _pendingMessage(int delayDays) => switch (delayDays) {
        0 => 'Pas encore mesurable sur cette période',
        1 => 'Pas encore mesurable : il faut 1 jour de recul',
        _ => 'Pas encore mesurable : il faut $delayDays jours de recul',
      };

  // Les trous (dénominateur nul, ou non mesurable pour une métrique de site)
  // viennent des points du résultat, pas d'ici.
  Widget _ratioStat(RatioData d, {String? detail, required TimeUnit unit}) =>
      d.denominatorTotal == 0
          ? _NoData(
              d.pending
                  ? _pendingMessage(d.delayDays)
                  : d.unpublished != null
                      ? _unpublishedMessage(d.unpublished!)
                      : 'Aucune donnée sur la période',
            )
          : CardStat(
              fill: fill,
              notes: _notes(d.cohorts, d.member, d.unpublished),
              big: d.overall == null ? '—' : fmtPct(d.overall! * 100),
              sub: '${fmtInt(d.numeratorTotal)} / ${fmtInt(d.denominatorTotal)}',
              detail: detail,
              child: _plots([for (final r in d.points) r.value])
                  ? IndicatorChart(
                      points: [
                        for (final r in d.points)
                          IndicatorPoint(
                            r.t,
                            r.value == null ? null : r.value! * 100,
                            cohort: r.cohort,
                          ),
                      ],
                      unit: unit,
                      percent: true,
                    )
                  : null,
            );

  /// Une courbe d'un seul point (ou aucun) ne dit rien de plus que le grand
  /// chiffre : on ne la dessine pas.
  /// Une courbe n'apprend quelque chose qu'avec au moins deux points qui
  /// diffèrent : une ligne plate (tout à 0 %, par exemple) ne dit rien que le
  /// grand chiffre ne dise déjà.
  static bool _plots(Iterable<double?> values) {
    final seen = values.whereType<double>().toList();
    return seen.length >= 2 && seen.any((v) => v != seen.first);
  }

  /// Cohortes mesurées, le membre retenu d'une famille, puis la fin des
  /// données publiées.
  static List<String> _notes(CohortSpan? c, String? member, Unpublished? u) => [
        if (c != null)
          c.first == c.last
              ? 'Mesurée sur la cohorte du ${fmtDay(c.first)}'
              : 'Mesurée sur les cohortes ${fmtDayRange(c.first, c.last)}',
        if (member != null) '$member · s\'ajuste à la période',
        if (u != null) 'Données jusqu\'au ${fmtDay(u.until)}',
      ];
}

class _NoData extends StatelessWidget {
  const _NoData([this.message = 'Aucune donnée sur la période']);
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          message,
          style: GT.body(13, color: context.glance.fg3),
        ),
      );
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.kind});
  final IndicatorKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.glance.chip;
    Widget block(double w, double h, [double r = 5]) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(r)),
        );
    final timeSeries = kind == IndicatorKind.counter ||
        kind == IndicatorKind.ratio ||
        kind == IndicatorKind.external;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        block(110, 32, 8),
        const SizedBox(height: 8),
        block(150, 11),
        const SizedBox(height: 14),
        if (timeSeries)
          Container(
            height: 130,
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10)),
          )
        else
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  block(90 + (i % 3) * 40, 12),
                  const SizedBox(height: 6),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _CardError extends StatelessWidget {
  const _CardError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center, style: GT.body(13, color: p.fg2)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Réessayer',
              style: GT.body(13, weight: 600, color: p.accent),
            ),
          ),
        ],
      ),
    );
  }
}
