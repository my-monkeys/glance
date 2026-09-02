import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/predict.dart';
import '../../state/period_state.dart';
import '../../theme/palette.dart';

/// Bascule « comparer à la période précédente » : superpose sur le graphique
/// la courbe de la période équivalente d'avant (30 j précédents, mois
/// précédent, etc. — cf. `previousPeriodWindow`). Invisible quand la période
/// n'a pas d'équivalent « avant » pertinent (perso, tout).
class CompareToggle extends ConsumerWidget {
  const CompareToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final state = ref.watch(periodProvider);
    if (previousPeriodWindow(state.window()) == null) {
      return const SizedBox.shrink();
    }
    final on = state.compare;
    return GestureDetector(
      onTap: () => ref.read(periodProvider.notifier).toggleCompare(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? p.accent : p.chip,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          Icons.compare_arrows_rounded,
          size: 19,
          color: on ? p.accentInk : p.fg2,
        ),
      ),
    );
  }
}
