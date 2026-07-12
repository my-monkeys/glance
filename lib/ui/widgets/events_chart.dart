import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../data/models/models.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import 'chart_util.dart';

/// Palette catégorielle (une couleur par événement). Tons sourds/éditoriaux qui
/// tiennent sur fond crème comme sur fond sombre.
const List<Color> kEventPalette = [
  Color(0xFF3B7A5A), // vert (accent)
  Color(0xFFC97F44), // ocre / terracotta
  Color(0xFF4A6FA5), // bleu ardoise
  Color(0xFF9A5BA6), // prune
  Color(0xFF3E9188), // sarcelle
  Color(0xFFB0658A), // rose
  Color(0xFF9A8A3C), // olive / or
  Color(0xFFC2603F), // rouille
];

Color eventColorAt(int i) => kEventPalette[i % kEventPalette.length];

/// Graphique multi-lignes : une courbe lissée par événement, échelle Y partagée,
/// tooltip qui liste chaque événement à la date pointée.
class EventsChart extends StatelessWidget {
  const EventsChart({
    super.key,
    required this.series,
    required this.colors,
    required this.unit,
    this.height = 200,
  });

  final List<EventSeries> series; // séries visibles
  final Map<String, Color> colors; // nom → couleur (stable)
  final String unit;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    if (series.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('Aucune série sélectionnée',
              style: GT.body(13, color: p.fg3)),
        ),
      );
    }

    final len = series.first.points.length;
    final rawMax = series
        .expand((s) => s.points.map((e) => e.visitors))
        .fold<double>(0, math.max);
    final maxY = chartNiceMax(rawMax);
    final yInterval = maxY / 4;
    final lastX = (len - 1).toDouble();
    final labelStep = math.max(1, (len / 6).ceil());
    final times = series.first.points.map((e) => e.t).toList();

    return SizedBox(
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
            getDrawingHorizontalLine: (v) => FlLine(color: p.line, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                    child: Text(fmtCount(value),
                        style: GT.mono(9.5, color: p.fg3),
                        textAlign: TextAlign.right),
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
                  if (i < 0 || i >= len) return const SizedBox.shrink();
                  final isLast = i == len - 1;
                  if (i % labelStep != 0 && !isLast) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(fmtAxis(times[i], unit),
                        style: GT.mono(9.5, color: p.fg3)),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => p.fg,
              tooltipBorderRadius: BorderRadius.circular(10),
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              maxContentWidth: 220,
              getTooltipItems: (touched) {
                final i = touched.isEmpty
                    ? 0
                    : touched.first.x.round().clamp(0, len - 1);
                final date = chartTooltipDate(times[i], unit);
                return [
                  for (var k = 0; k < touched.length; k++)
                    LineTooltipItem(
                      k == 0 ? '$date\n' : '',
                      GT.mono(10, color: p.fg3),
                      children: [
                        TextSpan(
                          text: '${fmtInt(touched[k].y)} ',
                          style: GT.stat(13, color: p.bg),
                        ),
                        TextSpan(
                          text: series[touched[k].barIndex].name,
                          style: GT.mono(9,
                              color: colors[series[touched[k].barIndex].name] ??
                                  p.fg3),
                        ),
                      ],
                    ),
                ];
              },
            ),
          ),
          lineBarsData: [
            for (var s = 0; s < series.length; s++)
              LineChartBarData(
                spots: [
                  for (var i = 0; i < len; i++)
                    FlSpot(i.toDouble(), series[s].points[i].visitors),
                ],
                isCurved: true,
                curveSmoothness: 0.32,
                preventCurveOverShooting: true,
                color: colors[series[s].name] ?? eventColorAt(s),
                barWidth: 2.2,
                isStrokeCapRound: true,
                isStrokeJoinRound: true,
                dotData: const FlDotData(show: false),
              ),
          ],
        ),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
