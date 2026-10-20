import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/predict.dart';
import '../../data/models/models.dart';
import '../../data/models/period.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import 'chart_util.dart';

/// Ce qu'une courbe représente. Le rôle porte le sens ; la couleur et le
/// libellé en découlent.
enum ChartSeriesRole { visitors, pageviews, forecast, compare }

/// Une série prête à peindre, indépendamment du moteur de rendu (courbe ou
/// barres) : des valeurs indexées par bucket, à partir d'un décalage.
@immutable
class ChartSeries {
  const ChartSeries({
    required this.role,
    required this.label,
    required this.color,
    required this.values,
    this.offset = 0,
  });

  final ChartSeriesRole role;
  final String label;
  final Color color;
  final List<double> values;

  /// Position du premier point sur l'axe X (la prévision démarre au dernier
  /// bucket observé pour se raccorder à la courbe).
  final int offset;

  double? at(int x) {
    final i = x - offset;
    return i >= 0 && i < values.length ? values[i] : null;
  }
}

/// Tout ce qu'un graphique a besoin de savoir, calculé une seule fois : quelles
/// séries sont visibles, l'échelle, l'axe des temps.
///
/// Extrait du widget pour que la courbe et les barres partagent exactement les
/// mêmes décisions — sans quoi basculer de l'un à l'autre changerait
/// discrètement l'échelle ou les libellés d'axe.
@immutable
class ChartModel {
  const ChartModel._({
    required this.drawn,
    required this.series,
    required this.unit,
    required this.maxY,
    required this.rightMaxY,
    required this.yInterval,
    required this.xCount,
    required this.labelStep,
    required this.lastObsX,
    required this.fcStart,
    required this.hasForecast,
  });

  factory ChartModel.from({
    required List<SeriesPoint> series,
    required TimeUnit unit,
    required bool showPageviews,
    required Set<String> hidden,
    required GlancePalette palette,
    Forecast? forecast,
    List<SeriesPoint>? compareSeries,
  }) {
    final showVisitors = !hidden.contains(kVisitorsKey);
    final showViews = showPageviews && !hidden.contains(kPageviewsKey);

    // La prévision démarre sur un bucket observé pour se raccorder sans saut.
    final fcPoints = forecast?.points ?? const <SeriesPoint>[];
    var fcStart = -1;
    if (fcPoints.isNotEmpty) {
      final t0 = fcPoints.first.t;
      fcStart = series.indexWhere((e) => e.t == t0);
    }
    final hasFc = fcStart >= 0;
    final showFc = hasFc && !hidden.contains(kForecastKey);

    // La comparaison se superpose par position de bucket, pas par date : ses
    // dates réelles sont celles de la période d'avant.
    final cmp = compareSeries ?? const <SeriesPoint>[];
    final showCompare = cmp.isNotEmpty;

    final visitors = [for (final e in series) e.visitors];
    final views = [for (final e in series) e.pageviews];

    // L'échelle ne tient compte que du visible : masquer une courbe rescale.
    // Quand les deux courbes sont là, les pages vues (souvent plusieurs fois les
    // visiteurs) ont leur propre échelle, à droite : sur un axe commun elles
    // écrasent la courbe verte.
    final dual = showVisitors && showViews;
    final rawMax = [
      if (showVisitors) ...visitors,
      if (showViews && !dual) ...views,
      if (showFc) ...fcPoints.map((e) => e.visitors),
      if (showCompare) ...cmp.map((e) => e.visitors),
    ].fold<double>(0, math.max);
    final maxY = chartNiceMax(rawMax);
    final rightMaxY = dual ? chartNiceMax(views.fold<double>(0, math.max)) : null;

    final xCount = [
      series.length,
      if (showFc) fcStart + fcPoints.length,
      if (showCompare) cmp.length,
    ].reduce(math.max);

    // Ordre de tracé : la comparaison dessous, les visiteurs dessus.
    final drawn = <ChartSeries>[
      if (showCompare)
        ChartSeries(
          role: ChartSeriesRole.compare,
          label: 'période précédente',
          color: palette.fg3,
          values: [for (final e in cmp) e.visitors],
        ),
      if (showFc)
        ChartSeries(
          role: ChartSeriesRole.forecast,
          label: 'prévision',
          color: palette.forecast,
          values: [for (final e in fcPoints) e.visitors],
          offset: fcStart,
        ),
      if (showViews)
        ChartSeries(
          role: ChartSeriesRole.pageviews,
          label: 'pages vues',
          color: palette.fg2,
          values: views,
        ),
      if (showVisitors)
        ChartSeries(
          role: ChartSeriesRole.visitors,
          label: 'visiteurs',
          color: palette.accent,
          values: visitors,
        ),
    ];

    return ChartModel._(
      drawn: drawn,
      series: series,
      unit: unit,
      maxY: maxY,
      rightMaxY: rightMaxY,
      yInterval: maxY / 4,
      xCount: xCount,
      labelStep: math.max(1, (xCount / 6).ceil()),
      lastObsX: (series.length - 1).toDouble(),
      fcStart: fcStart,
      hasForecast: hasFc,
    );
  }

