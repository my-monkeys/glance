import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
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
    this.visitorsTotal,
    this.pageviewsTotal,
    this.hidden = const {},
    this.onToggle,
  });

  static const kVisitors = 'visitors';
  static const kPageviews = 'pageviews';

  final List<SeriesPoint> series;
  final String unit; // 'hour' | 'day' | 'month'
  final double height;

  /// Superpose une seconde courbe « pages vues » + une légende.
  final bool showPageviews;
  final int? visitorsTotal;
  final int? pageviewsTotal;

  /// Séries masquées (clés [kVisitors]/[kPageviews]) et bascule via la légende.
  final Set<String> hidden;
  final void Function(String key)? onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    if (series.isEmpty) {
      return SizedBox(height: height);
    }
    final altColor = p.fg2;

    final showVisitors = !hidden.contains(kVisitors);
    final showViews = showPageviews && !hidden.contains(kPageviews);

    final visitors = series.map((e) => e.visitors).toList();
    final views = series.map((e) => e.pageviews).toList();
    // Échelle : le max ne couvre que les courbes visibles → masquer les pages
    // vues fait « remonter » la courbe visiteurs (rescale automatique).
    final rawMax = [
      if (showVisitors) ...visitors,
      if (showViews) ...views,
    ].fold<double>(0, math.max);
    final maxY = chartNiceMax(rawMax);
    final yInterval = maxY / 4;

    final visitorSpots = [
      for (var i = 0; i < series.length; i++) FlSpot(i.toDouble(), visitors[i]),
    ];
    final viewSpots = [
      for (var i = 0; i < series.length; i++) FlSpot(i.toDouble(), views[i]),
    ];
    final lastX = (series.length - 1).toDouble();

    // Nombre de labels X visés selon la largeur.
    final labelStep = math.max(1, (series.length / 6).ceil());

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
                  if (i < 0 || i >= series.length) {
                    return const SizedBox.shrink();
                  }
                  // Affiche ~6 labels + le dernier.
                  final isLast = i == series.length - 1;
                  if (i % labelStep != 0 && !isLast) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      fmtAxis(series[i].t, unit),
                      style: GT.mono(9.5, color: p.fg3),
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
                // Ordre des courbes tracées = clés visibles (pages vues dessous,
                // visiteurs dessus) pour mapper barIndex → libellé.
                final visibleKeys = [
                  if (showViews) 'pages vues',
                  if (showVisitors) 'visiteurs',
                ];
                final i = touched.isEmpty
                    ? 0
                    : touched.first.x.round().clamp(0, series.length - 1);
                final date = chartTooltipDate(series[i].t, unit);
                // Une seule courbe visible : gros chiffre + date.
                if (visibleKeys.length <= 1) {
                  return [
                    LineTooltipItem(
                      '${fmtInt(touched.isEmpty ? 0 : touched.first.y)}\n',
                      GT.stat(15, color: p.bg),
                      children: [
                        TextSpan(text: date, style: GT.mono(10, color: p.fg3)),
                      ],
                    ),
                  ];
                }
                return [
                  for (var k = 0; k < touched.length; k++)
                    LineTooltipItem(
                      k == 0 ? '$date\n' : '',
                      GT.mono(10, color: p.fg3),
                      children: [
                        TextSpan(
                          text: '${fmtInt(touched[k].y)} ',
                          style: GT.stat(14, color: p.bg),
                        ),
                        TextSpan(
                          text: touched[k].barIndex < visibleKeys.length
                              ? visibleKeys[touched[k].barIndex]
                              : '',
                          style: GT.mono(9, color: p.fg3),
                        ),
                      ],
                    ),
                ];
              },
            ),
            getTouchedSpotIndicator: (bar, indexes) => indexes
                .map(
                  (i) => TouchedSpotIndicatorData(
                    FlLine(color: p.accent.withValues(alpha: 0.35), strokeWidth: 1.5),
                    FlDotData(
                      getDotPainter: (s, pr, b, idx) => FlDotCirclePainter(
                        radius: 4.5,
                        color: p.accent,
                        strokeColor: p.surface,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          lineBarsData: [
            // Pages vues (secondaire) — tracée dessous, sans remplissage.
            if (showViews)
              LineChartBarData(
                spots: viewSpots,
                isCurved: true,
                curveSmoothness: 0.32,
                preventCurveOverShooting: true,
                color: altColor,
                barWidth: 1.8,
                isStrokeCapRound: true,
                isStrokeJoinRound: true,
                dotData: const FlDotData(show: false),
              ),
            // Visiteurs (primaire) — accent + aire dégradée.
            if (showVisitors)
              LineChartBarData(
                spots: visitorSpots,
                isCurved: true,
                curveSmoothness: 0.32,
                preventCurveOverShooting: true,
                color: p.accent,
                barWidth: 2.6,
                isStrokeCapRound: true,
                isStrokeJoinRound: true,
                dotData: FlDotData(
                  show: true,
                  checkToShowDot: (spot, bar) => spot.x == lastX,
                  getDotPainter: (s, pr, b, idx) => FlDotCirclePainter(
                    radius: 4,
                    color: p.accent,
                    strokeColor: p.surface,
                    strokeWidth: 2,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      p.accent.withValues(alpha: 0.22),
                      p.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
          ],
        ),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      ),
    );

    if (!showPageviews) return chart;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Row(
            children: [
              _LegendItem(
                color: p.accent,
                label: 'Visiteurs',
                value: visitorsTotal,
                on: showVisitors,
                onTap: onToggle == null ? null : () => onToggle!(kVisitors),
              ),
              const SizedBox(width: 16),
              _LegendItem(
                color: altColor,
                label: 'Pages vues',
                value: pageviewsTotal,
                on: showViews,
                onTap: onToggle == null ? null : () => onToggle!(kPageviews),
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
    this.on = true,
    this.onTap,
  });
  final Color color;
  final String label;
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
              Text(fmtInt(value!), style: GT.mono(12, weight: 600, color: p.fg)),
              const SizedBox(width: 4),
            ],
            Text(label, style: GT.body(12, color: p.fg2)),
          ],
        ),
      ),
    );
  }
}
