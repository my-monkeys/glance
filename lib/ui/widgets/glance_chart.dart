import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/predict.dart';
import '../../data/models/models.dart';
import '../../data/models/period.dart';
import '../../state/settings.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import 'chart_model.dart';
import 'chart_util.dart';

/// Graphique de série temporelle : courbe lissée à aire dégradée, ou barres,
/// selon le réglage d'affichage. La légende, l'échelle et les axes sont les
/// mêmes dans les deux cas — seul le trait change.
class GlanceChart extends StatelessWidget {
  const GlanceChart({
    super.key,
    required this.series,
    required this.unit,
    this.height = 168,
    this.showPageviews = false,
    this.pageviewsTotal,
    this.visitorsTotal,
    this.forecast,
    this.compareSeries,
    this.hidden = const {},
    this.onToggle,
    this.style = ChartStyle.curve,
    this.trailing,
  });

  static const kVisitors = ChartModel.kVisitorsKey;
  static const kPageviews = ChartModel.kPageviewsKey;
  static const kForecast = ChartModel.kForecastKey;
  static const kCompare = ChartModel.kCompareKey;

  final List<SeriesPoint> series;
  final TimeUnit unit;
  final double height;

  /// Superpose une seconde courbe « pages vues » + une légende.
  final bool showPageviews;
  final int? pageviewsTotal;

  /// Total visiteurs uniques (courbe verte).
  final int? visitorsTotal;

  /// Prévision (pointillé orange) : complète le bucket courant et prolonge la
  /// courbe visiteurs jusqu'à la fin de la période calendaire.
  final Forecast? forecast;

  /// Courbe de la période précédente équivalente (bascule « Comparer »),
  /// superposée sur les mêmes positions de bucket que [series].
  final List<SeriesPoint>? compareSeries;

  /// Séries masquées (clés [kVisitors]/[kPageviews]/[kForecast]/[kCompare]) et
  /// bascule via la légende.
  final Set<String> hidden;
  final void Function(String key)? onToggle;

  final ChartStyle style;

  /// Posé à droite de la légende — le sélecteur de découpage y vit.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    if (series.isEmpty) return SizedBox(height: height);

    final model = ChartModel.from(
      series: series,
      unit: unit,
      showPageviews: showPageviews,
      hidden: hidden,
      palette: p,
      forecast: forecast,
      compareSeries: compareSeries,
    );

    final chart = SizedBox(
      height: height,
      child: model.drawn.isEmpty
          ? const SizedBox.shrink()
          : switch (style) {
              ChartStyle.curve => _CurveBody(model: model, palette: p),
              ChartStyle.bars => _BarsBody(model: model, palette: p),
            },
    );

    if (!showPageviews) return chart;

    final projected = (forecast != null && visitorsTotal != null)
        ? forecast!.projectedTotal(visitorsTotal!)
        : null;
    final hasCompare = (compareSeries ?? const []).isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    if (visitorsTotal != null)
                      _LegendItem(
                        color: p.accent,
                        label: 'Visiteurs',
                        value: visitorsTotal,
                        on: !hidden.contains(kVisitors),
                        onTap:
                            onToggle == null ? null : () => onToggle!(kVisitors),
                      ),
                    _LegendItem(
                      color: p.fg2,
                      label: 'Pages vues',
                      value: pageviewsTotal,
                      on: !hidden.contains(kPageviews),
                      onTap:
                          onToggle == null ? null : () => onToggle!(kPageviews),
                    ),
                    if (model.hasForecast)
                      _LegendItem(
                        color: p.forecast,
                        label: 'Prévision',
                        value: projected,
                        approx: true,
                        on: !hidden.contains(kForecast),
                        onTap:
                            onToggle == null ? null : () => onToggle!(kForecast),
                      ),
                    if (hasCompare)
                      _LegendItem(
                        color: p.fg3,
                        label: 'Période précédente',
                        on: !hidden.contains(kCompare),
                        onTap:
                            onToggle == null ? null : () => onToggle!(kCompare),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
        ),
        chart,
      ],
    );
  }
}

