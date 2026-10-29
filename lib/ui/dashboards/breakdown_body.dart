import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../../data/models/period.dart';
import '../widgets/events_chart.dart';

/// Corps d'une carte « Répartition » : les courbes par valeur (si demandées)
/// au-dessus des barres. L'état des courbes masquées reste local à la carte.
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
    if (series == null || !_worthDrawing) return widget.bars;

    // Couleur stable : le rang de la valeur, pas sa position parmi les visibles.
    final colors = {
      for (final (i, s) in series.indexed) s.name: eventColorAt(i),
    };
    final visible = series.where((s) => !_hidden.contains(s.name)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
        ),
        const SizedBox(height: 14),
        EventsChart(series: visible, colors: colors, unit: widget.unit, height: 180),
        const SizedBox(height: 8),
        widget.bars,
      ],
    );
  }
}
