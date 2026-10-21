import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../widgets/motion.dart';
import 'funnel_bars.dart';
import 'indicator_chart.dart';
import 'indicator_menu.dart';
import 'labels.dart';

/// Lignes d'une répartition : au-delà, la carte deviendrait une liste.
const int kBreakdownRows = 8;

const _kindLabels = {
  IndicatorKind.counter: 'Compteur',
  IndicatorKind.ratio: 'Taux',
  IndicatorKind.funnel: 'Entonnoir',
  IndicatorKind.breakdown: 'Répartition',
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
  });

  final Site site;
  final DateWindow window;
  final Indicator indicator;

  /// Faux pour l'aperçu de l'éditeur, qui n'est pas encore un tableau.
  final bool menu;

  /// En-tête à afficher à la place du nom : l'aperçu y met le nom en cours de
  /// saisie sans que celui-ci entre dans la clé du provider.
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final key = (site, window, indicator);
    // `.value` garde la donnée précédente pendant un rafraîchissement : pas de
    // flash de squelette à chaque tick.
    final async = ref.watch(indicatorDataProvider(key));
    final data = async.value;

    return GlanceCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const SizedBox(width: 10),
              SectionLabel(_kindLabels[indicator.kind]!, color: p.fg3),
              if (menu)
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
          const SizedBox(height: 10),
          ClipRect(
            child: AnimatedSize(
              duration: kMotionBase,
              curve: kCurveOutCubic,
              alignment: Alignment.topCenter,
              child: GlanceSwap(
                dy: 0,
                child: KeyedSubtree(
                  key: ValueKey(data == null),
                  child: data == null
                      ? (async.hasError
                          ? _CardError(
                              onRetry: () =>
                                  ref.invalidate(indicatorDataProvider(key)),
                            )
                          : _CardSkeleton(kind: indicator.kind))
                      : _CardBody(
                          indicator: indicator,
                          data: data,
                          window: window,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.indicator,
    required this.data,
    required this.window,
  });

  final Indicator indicator;
  final IndicatorData data;
  final DateWindow window;

  @override
  Widget build(BuildContext context) {
    return switch ((indicator, data)) {
      (CounterIndicator(:final query), CounterData d) => _isEmpty(d)
          ? const _NoData()
          : _Stat(
              big: fmtInt(d.total),
              sub: queryLabel(query),
              child: IndicatorChart(
                points: [for (final s in d.points) IndicatorPoint(s.t, s.visitors)],
                unit: window.unit,
              ),
            ),
      (RatioIndicator(:final numerator, :final denominator), RatioData d) =>
        d.denominatorTotal == 0
            ? const _NoData()
            : _Stat(
                big: d.overall == null ? '—' : fmtPct(d.overall! * 100),
                sub: '${fmtInt(d.numeratorTotal)} / ${fmtInt(d.denominatorTotal)}',
                detail: '${queryLabel(numerator)} ÷ ${queryLabel(denominator)}',
                child: IndicatorChart(
                  // Les trous (dénominateur nul) viennent de `ratioOf`, selon le
                  // choix de l'indicateur.
                  points: [
                    for (final r in d.points)
                      IndicatorPoint(r.t, r.value == null ? null : r.value! * 100),
                  ],
                  unit: window.unit,
                  percent: true,
                ),
              ),
      (FunnelIndicator(), FunnelData d) => d.steps.isEmpty || d.steps.first.visitors == 0
          ? const _NoData()
          : _Stat(
              big: fmtPct(d.steps.last.remaining * 100),
              sub: '${fmtInt(d.steps.last.visitors)} / '
                  '${fmtInt(d.steps.first.visitors)} visiteurs',
              child: FunnelBars(steps: d.steps),
            ),
      (BreakdownIndicator(:final event, :final property), BreakdownData d) =>
        d.rows.isEmpty
            ? const _NoData()
            : _Stat(
                big: fmtInt(d.total),
                sub: '$event · $property',
                child: MetricBars(
                  rows: [
                    for (final r in d.rows.take(kBreakdownRows))
                      MetricBarRow(label: r.label, value: r.value),
                  ],
                  // Ici le dénominateur est la somme des lignes, pas les
                  // visiteurs du résumé comme dans le détail : chaque ligne est
                  // un nombre d'événements d'UNE propriété, qui partitionne
                  // l'événement. Leur somme est donc bien l'univers de la part.
                  total: d.total,
                ),
              ),
      // Résultat d'un autre genre (indicateur modifié pendant un rechargement).
      _ => _CardSkeleton(kind: indicator.kind),
    };
  }

  static bool _isEmpty(CounterData d) =>
      d.total == 0 && d.points.every((s) => s.visitors == 0);
}

/// Grand chiffre, ligne de contexte, puis le détail de l'indicateur.
class _Stat extends StatelessWidget {
  const _Stat({required this.big, required this.sub, required this.child, this.detail});
  final String big;
  final String sub;
  final String? detail;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          // Fredoka n'a pas l'espace fine insécable (U+202F) que `intl` met
          // entre les milliers : le groupe disparaissait (« 1994 »).
          child: Text(big.replaceAll('\u202f', '\u00a0'),
              style: GT.stat(40, color: p.fg)),
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GT.mono(11.5, color: p.fg2),
        ),
        if (detail != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              detail!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GT.mono(10.5, color: p.fg3),
            ),
          ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          'Aucune donnée sur la période',
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
    final timeSeries = kind == IndicatorKind.counter || kind == IndicatorKind.ratio;
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
  const _CardError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          Text('Chargement impossible.', style: GT.body(13, color: p.fg2)),
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