/// Contenu du tooltip, partagé par les deux moteurs : une date en entête, puis
/// une ligne par série visible à cette position.
///
/// [visible] est dans l'ordre de tracé, celui des index que les deux moteurs
/// donnent à leurs séries.
List<TextSpan> _tooltipLines({
  required ChartModel model,
  required int x,
  required GlancePalette p,
  Iterable<ChartSeries>? only,
}) {
  final spans = <TextSpan>[];
  for (final s in only ?? model.drawn) {
    final v = s.at(x);
    if (v == null) continue;
    // Le point de raccord de la prévision duplique la valeur observée.
    if (s.role == ChartSeriesRole.forecast &&
        x == model.fcStart &&
        model.fcStart < model.series.length - 1) {
      continue;
    }
    final fc = s.role == ChartSeriesRole.forecast;
    spans.add(TextSpan(
      text: '${fc ? '≈' : ''}${fmtInt(v)} ',
      style: GT.stat(14, color: fc ? p.forecast : p.bg),
    ));
    spans.add(TextSpan(
      text: '${s.label}\n',
      style: GT.mono(9, color: p.fg3),
    ));
  }
  if (spans.isNotEmpty) {
    // Retire le saut de ligne final.
    final last = spans.removeLast();
    spans.add(TextSpan(text: last.text!.trimRight(), style: last.style));
  }
  return spans;
}

/// Rendu en courbes lissées (défaut).
class _CurveBody extends StatelessWidget {
  const _CurveBody({required this.model, required this.palette});
  final ChartModel model;
  final GlancePalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final m = model;

