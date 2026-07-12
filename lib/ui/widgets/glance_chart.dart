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
    this.visitsTotal,
    this.pageviewsTotal,
    this.visitorsTotal,
    this.hidden = const {},
    this.onToggle,
  });

  static const kVisitors = 'visitors';
  static const kVisits = 'visits';
  static const kPageviews = 'pageviews';

  final List<SeriesPoint> series;
  final String unit; // 'hour' | 'day' | 'month'
  final double height;

  /// Superpose une seconde courbe « pages vues » + une légende.
  final bool showPageviews;
  final int? visitsTotal;
  final int? pageviewsTotal;

  /// Total visiteurs uniques (courbe verte, toujours tracée depuis la série).
  final int? visitorsTotal;

  /// Séries masquées (clés [kVisits]/[kPageviews]) et bascule via la légende.
  final Set<String> hidden;
  final void Function(String key)? onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    if (series.isEmpty) {
      return SizedBox(height: height);
    }
    final altColor = p.fg2;

    // Visiteurs (vert) + pages vues (gris) sont toujours traçables. La courbe
    // orange des *visites* (visit_id) n'est dispo que si la série les porte :
    // Umami ne les fournit qu'au détail d'un site (un appel /stats par point) ;
    // sinon les visites restent une référence chiffrée dans la légende.
    final hasVisitsSeries = series.any((e) => e.visits != null);
    final showVisitors = !hidden.contains(kVisitors);
    final showVisits = hasVisitsSeries && !hidden.contains(kVisits);
    final showViews = showPageviews && !hidden.contains(kPageviews);

    final visitors = series.map((e) => e.visitors).toList();
    final visits = series.map((e) => e.visits ?? 0).toList();
    final views = series.map((e) => e.pageviews).toList();
    // Échelle : le max ne couvre que les courbes visibles (rescale au masquage).
    final rawMax = [
      if (showVisitors) ...visitors,
      if (showVisits) ...visits,
      if (showViews) ...views,
    ].fold<double>(0, math.max);
    final maxY = chartNiceMax(rawMax);
    final yInterval = maxY / 4;

    final visitorSpots = [
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), visitors[i]),
    ];
    final visitSpots = [
      for (var i = 0; i < series.length; i++) FlSpot(i.toDouble(), visits[i]),
    ];
    final viewSpots = [
      for (var i = 0; i < series.length; i++) FlSpot(i.toDouble(), views[i]),
    ];
    final lastX = (series.length - 1).toDouble();

    // Une barre lissée avec point terminal. `area` = aire dégradée sous la courbe.
    // `dash` = trait pointillé (Visites) : reste lisible même superposée aux
    // Visiteurs (à l'heure, visites == visiteurs → courbes confondues).
    LineChartBarData lineBar(
      List<FlSpot> spots,
      Color color,
      double width, {
      bool area = false,
      List<int>? dash,
    }) =>
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.32,
          preventCurveOverShooting: true,
          color: color,
          barWidth: width,
          dashArray: dash,
          isStrokeCapRound: true,
          isStrokeJoinRound: true,
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, bar) => spot.x == lastX,
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

    // Courbes visibles dans l'ordre de tracé (pages vues dessous → visiteurs
    // avec aire → visites dessus). Clé/libellé et barre construits ensemble :
    // le tooltip mappe barIndex → libellé sans risque de désync.
    final drawn = <({String label, LineChartBarData bar})>[
      if (showViews)
        (label: 'pages vues', bar: lineBar(viewSpots, altColor, 1.8)),
      if (showVisitors)
        (label: 'visiteurs', bar: lineBar(visitorSpots, p.accent, 2.6, area: true)),
      if (showVisits)
        (label: 'visites', bar: lineBar(visitSpots, p.amber, 2.4, dash: const [6, 5])),
    ];

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
                // Libellés dans l'ordre de tracé → mappe barIndex → libellé.
                final visibleKeys = [for (final d in drawn) d.label];
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              // Visiteurs uniques (vert) — toujours une courbe, basculable.
              if (visitorsTotal != null)
                _LegendItem(
                  color: p.accent,
                  label: 'Visiteurs',
                  value: visitorsTotal,
                  on: showVisitors,
                  onTap: onToggle == null ? null : () => onToggle!(kVisitors),
                ),
              // Visites (orange). Courbe basculable en détail (série dispo) ;
              // sinon simple référence chiffrée (point creux) — Umami ne fournit
              // pas les visites en série sur l'accueil.
              _LegendItem(
                color: p.amber,
                hollow: !hasVisitsSeries,
                label: 'Visites',
                value: visitsTotal,
                on: hasVisitsSeries ? showVisits : true,
                onTap: (hasVisitsSeries && onToggle != null)
                    ? () => onToggle!(kVisits)
                    : null,
              ),
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
    this.hollow = false,
  });
  final Color color;
  final String label;
  final bool on;
  final VoidCallback? onTap;
  final int? value;

  /// Dot en anneau (non plein) : marque un total de référence sans courbe.
  final bool hollow;

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
                color: hollow ? Colors.transparent : color,
                shape: BoxShape.circle,
                border: hollow ? Border.all(color: color, width: 1.5) : null,
              ),
            ),
            const SizedBox(width: 6),
            if (value != null) ...[
              Text(fmtInt(value!), style: GT.mono(12, weight: 600, color: color)),
              const SizedBox(width: 4),
            ],
            Text(label, style: GT.body(12, color: p.fg2)),
          ],
        ),
      ),
    );
  }
}
