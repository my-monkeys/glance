import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../state/period_state.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';

/// Ligne « ‹ label › » partagée par [DayNav]/[MonthNav]/[YearNav]. La flèche
/// droite se désactive quand [canGoForward] est faux (pas de futur).
class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.label,
    required this.canGoForward,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final bool canGoForward;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Row(
      children: [
        _arrow(context, icon: Icons.chevron_left_rounded, onTap: onPrev),
        Expanded(
          child: Center(
            child: Text(label, style: GT.body(14, weight: 500, color: p.fg)),
          ),
        ),
        _arrow(
          context,
          icon: Icons.chevron_right_rounded,
          enabled: canGoForward,
          onTap: onNext,
        ),
      ],
    );
  }

  static Widget _arrow(
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
}

/// Navigation jour par jour (visible quand « Aujourd'hui » est sélectionné) :
/// ‹ Hier / Aujourd'hui / date ›. La flèche droite est désactivée sur le jour
/// courant (pas de futur).
class DayNav extends ConsumerWidget {
  const DayNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offset = ref.watch(periodProvider.select((s) => s.dayOffset));
    return _NavRow(
      label: _label(offset),
      canGoForward: offset < 0,
      onPrev: () => ref.read(periodProvider.notifier).shiftDay(-1),
      onNext: () => ref.read(periodProvider.notifier).shiftDay(1),
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

/// Navigation mois par mois (visible quand « Ce mois-ci » est sélectionné) :
/// ‹ Mois dernier / Ce mois-ci / août 2026 ›. La flèche droite est désactivée
/// sur le mois courant (pas de futur).
class MonthNav extends ConsumerWidget {
  const MonthNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offset = ref.watch(periodProvider.select((s) => s.monthOffset));
    return _NavRow(
      label: _label(offset),
      canGoForward: offset < 0,
      onPrev: () => ref.read(periodProvider.notifier).shiftMonth(-1),
      onNext: () => ref.read(periodProvider.notifier).shiftMonth(1),
    );
  }

  static String _label(int offset) {
    switch (offset) {
      case 0:
        return 'Ce mois-ci';
      case -1:
        return 'Mois dernier';
      default:
        final now = DateTime.now();
        final month = DateTime(now.year, now.month + offset, 1);
        return DateFormat('MMMM yyyy', 'fr_FR').format(month);
    }
  }
}

/// Navigation année par année (visible quand « Cette année » est
/// sélectionnée) : ‹ Année dernière / Cette année / 2024 ›. La flèche droite
/// est désactivée sur l'année courante (pas de futur).
class YearNav extends ConsumerWidget {
  const YearNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offset = ref.watch(periodProvider.select((s) => s.yearOffset));
    return _NavRow(
      label: _label(offset),
      canGoForward: offset < 0,
      onPrev: () => ref.read(periodProvider.notifier).shiftYear(-1),
      onNext: () => ref.read(periodProvider.notifier).shiftYear(1),
    );
  }

  static String _label(int offset) {
    switch (offset) {
      case 0:
        return 'Cette année';
      case -1:
        return 'Année dernière';
      default:
        return '${DateTime.now().year + offset}';
    }
  }
}
