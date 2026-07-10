import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../state/period_state.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';

/// Navigation jour par jour (visible quand « Aujourd'hui » est sélectionné) :
/// ‹ Hier / Aujourd'hui / date ›. La flèche droite est désactivée sur le jour
/// courant (pas de futur).
class DayNav extends ConsumerWidget {
  const DayNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final offset = ref.watch(periodProvider.select((s) => s.dayOffset));
    final atToday = offset >= 0;

    return Row(
      children: [
        _arrow(
          context,
          icon: Icons.chevron_left_rounded,
          onTap: () => ref.read(periodProvider.notifier).shiftDay(-1),
        ),
        Expanded(
          child: Center(
            child: Text(
              _label(offset),
              style: GT.body(14, weight: 500, color: p.fg),
            ),
          ),
        ),
        _arrow(
          context,
          icon: Icons.chevron_right_rounded,
          enabled: !atToday,
          onTap: () => ref.read(periodProvider.notifier).shiftDay(1),
        ),
      ],
    );
  }

  Widget _arrow(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final p = context.glance;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.chip,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: enabled ? p.fg : p.fg3),
      ),
    );
  }

  static String _label(int offset) {
    switch (offset) {
      case 0:
        return "Aujourd'hui";
      case -1:
        return 'Hier';
      case -2:
        return 'Avant-hier';
      default:
        final day = DateTime.now().add(Duration(days: offset));
        return DateFormat('EEEE d MMMM', 'fr_FR').format(day);
    }
  }
}
