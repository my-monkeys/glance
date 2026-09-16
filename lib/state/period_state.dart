import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/period.dart';
import 'providers.dart';
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
    this.unit,
  });

  final Period period;
  final DateTime? customStart;
  final DateTime? customEnd;

  /// Superpose sur le graphique la courbe de la période précédente
  /// équivalente (cf. `previousPeriodWindow` dans core/predict.dart) —
  /// préférence de vue, conservée telle quelle d'un changement de période à
  /// l'autre (contrairement aux décalages, propres chacun à une période).
  final bool compare;

  /// Granularité forcée par le sélecteur des graphiques (null = celle qui va
  /// de soi pour la période). Elle vit ici, et non dans l'état d'un écran :
  /// la fenêtre sert de clé aux providers, et les minuteries de
  /// rafraîchissement la relisent au tick — une granularité locale à un écran
  /// ferait invalider une clé que plus personne n'écoute, et le graphe
  /// cesserait de se mettre à jour sans le dire.
  final TimeUnit? unit;

  /// Décalage en jours, uniquement pour [Period.today] (0 = aujourd'hui,
  /// -1 = hier, …). Permet de naviguer jour par jour.
  final int dayOffset;

  /// Décalage en mois, uniquement pour [Period.thisMonth] (0 = ce mois-ci,
  /// -1 = le mois dernier, …). Permet de naviguer mois par mois.
  final int monthOffset;

  /// Décalage en années, uniquement pour [Period.thisYear] (0 = cette année,
  /// -1 = l'année dernière, …). Permet de naviguer année par année.
  final int yearOffset;

  PeriodState copyWith({
    Period? period,
    DateTime? customStart,
    DateTime? customEnd,
    int? dayOffset,
    int? monthOffset,
    int? yearOffset,
    bool? compare,
    TimeUnit? unit,
    bool clearUnit = false,
  }) => PeriodState(
    period: period ?? this.period,
    customStart: customStart ?? this.customStart,
    customEnd: customEnd ?? this.customEnd,
    dayOffset: dayOffset ?? this.dayOffset,
    monthOffset: monthOffset ?? this.monthOffset,
    yearOffset: yearOffset ?? this.yearOffset,
    compare: compare ?? this.compare,
    unit: clearUnit ? null : (unit ?? this.unit),
  );

  /// Fenêtre résolue. Alignée sur la grille temporelle (cf. [Period.window]),
  /// donc stable entre deux builds d'une même heure/journée → pas de reload.
  ///
  /// Les écrans passent par `windowProvider`, qui y injecte la date de première
  /// donnée pour « Tout ». Appeler `resolve()` sans elle cadre large.
  DateWindow resolve({DateTime? allTimeStart}) => period.window(
        customStart: customStart,
        customEnd: customEnd,
        dayOffset: dayOffset,
        monthOffset: monthOffset,
        yearOffset: yearOffset,
        unit: unit,
        allTimeStart: allTimeStart,
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

  /// Force la granularité des graphiques (null = celle de la période).
  void setUnit(TimeUnit? u) =>
      state = state.copyWith(unit: u, clearUnit: u == null);

  /// Décale d'un jour (borné : on ne va pas dans le futur).
  void shiftDay(int delta) {
    if (state.period != Period.today) return;
    state = state.copyWith(dayOffset: (state.dayOffset + delta).clamp(-3650, 0));
  }

  /// Décale d'un mois (borné : on ne va pas dans le futur).
  void shiftMonth(int delta) {
    if (state.period != Period.thisMonth) return;
    state =
        state.copyWith(monthOffset: (state.monthOffset + delta).clamp(-1200, 0));
  }

  /// Décale d'une année (borné : on ne va pas dans le futur).
  void shiftYear(int delta) {
    if (state.period != Period.thisYear) return;
    state = state.copyWith(yearOffset: (state.yearOffset + delta).clamp(-100, 0));
  }

  /// Bascule la comparaison à la période précédente (superposée sur le
  /// graphique). Reste tel quel au changement de période.
  void toggleCompare() => state = state.copyWith(compare: !state.compare);
}

final periodProvider =
    NotifierProvider<PeriodNotifier, PeriodState>(PeriodNotifier.new);

/// **La** fenêtre que lisent tous les écrans et toutes les minuteries. Passer
/// par elle est ce qui garantit qu'ils interrogent tous la même clé de
/// provider ; un écran qui résoudrait la fenêtre lui-même ferait fetcher deux
/// fois et son rafraîchissement viserait une clé que personne n'écoute.
///
/// Null tant que « Tout » attend la date de première donnée : l'appelant montre
/// alors son squelette sans rien déclencher. Cadrer large en attendant ferait
/// partir une première vague de requêtes sur une fenêtre jetable, puis une
/// seconde sur la bonne.
final windowProvider = Provider<DateWindow?>((ref) {
  final state = ref.watch(periodProvider);
  if (state.period != Period.allTime) return state.resolve();
  final start = ref.watch(allTimeStartProvider);
  return start == null ? null : state.resolve(allTimeStart: start);
});
