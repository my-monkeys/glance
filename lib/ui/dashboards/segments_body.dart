import 'package:flutter/material.dart';

import '../../data/models/indicator_result.dart';
import '../../data/models/models.dart';
import '../../data/models/period.dart';
import '../widgets/common.dart';
import '../widgets/events_chart.dart';
import 'breakdown_body.dart';

/// Vrai dès qu'une part a une valeur. Avant que la source ne sache découper,
/// toutes les parts sont inconnues : la carte reste un compteur simple.
bool hasSegmentData(CounterData d) => d.segments.any(
      (s) => (s.periodTotal ?? 0) > 0 || s.values.any((v) => (v ?? 0) > 0),
    );

/// Corps d'un compteur découpé par part (plateformes) : la courbe du total et
/// une par part, puis la part de chacune sur la période.
class SegmentsBody extends StatelessWidget {
  const SegmentsBody({
    super.key,
    required this.data,
    required this.totals,
    required this.unit,
  });

  final CounterData data;

  /// Le total par point, null là où il n'est pas encore publié.
  final List<double?> totals;
  final TimeUnit unit;

  static const _totalLabel = 'Total';

  static String _label(CounterSegment s) =>
      s.estimated ? '${s.label} · estimé' : s.label;

  static EventSeries _series(
    String name,
    List<DateTime> times,
    List<double?> values,
    int total,
  ) =>
      EventSeries(
        name: name,
        points: [
          for (final (i, t) in times.indexed) SeriesPoint(t, values[i] ?? 0, 0),
        ],
        total: total,
        gaps: {for (final (i, v) in values.indexed) if (v == null) i},
      );

  @override
  Widget build(BuildContext context) {
    final times = [for (final p in data.points) p.t];
    final segments = data.segments;
    // Les parts se lisent sur les totaux distincts de la période : leur somme
    // dépasse le total quand un joueur passe par deux plateformes.
    final sum = segments.fold<int>(0, (a, s) => a + (s.periodTotal ?? 0));
    return BreakdownBody(
      unit: unit,
      series: [
        _series(_totalLabel, times, totals, data.total),
        for (final s in segments)
          _series(_label(s), times, s.values, s.periodTotal ?? 0),
      ],
      bars: sum == 0
          ? const SizedBox.shrink()
          : MetricBars(
              dense: true,
              rows: [
                // Une part sans total (la source ne la comptait pas encore sur
                // la fenêtre) est inconnue : pas de barre à 0 %.
                for (final (i, s) in segments.indexed)
                  if (s.periodTotal != null)
                    MetricBarRow(
                      label: _label(s),
                      value: s.periodTotal!,
                      // Le total prend la 1re couleur des courbes.
                      color: eventColorAt(i + 1),
                    ),
              ],
              total: sum,
            ),
    );
  }
}
