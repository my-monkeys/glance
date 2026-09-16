import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/period.dart';
import '../../state/period_state.dart';
import '../../theme/motion.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';

/// Découpage du graphique — heure / jour / mois — posé en haut à droite des
/// grands graphiques.
///
/// N'offre que les granularités que la fenêtre autorise (cf. [allowedUnits]) :
/// rien sur une journée, où l'heure est le seul découpage possible. Le choix
/// est partagé par tous les écrans, comme la période.
class UnitPicker extends ConsumerWidget {
  const UnitPicker({super.key, required this.window});

  final DateWindow window;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final units = allowedUnits(window);
    if (units.length < 2) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: p.chip,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final u in units)
            GestureDetector(
              onTap: () => ref.read(periodProvider.notifier).setUnit(u),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: kMotionFast,
                curve: kCurveOut,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: u == window.unit ? p.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: u == window.unit ? p.shadow : null,
                ),
                child: Text(
                  u.label,
                  style: GT.mono(
                    10.5,
                    weight: u == window.unit ? 600 : 400,
                    color: u == window.unit ? p.fg : p.fg2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