    LineChartBarData barOf(ChartSeries s) {
      final spots = [
        for (var i = 0; i < s.values.length; i++)
          FlSpot((s.offset + i).toDouble(), s.values[i]),
      ];
      final isForecast = s.role == ChartSeriesRole.forecast;
      final isCompare = s.role == ChartSeriesRole.compare;
      final isVisitors = s.role == ChartSeriesRole.visitors;
      return LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.32,
        preventCurveOverShooting: true,
        color: s.color,
        barWidth: switch (s.role) {
          ChartSeriesRole.visitors => 2.6,
          ChartSeriesRole.pageviews => 1.8,
          ChartSeriesRole.forecast => 2.2,
          ChartSeriesRole.compare => 1.8,
        },
        isStrokeCapRound: true,
        isStrokeJoinRound: true,
        dashArray: isForecast
            ? [6, 5]
            : isCompare
                ? [3, 4]
                : null,
        dotData: FlDotData(
          show: !isCompare,
          checkToShowDot: (spot, bar) => isForecast
              ? spot.x == m.lastX && m.lastX > m.lastObsX
              : spot.x == m.lastObsX,
          getDotPainter: (s2, pr, b, idx) => FlDotCirclePainter(
            radius: isForecast ? 3.5 : 4,
            color: isForecast ? p.surface : s.color,
            strokeColor: isForecast ? p.forecast : p.surface,
            strokeWidth: 2,
          ),
        ),
        belowBarData: BarAreaData(
          show: isVisitors,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              s.color.withValues(alpha: 0.20),
              s.color.withValues(alpha: 0.0),
            ],
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: m.lastX,
        minY: 0,
        maxY: m.maxY,
        gridData: buildChartGrid(m, p),
        borderData: FlBorderData(show: false),
        titlesData: buildChartTitles(m, p),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => p.fg,
            tooltipBorderRadius: BorderRadius.circular(10),
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            maxContentWidth: 220,
            getTooltipItems: (touched) {
              if (touched.isEmpty) return const [];
              final x = touched.first.x.round().clamp(0, m.xCount - 1);
              final date = chartTooltipDate(m.timeAt(x), m.unit);
              // Un seul item porte tout le contenu : fl_chart en dessine un par
              // point touché, et n lignes identiques se superposeraient.
              return [
                LineTooltipItem(
                  '$date\n',
                  GT.mono(10, color: p.fg3),
                  children: _tooltipLines(model: m, x: x, p: p),
                ),
                for (var i = 1; i < touched.length; i++) null,
              ];
            },
          ),
          getTouchedSpotIndicator: (bar, indexes) => indexes
              .map(
                (i) => TouchedSpotIndicatorData(
                  FlLine(color: p.fg.withValues(alpha: 0.28), strokeWidth: 1.5),
                  FlDotData(
                    getDotPainter: (s, pr, b, idx) => FlDotCirclePainter(
                      radius: 4.5,
                      color: b.color ?? p.fg,
                      strokeColor: p.surface,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        lineBarsData: [for (final s in m.drawn) barOf(s)],
      ),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }
}

/// Rendu en barres. La comparaison y devient un fantôme derrière la barre
/// courante plutôt qu'une cinquième série, et la prévision une barre en
/// remplissage atténué bordée de pointillés — une barre ne peut pas être
/// tracée en trait discontinu.
class _BarsBody extends StatelessWidget {
  const _BarsBody({required this.model, required this.palette});
  final ChartModel model;
  final GlancePalette palette;

  /// En deçà, une barre n'est plus qu'un trait : la courbe redevient le bon
  /// rendu. Atteignable en deux gestes avec le sélecteur de découpage.
  static const double _minRodWidth = 2;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final m = model;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - kChartLeftAxisWidth;
        final rods = m.drawn
            .where((s) => s.role != ChartSeriesRole.compare)
            .toList(growable: false);
        final perGroup = rods.isEmpty ? 1 : rods.length;
        final rodWidth =
            (available / m.xCount / perGroup - 1).clamp(0.5, 18.0).toDouble();
        if (rodWidth < _minRodWidth) {
          return _CurveBody(model: m, palette: p);
        }

        final compare = m.drawn
            .where((s) => s.role == ChartSeriesRole.compare)
            .firstOrNull;

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceEvenly,
            groupsSpace: 0,
            maxY: m.maxY,
            minY: 0,
            gridData: buildChartGrid(m, p),
            borderData: FlBorderData(show: false),
            titlesData: buildChartTitles(m, p),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => p.fg,
                tooltipBorderRadius: BorderRadius.circular(10),
                tooltipPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                maxContentWidth: 220,
                // La signature ne donne qu'une barre à la fois ; on reconstruit
                // tout le bucket pour garder le même tooltip qu'en courbes.
                getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                  '${chartTooltipDate(m.timeAt(group.x), m.unit)}\n',
                  GT.mono(10, color: p.fg3),
                  children: _tooltipLines(model: m, x: group.x, p: p),
                ),
              ),
            ),
            barGroups: [
              for (var x = 0; x < m.xCount; x++)
                BarChartGroupData(
                  x: x,
                  barsSpace: 1,
                  barRods: [
                    for (final s in rods)
                      if (s.at(x) case final v?)
                        BarChartRodData(
                          toY: v,
                          width: rodWidth,
                          color: s.role == ChartSeriesRole.forecast
                              ? s.color.withValues(alpha: 0.16)
                              : s.color,
                          borderSide: s.role == ChartSeriesRole.forecast
                              ? BorderSide(color: s.color, width: 1.2)
                              : BorderSide.none,
                          borderDashArray: s.role == ChartSeriesRole.forecast
                              ? [4, 3]
                              : null,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(rodWidth / 3),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: compare != null &&
                                s.role == ChartSeriesRole.visitors,
                            toY: compare?.at(x) ?? 0,
                            color: p.fg3.withValues(alpha: 0.22),
                          ),
                        ),
                  ],
                ),
            ],
          ),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      },
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.value,
    this.approx = false,
    this.on = true,
    this.onTap,
  });
  final Color color;
  final String label;
  final bool approx;
  final bool on;
  final VoidCallback? onTap;
  final int? value;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: on ? 1 : 0.4,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            if (value != null) ...[
              Text(
                '${approx ? '≈' : ''}${fmtInt(value!)}',
                style: GT.mono(12, weight: 600, color: color),
              ),
              const SizedBox(width: 4),
            ],
            Text(label, style: GT.body(12, color: p.fg2)),
          ],
        ),
      ),
    );
  }
}
