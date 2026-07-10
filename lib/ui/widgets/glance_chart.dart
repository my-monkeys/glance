import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../data/models/models.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';

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
  });

  final List<SeriesPoint> series;
  final String unit; // 'hour' | 'day' | 'month'
  final double height;

  /// Superpose une seconde courbe « pages vues » + une légende.
  final bool showPageviews;
  final int? visitorsTotal;
  final int? pageviewsTotal;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    if (series.isEmpty) {
      return SizedBox(height: height);
    }
    final altColor = p.fg2;

    final visitors = series.map((e) => e.visitors).toList();
    final views = series.map((e) => e.pageviews).toList();
    // Échelle partagée : le max doit couvrir la plus haute des deux courbes.
    final rawMax = [
      ...visitors,
      if (showPageviews) ...views,
    ].fold<double>(0, math.max);
    final maxY = _niceMax(rawMax);
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
                for (var k = 0; k < touched.length; k++) {
                  final t = touched[k];
                  final i = t.x.round().clamp(0, series.length - 1);
                  final date = _tooltipDate(series[i].t, unit);
                  // Une seule courbe : gros chiffre + date.
                  if (!showPageviews) {
                    return [
                      LineTooltipItem(
                        '${fmtInt(t.y)}\n',
                        GT.stat(15, color: p.bg),
                        children: [
                          TextSpan(text: date, style: GT.mono(10, color: p.fg3)),
                        ],
                      ),
                    ];
                  }
                }
                // Deux courbes : date en tête, puis « visiteurs · pages vues ».
                final i = touched.isEmpty
                    ? 0
                    : touched.first.x.round().clamp(0, series.length - 1);
                final date = _tooltipDate(series[i].t, unit);
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
                          text: touched[k].barIndex == (showPageviews ? 1 : 0)
                              ? 'visiteurs'
                              : 'pages vues',
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
            if (showPageviews)
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
              ),
              const SizedBox(width: 16),
              _LegendItem(
                color: altColor,
                label: 'Pages vues',
                value: pageviewsTotal,
              ),
            ],
          ),
        ),
        chart,
      ],
    );
  }

  static String _tooltipDate(DateTime t, String unit) {
    switch (unit) {
      case 'hour':
        return DateFormat("d MMM · HH'h'", 'fr_FR').format(t);
      case 'month':
        return DateFormat('MMMM yyyy', 'fr_FR').format(t);
      default:
        return DateFormat('EEE d MMM', 'fr_FR').format(t);
    }
  }

  /// Arrondit le max vers une valeur « ronde » avec un peu de marge.
  static double _niceMax(double m) {
    if (m <= 0) return 10;
    final v = m * 1.15;
    final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    final norm = v / mag;
    double nice;
    if (norm <= 1) {
      nice = 1;
    } else if (norm <= 2) {
      nice = 2;
    } else if (norm <= 2.5) {
      nice = 2.5;
    } else if (norm <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * mag;
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label, this.value});
  final Color color;
  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Row(
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
    );
  }
}
