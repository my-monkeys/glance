import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../data/models/period.dart';
import '../../theme/motion.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../widgets/chart_util.dart';

/// Un point de la courbe ; [value] null = trou dans la mesure.
class IndicatorPoint {
  const IndicatorPoint(this.t, this.value);
  final DateTime t;
  final double? value;
}

/// Courbe unique et compacte d'un indicateur : même habillage que
/// `EventsChart` (grille, axes mono, tooltip sombre), en une seule série avec
/// l'aire dégradée de la courbe des visiteurs.
class IndicatorChart extends StatelessWidget {
  const IndicatorChart({
    super.key,
    required this.points,
    required this.unit,
    this.percent = false,
    this.height = 130,
  });

  final List<IndicatorPoint> points;
  final TimeUnit unit;

  /// Valeurs en % (0..100) : axe et tooltip suffixés.
  final bool percent;
  final double height;

  String _fmt(double v) => percent ? fmtPct(v) : fmtInt(v);

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final len = points.length;
    final rawMax = points.fold<double>(0, (m, e) => math.max(m, e.value ?? 0));
    // Un taux plafonne à 100 : au-delà de l'échelle, « 200 % » en haut d'un
    // graphe dont le maximum réel est 87 écraserait la courbe pour rien.
    final niceMax = chartNiceMax(rawMax);
    final maxY = percent ? math.min(100.0, niceMax) : niceMax;
    final yInterval = maxY / 4;
    final labelStep = math.max(1, (len / 6).ceil());

    final spots = [
      for (var i = 0; i < len; i++)
        points[i].value == null
            ? FlSpot.nullSpot
            : FlSpot(i.toDouble(), points[i].value!),
    ];

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: math.max(1, len - 1).toDouble(),
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
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            // Marge à droite : le dernier libellé de l'axe X est centré sur le
            // bord du tracé et sa moitié sortirait du cadre.
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 12,
                getTitlesWidget: (_, _) => const SizedBox.shrink(),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  if (value < yInterval / 2 && value != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      percent ? '${value.round()}\u00a0%' : fmtCount(value),
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
                  if (i < 0 || i >= len) return const SizedBox.shrink();
                  if (i % labelStep != 0 && i != len - 1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(fmtAxis(points[i].t, unit),
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
              getTooltipItems: (touched) => [
                for (final s in touched)
                  LineTooltipItem(
                    '${chartTooltipDate(points[s.x.round().clamp(0, len - 1)].t, unit)}\n',
                    GT.mono(10, color: p.fg3),
                    children: [
                      TextSpan(
                        text: _fmt(s.y),
                        style: GT.stat(13, color: p.bg),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.32,
              preventCurveOverShooting: true,
              color: p.accent,
              barWidth: 2.2,
              isStrokeCapRound: true,
              isStrokeJoinRound: true,
              // Un bucket isolé entre deux trous n'a pas de segment à tracer :
              // sans point, la seule mesure du jour serait invisible.
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, bar) {
                  final i = spot.x.round();
                  bool hole(int j) =>
                      j < 0 || j >= bar.spots.length || bar.spots[j].isNull();
                  return hole(i - 1) && hole(i + 1);
                },
                getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                  radius: 2.6,
                  color: p.accent,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                applyCutOffY: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    p.accent.withValues(alpha: 0.20),
                    p.accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: kMotionSlow,
        curve: kCurveOutCubic,
      ),
    );
  }
}