  static const kVisitorsKey = 'visitors';
  static const kPageviewsKey = 'pageviews';
  static const kForecastKey = 'forecast';

  final List<ChartSeries> drawn;
  final List<SeriesPoint> series;
  final TimeUnit unit;
  /// Échelle de l'axe de gauche (visiteurs, ou la seule série visible).
  final double maxY;

  /// Échelle des pages vues quand elles ont leur axe à droite, sinon `null`.
  final double? rightMaxY;
  final double yInterval;
  final int xCount;
  final int labelStep;

  /// Dernier bucket réellement observé (au-delà, c'est de la projection).
  final double lastObsX;
  final int fcStart;
  final bool hasForecast;

  bool get hasRightAxis => rightMaxY != null;

  /// fl_chart n'a qu'un axe Y par graphique : les pages vues sont ramenées dans
  /// l'espace de gauche (v × maxY / rightMaxY) pour être tracées, et seuls les
  /// libellés de l'axe de droite et [fromPlot] rendent la vraie valeur. Les
  /// tooltips lisent toujours les valeurs réelles de la série.
  double toPlot(ChartSeries s, double v) =>
      s.role == ChartSeriesRole.pageviews && rightMaxY != null
          ? v * maxY / rightMaxY!
          : v;

  double fromPlot(ChartSeries s, double v) =>
      s.role == ChartSeriesRole.pageviews && rightMaxY != null
          ? v * rightMaxY! / maxY
          : v;

  double get lastX => (xCount - 1).toDouble();

  /// Le premier point de la prévision recopie un bucket déjà observé, pour que
  /// la courbe se raccorde sans saut. En barres il n'a rien à raccorder : il
  /// dessinerait une barre en double sur une valeur déjà présente.
  bool isForecastBridge(int x) =>
      hasForecast && x == fcStart && fcStart < series.length - 1;

  bool get isEmpty => series.isEmpty || drawn.isEmpty;

  /// Date d'un index d'axe. Au-delà des buckets observés ou projetés (seule la
  /// comparaison s'y étend), le calendrier se prolonge par pas d'unité : ces
  /// dates existent, seule la donnée manque.
  DateTime timeAt(int i) {
    if (i < series.length) return series[i].t;
    final base = series.first.t;
    return switch (unit) {
      TimeUnit.hour => DateTime(base.year, base.month, base.day, base.hour + i),
      TimeUnit.day => DateTime(base.year, base.month, base.day + i),
      TimeUnit.month => DateTime(base.year, base.month + i, 1),
    };
  }
}

/// Axes communs aux deux moteurs : l'échelle Y arrondie à gauche (et celle des
/// pages vues à droite quand elles ont la leur), ~6 repères de temps en bas, ceux de la partie projetée dans la couleur de la prévision.
FlTitlesData buildChartTitles(ChartModel m, GlancePalette p) => FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      // Les couleurs des deux axes ne servent qu'à les distinguer, et seulement
      // quand il y en a deux.
      rightTitles: m.hasRightAxis
          ? AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: kChartAxisWidth,
                interval: m.yInterval,
                getTitlesWidget: (value, meta) {
                  if (value < m.yInterval / 2) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                      fmtCount(value * m.rightMaxY! / m.maxY),
                      style: GT.mono(9.5, color: p.fg2),
                    ),
                  );
                },
              ),
            )
          : const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: kChartAxisWidth,
          interval: m.yInterval,
          getTitlesWidget: (value, meta) {
            if (value < m.yInterval / 2 && value != 0) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                fmtCount(value),
                style: GT.mono(9.5, color: m.hasRightAxis ? p.accent : p.fg3),
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
            if (i < 0 || i >= m.xCount) return const SizedBox.shrink();
            final isLast = i == m.xCount - 1;
            if (i % m.labelStep != 0 && !isLast) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                fmtAxis(m.timeAt(i), m.unit),
                style: GT.mono(
                  9.5,
                  color: i > m.lastObsX ? p.forecast : p.fg3,
                ),
              ),
            );
          },
        ),
      ),
    );

/// Largeur réservée aux libellés d'un axe des valeurs (gauche ou droite).
const double kChartAxisWidth = 36;

FlGridData buildChartGrid(ChartModel m, GlancePalette p) => FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: m.yInterval,
      getDrawingHorizontalLine: (v) => FlLine(color: p.line, strokeWidth: 1),
    );
