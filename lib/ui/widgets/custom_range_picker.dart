import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/period_state.dart';
import '../../theme/palette.dart';
import 'adaptive_sheet.dart';

/// Taille du pop-up de dates : celle d'un calendrier, pas d'un écran.
const Size kRangePickerSize = Size(400, 600);

/// Marge laissée autour du pop-up quand la fenêtre est plus petite que lui.
const double kRangePickerMargin = 16;

/// Choix de la période « Perso » : `showDateRangePicker` s'ouvre en plein écran
/// par défaut, on le ramène à un pop-up sur toutes les plateformes. Applique la
/// plage choisie (jusqu'à 23:59 du dernier jour) à la période partagée.
Future<void> pickCustomPeriod(BuildContext context, WidgetRef ref) async {
  final now = DateTime.now();
  final range = await showDateRangePicker(
    context: context,
    firstDate: DateTime(now.year - 3),
    lastDate: now,
    initialDateRange: DateTimeRange(
      start: now.subtract(const Duration(days: 29)),
      end: now,
    ),
    builder: (ctx, child) => _RangePickerFrame(child: child!),
  );
  if (range != null) {
    ref.read(periodProvider.notifier).setCustom(
          range.start,
          range.end.add(const Duration(hours: 23, minutes: 59)),
        );
  }
}

/// Le sélecteur de Flutter prend la taille de `MediaQuery` en mode calendrier :
/// on lui fait croire que la fenêtre est celle du pop-up, et on l'habille de la
/// palette Glance.
class _RangePickerFrame extends StatelessWidget {
  const _RangePickerFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final size = Size(
      (mq.size.width - 2 * kRangePickerMargin).clamp(0, kRangePickerSize.width),
      (mq.size.height - 2 * kRangePickerMargin).clamp(0, kRangePickerSize.height),
    );
    final scheme = theme.colorScheme.copyWith(
      primary: p.accent,
      onPrimary: p.accentInk,
      surface: p.surface,
      onSurface: p.fg,
      onSurfaceVariant: p.fg2,
      outline: p.line,
      outlineVariant: p.line,
    );
    return Theme(
      data: theme.copyWith(
        colorScheme: scheme,
        datePickerTheme: DatePickerThemeData(
          backgroundColor: p.surface,
          surfaceTintColor: Colors.transparent,
          rangePickerBackgroundColor: p.surface,
          rangePickerSurfaceTintColor: Colors.transparent,
          rangeSelectionBackgroundColor: p.accentSoft,
          rangePickerShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kSheetRadius),
          ),
          headerBackgroundColor: p.surface,
          headerForegroundColor: p.fg,
        ),
      ),
      child: MediaQuery(data: mq.copyWith(size: size), child: child),
    );
  }
}
