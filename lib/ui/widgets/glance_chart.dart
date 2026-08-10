import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/predict.dart';
import '../../data/models/models.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import 'chart_util.dart';

/// Graphique de série temporelle « propre » : courbe lissée, extrémités
/// arrondies, aire dégradée, échelle Y et labels X. C'est l'équivalent Flutter
/// du rendu Chart.js recherché.
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
    this.hidden = const {},
    this.onToggle,
  });

  static const kVisitors = 'visitors';
  static const kPageviews = 'pageviews';
  static const kForecast = 'forecast';

  final List<SeriesPoint> series;
  final String unit; // 'hour' | 'day' | 'month'
  final double height;

  /// Superpose une seconde courbe « pages vues » + une légende.
  final bool showPageviews;
  final int? pageviewsTotal;

  /// Total visiteurs uniques (courbe verte).
  final int? visitorsTotal;

  /// Prévision (pointillé orange) : complète le bucket courant et prolonge la
  /// courbe visiteurs jusqu'à la fin de la période calendaire.
  final Forecast? forecast;

  /// Séries masquées (clés [kVisitors]/[kPageviews]/[kForecast]) et bascule via
  /// la légende.
  final Set<String> hidden;
  final void Function(String key)? onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    if (series.isEmpty) {
      return SizedBox(height: height);
    }
    final altColor = p.fg2;

    // Deux courbes : visiteurs uniques (vert, aire) + pages vues (gris).
    final showVisitors = !hidden.contains(kVisitors);
    final showViews = showPageviews && !hidden.contains(kPageviews);

    // Prévision : son premier point coïncide avec un bucket observé (raccord).
    final fcPoints = forecast?.points ?? const <SeriesPoint>[];
    var fcStart = -1;
    if (fcPoints.isNotEmpty) {
      final t0 = fcPoints.first.t;
      fcStart = series.indexWhere((e) => e.t == t0);
    }
    final hasFc = fcStart >= 0;
    final showFc = hasFc && !hidden.contains(kForecast);

    final visitors = series.map((e) => e.visitors).toList();
    final views = series.map((e) => e.pageviews).toList();
    // Échelle : le max ne couvre que les courbes visibles (rescale au masquage).
    final rawMax = [
      if (showVisitors) ...visitors,
      if (showViews) ...views,
      if (showFc) ...fcPoints.map((e) => e.visitors),
    ].fold<double>(0, math.max);
    final maxY = chartNiceMax(rawMax);
    final yInterval = maxY / 4;

    final visitorSpots = [
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), visitors[i]),
    ];
    final viewSpots = [
      for (var i = 0; i < series.length; i++) FlSpot(i.toDouble(), views[i]),
    ];
    final fcSpots = [
      for (var k = 0; k < fcPoints.length; k++)
        FlSpot((fcStart + k).toDouble(), fcPoints[k].visitors),
    ];
    final lastObsX = (series.length - 1).toDouble();

    // Axe X : étendu aux buckets futurs quand la prévision est affichée.
    final xCount = showFc
        ? math.max(series.length, fcStart + fcPoints.length)
        : series.length;
    final lastX = (xCount - 1).toDouble();
    DateTime timeAt(int i) =>
        i < series.length ? series[i].t : fcPoints[i - fcStart].t;

    // Une barre lissée avec point terminal. `area` = aire dégradée sous la courbe.
    LineChartBarData lineBar(
      List<FlSpot> spots,
      Color color,
      double width, {
      bool area = false,
    }) =>
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.32,
          preventCurveOverShooting: true,
          color: color,
          barWidth: width,
          isStrokeCapRound: true,
          isStrokeJoinRound: true,
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, bar) => spot.x == lastObsX,
            getDotPainter: (s, pr, b, idx) => FlDotCirclePainter(
              radius: 4,
              color: color,
              strokeColor: p.surface,
              strokeWidth: 2,
            ),
          ),
          belowBarData: BarAreaData(
            show: area,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.20),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        );

    // Pointillé orange, point terminal creux sur le dernier bucket projeté.
    LineChartBarData forecastBar() => LineChartBarData(
          spots: fcSpots,
          isCurved: true,
          curveSmoothness: 0.32,
          preventCurveOverShooting: true,
          color: p.forecast,
          barWidth: 2.2,
          isStrokeCapRound: true,
          isStrokeJoinRound: true,
          dashArray: [6, 5],
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, bar) => spot.x == lastX && lastX > lastObsX,
            getDotPainter: (s, pr, b, idx) => FlDotCirclePainter(
              radius: 3.5,
              color: p.surface,
              strokeColor: p.forecast,
              strokeWidth: 2,
            ),
          ),
        );

    // Courbes visibles dans l'ordre de tracé (prévision dessous → pages vues →
    // visiteurs avec aire dessus). Clé/libellé et barre construits ensemble :
    // le tooltip mappe barIndex → libellé sans risque de désync.
    final drawn = <({String label, LineChartBarData bar})>[
      if (showFc) (label: 'prévision', bar: forecastBar()),
      if (showViews)
        (label: 'pages vues', bar: lineBar(viewSpots, altColor, 1.8)),
      if (showVisitors)
        (label: 'visiteurs', bar: lineBar(visitorSpots, p.accent, 2.6, area: true)),
    ];

    // Nombre de labels X visés selon la largeur.
    final labelStep = math.max(1, (xCount / 6).ceil());

    final chart = SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: lastX,
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: p.line, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  if (value < yInterval / 2 && value != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      fmtCount(value),
                      style: GT.mono(9.5, color: p.fg3),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= xCount) {
                    return const SizedBox.shrink();
                  }
                  // Affiche ~6 labels + le dernier.
                  final isLast = i == xCount - 1;
                  if (i % labelStep != 0 && !isLast) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      fmtAxis(timeAt(i), unit),
                      style: GT.mono(
                        9.5,
                        color: i > lastObsX ? p.forecast : p.fg3,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => p.fg,
              tooltipBorderRadius: BorderRadius.circular(10),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              getTooltipItems: (touched) {
                // Libellés dans l'ordre de tracé → mappe barIndex → libellé.
                final visibleKeys = [for (final d in drawn) d.label];
                String labelOf(LineBarSpot s) => s.barIndex < visibleKeys.length
                    ? visibleKeys[s.barIndex]
                    : '';
                // Le point de raccord de la prévision duplique la valeur
                // observée → pas de ligne tooltip pour lui.
                bool isBridge(LineBarSpot s) =>
                    labelOf(s) == 'prévision' &&
                    s.x.round() == fcStart &&
                    fcStart < series.length - 1;
                final xi = touched.isEmpty
                    ? 0
                    : touched.first.x.round().clamp(0, xCount - 1);
                final date = chartTooltipDate(timeAt(xi), unit);
                // Une seule courbe visible : gros chiffre + date.
                if (visibleKeys.length <= 1) {
                  return [
                    for (final s in touched)
                      LineTooltipItem(
                        '${fmtInt(s.y)}\n',
                        GT.stat(15, color: p.bg),
                        children: [
                          TextSpan(text: date, style: GT.mono(10, color: p.fg3)),
                        ],
                      ),
                  ];
                }
                final items = <LineTooltipItem?>[];
                var headerDone = false;
                for (final s in touched) {
                  if (isBridge(s)) {
                    items.add(null);
                    continue;
                  }
                  final fc = labelOf(s) == 'prévision';
                  items.add(LineTooltipItem(
                    headerDone ? '' : '$date\n',
                    GT.mono(10, color: p.fg3),
                    children: [
                      TextSpan(
                        text: '${fc ? '≈' : ''}${fmtInt(s.y)} ',
                        style: GT.stat(14, color: fc ? p.forecast : p.bg),
                      ),
                      TextSpan(
                        text: labelOf(s),
                        style: GT.mono(9, color: p.fg3),
                      ),
                    ],
                  ));
                  headerDone = true;
                }
                return items;
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
          lineBarsData: [for (final d in drawn) d.bar],
        ),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      ),
    );

    if (!showPageviews) return chart;

    final projected = (forecast != null && visitorsTotal != null)
        ? forecast!.projectedTotal(visitorsTotal!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              // Visiteurs uniques (vert) + pages vues (gris) + prévision
              // (orange), basculables.
              if (visitorsTotal != null)
                _LegendItem(
                  color: p.accent,
                  label: 'Visiteurs',
                  value: visitorsTotal,
                  on: showVisitors,
                  onTap: onToggle == null ? null : () => onToggle!(kVisitors),
                ),
              _LegendItem(
                color: altColor,
                label: 'Pages vues',
                value: pageviewsTotal,
                on: showViews,
                onTap: onToggle == null ? null : () => onToggle!(kPageviews),
              ),
              if (hasFc)
                _LegendItem(
                  color: p.forecast,
                  label: 'Prévision',
                  value: projected,
                  approx: true,
                  on: showFc,
                  onTap: onToggle == null ? null : () => onToggle!(kForecast),
                ),
            ],
          ),
        ),
        chart,
      ],
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
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
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
