import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../../data/models/period.dart';
import '../widgets/events_chart.dart';
import 'card_stat.dart';

/// Courbes par valeur (si demandées) au-dessus des barres : corps d'une carte
/// « Répartition », et d'un compteur découpé par part. L'état des courbes
/// masquées reste local à la carte.
///
/// Dans une carte de la grille (hauteur imposée), la légende et les barres
/// gardent leur hauteur et la courbe prend ce qui reste : on voit les barres
/// sans avoir à agrandir la carte. Hors grille (aperçu de l'éditeur), la courbe
/// a sa hauteur fixe.
class BreakdownBody extends StatefulWidget {
  const BreakdownBody({
    super.key,
    required this.series,
    required this.unit,
    required this.bars,
  });

  /// Une série par valeur, dans l'ordre des barres. Null : barres seules.
  final List<EventSeries>? series;
  final TimeUnit unit;
  final Widget bars;

  @override
  State<BreakdownBody> createState() => _BreakdownBodyState();
}

class _BreakdownBodyState extends State<BreakdownBody> {
  final Set<String> _hidden = {};

  static const double _chartHeight = 180;

  /// Moins de deux points non nuls : une courbe n'aurait rien à raconter.
  bool get _worthDrawing =>
      (widget.series ?? const <EventSeries>[])
          .expand((s) => s.points)
          .where((p) => p.visitors > 0)
          .length >=
      2;

  @override
  Widget build(BuildContext context) {
    final series = widget.series;
    if (series == null || !_worthDrawing) {
      return LayoutBuilder(
        builder: (context, c) =>
            c.hasBoundedHeight ? CardLoose(child: widget.bars) : widget.bars,
      );
    }

    // Couleur stable : le rang de la valeur, pas sa position parmi les visibles.
    final colors = {
      for (final (i, s) in series.indexed) s.name: eventColorAt(i),
    };
    final visible = series.where((s) => !_hidden.contains(s.name)).toList();
    final legend = Wrap(
      spacing: 14,
      runSpacing: 2,
      children: [
        for (final s in series)
          EventChip(
            label: s.name,
            color: colors[s.name]!,
            on: !_hidden.contains(s.name),
            onTap: () => setState(() {
              if (!_hidden.remove(s.name)) _hidden.add(s.name);
            }),
          ),
      ],
    );
    final chart = EventsChart(
      series: visible,
      colors: colors,
      unit: widget.unit,
      height: _chartHeight,
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.hasBoundedHeight) {
          return CustomMultiChildLayout(
            delegate: _FillLayout(),
            children: [
              LayoutId(id: _Part.legend, child: legend),
              LayoutId(id: _Part.chart, child: chart),
              LayoutId(id: _Part.bars, child: widget.bars),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            legend,
            const SizedBox(height: _FillLayout.legendGap),
            chart,
            const SizedBox(height: _FillLayout.barsGap),
            widget.bars,
          ],
        );
      },
    );
  }
}

enum _Part { legend, chart, bars }

/// Légende et barres à leur hauteur, la courbe entre les deux sur la hauteur
/// restante, jamais sous [minChart] : en deçà, ce sont les barres qui sont
/// coupées par la carte.
class _FillLayout extends MultiChildLayoutDelegate {
  static const double legendGap = 8;
  static const double barsGap = 6;
  static const double minChart = 80;

  @override
  void performLayout(Size size) {
    final width = BoxConstraints.tightFor(width: size.width);
    final legend = layoutChild(_Part.legend, width);
    final bars = layoutChild(_Part.bars, width);
    final top = legend.height + legendGap;
    final chart = math.max(minChart, size.height - top - barsGap - bars.height);
    layoutChild(
      _Part.chart,
      BoxConstraints.tightFor(width: size.width, height: chart),
    );
    positionChild(_Part.legend, Offset.zero);
    positionChild(_Part.chart, Offset(0, top));
    positionChild(_Part.bars, Offset(0, top + chart + barsGap));
  }

  @override
  bool shouldRelayout(_FillLayout old) => false;
}
