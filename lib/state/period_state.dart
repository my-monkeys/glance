import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/period.dart';
import 'settings.dart';

/// Période sélectionnée, partagée par tous les écrans (accueil, détail…) pour
/// qu'ils restent synchronisés.
@immutable
class PeriodState {
  const PeriodState({
    this.period = Period.d7,
    this.customStart,
    this.customEnd,
    this.dayOffset = 0,
    this.monthOffset = 0,
    this.yearOffset = 0,
    this.compare = false,
  });

  final Period period;
  final DateTime? customStart;
  final DateTime? customEnd;

  /// Superpose sur le graphique la courbe de la période précédente
  /// équivalente (cf. `previousPeriodWindow` dans core/predict.dart) —
  /// préférence de vue, conservée telle quelle d'un changement de période à
  /// l'autre (contrairement aux décalages, propres chacun à une période).
  final bool compare;

  /// Décalage en jours, uniquement pour [Period.today] (0 = aujourd'hui,
  /// -1 = hier, …). Permet de naviguer jour par jour.
  final int dayOffset;

  /// Décalage en mois, uniquement pour [Period.thisMonth] (0 = ce mois-ci,
  /// -1 = le mois dernier, …). Permet de naviguer mois par mois.
  final int monthOffset;

  /// Décalage en années, uniquement pour [Period.thisYear] (0 = cette année,
  /// -1 = l'année dernière, …). Permet de naviguer année par année.
  final int yearOffset;

  /// Fenêtre résolue. Alignée sur la grille temporelle (cf. [Period.window]),
  /// donc stable entre deux builds d'une même heure/journée → pas de reload.
  DateWindow window() => period.window(
        customStart: customStart,
        customEnd: customEnd,
        dayOffset: dayOffset,
        monthOffset: monthOffset,
        yearOffset: yearOffset,
      );

  /// La navigation par jour/mois/année n'a de sens que pour la période
  /// calendaire correspondante.
  bool get canNavigateDays => period == Period.today;
  bool get canNavigateMonths => period == Period.thisMonth;
  bool get canNavigateYears => period == Period.thisYear;
}

class PeriodNotifier extends Notifier<PeriodState> {
  @override
  PeriodState build() {
    // Période affichée au lancement = réglage « période par défaut ».
    final def = ref.read(settingsProvider).defaultPeriod;
    return PeriodState(period: def);
  }

  void set(Period p) => state = PeriodState(period: p, compare: state.compare);

  void setCustom(DateTime start, DateTime end) => state = PeriodState(
        period: Period.custom,
        customStart: start,
        customEnd: end,
        compare: state.compare,
      );

  /// Décale d'un jour (borné : on ne va pas dans le futur).
  void shiftDay(int delta) {
    if (state.period != Period.today) return;
    final next = (state.dayOffset + delta).clamp(-3650, 0);
    state = PeriodState(period: Period.today, dayOffset: next, compare: state.compare);
  }

  /// Décale d'un mois (borné : on ne va pas dans le futur).
  void shiftMonth(int delta) {
    if (state.period != Period.thisMonth) return;
    final next = (state.monthOffset + delta).clamp(-1200, 0);
    state = PeriodState(period: Period.thisMonth, monthOffset: next, compare: state.compare);
  }

  /// Décale d'une année (borné : on ne va pas dans le futur).
  void shiftYear(int delta) {
    if (state.period != Period.thisYear) return;
    final next = (state.yearOffset + delta).clamp(-100, 0);
    state = PeriodState(period: Period.thisYear, yearOffset: next, compare: state.compare);
  }

  /// Bascule la comparaison à la période précédente (superposée sur le
  /// graphique). Reste tel quel au changement de période.
  void toggleCompare() =>
      state = PeriodState(
        period: state.period,
        customStart: state.customStart,
        customEnd: state.customEnd,
        dayOffset: state.dayOffset,
        monthOffset: state.monthOffset,
        yearOffset: state.yearOffset,
        compare: !state.compare,
      );
}

final periodProvider =
    NotifierProvider<PeriodNotifier, PeriodState>(PeriodNotifier.new);
