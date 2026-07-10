import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/period.dart';

/// Période sélectionnée, partagée par tous les écrans (accueil, détail…) pour
/// qu'ils restent synchronisés.
@immutable
class PeriodState {
  const PeriodState({this.period = Period.d7, this.customStart, this.customEnd});

  final Period period;
  final DateTime? customStart;
  final DateTime? customEnd;

  /// Fenêtre résolue. Alignée sur la grille temporelle (cf. [Period.window]),
  /// donc stable entre deux builds d'une même heure/journée → pas de reload.
  DateWindow window() =>
      period.window(customStart: customStart, customEnd: customEnd);

  PeriodState copyWith({
    Period? period,
    DateTime? customStart,
    DateTime? customEnd,
  }) =>
      PeriodState(
        period: period ?? this.period,
        customStart: customStart ?? this.customStart,
        customEnd: customEnd ?? this.customEnd,
      );
}

class PeriodNotifier extends Notifier<PeriodState> {
  @override
  PeriodState build() => const PeriodState();

  void set(Period p) => state = PeriodState(period: p);

  void setCustom(DateTime start, DateTime end) => state = PeriodState(
        period: Period.custom,
        customStart: start,
        customEnd: end,
      );
}

final periodProvider =
    NotifierProvider<PeriodNotifier, PeriodState>(PeriodNotifier.new);
