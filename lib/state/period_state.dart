import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/period.dart';

/// Période sélectionnée, partagée par tous les écrans (accueil, détail…) pour
/// qu'ils restent synchronisés.
@immutable
class PeriodState {
  const PeriodState({
    this.period = Period.d7,
    this.customStart,
    this.customEnd,
    this.dayOffset = 0,
  });

  final Period period;
  final DateTime? customStart;
  final DateTime? customEnd;

  /// Décalage en jours, uniquement pour [Period.today] (0 = aujourd'hui,
  /// -1 = hier, …). Permet de naviguer jour par jour.
  final int dayOffset;

  /// Fenêtre résolue. Alignée sur la grille temporelle (cf. [Period.window]),
  /// donc stable entre deux builds d'une même heure/journée → pas de reload.
  DateWindow window() => period.window(
        customStart: customStart,
        customEnd: customEnd,
        dayOffset: dayOffset,
      );

  /// La navigation par jour n'a de sens que pour « Aujourd'hui ».
  bool get canNavigateDays => period == Period.today;
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

  /// Décale d'un jour (borné : on ne va pas dans le futur).
  void shiftDay(int delta) {
    if (state.period != Period.today) return;
    final next = (state.dayOffset + delta).clamp(-3650, 0);
    state = PeriodState(period: Period.today, dayOffset: next);
  }
}

final periodProvider =
    NotifierProvider<PeriodNotifier, PeriodState>(PeriodNotifier.new);
