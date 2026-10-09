import 'dart:math' as math;

import '../data/models/models.dart';

/// Jours qui servent à mesurer le profil de la semaine (creux du week-end…).
const kProfileDays = 56;

/// Jours qui fixent le niveau actuel. Court exprès : c'est lui qui suit la
/// croissance d'un site, là où une fenêtre longue la lisse.
const kLevelDays = 7;

/// Jours d'historique à récupérer : neuf semaines, soit [kProfileDays] de
/// profil et toujours le mois précédent en entier (31 jours entamés + 31 jours
/// d'avant tiennent dans 63).
const kHistoryDays = 63;

/// Historique minimal pour qu'un profil hebdomadaire veuille dire quelque chose.
const kMinHistoryDays = 14;

/// Visiteurs attendus jour par jour après [complete] (jours complets, du plus
/// ancien au plus récent) : niveau des [kLevelDays] derniers jours, corrigé du
/// jour de la semaine, × profil de la semaine. Null sous [kMinHistoryDays].
///
/// Retenu sur banc d'essai (96 mois réels de 10 sites, coupés du 3 au 25) :
/// erreur médiane de 9,7 % sur le total du mois, contre 10,7 % pour
/// Holt-Winters amorti, 11,6 % pour le rythme du seul mois en cours et 16 %
/// pour le profil du mois précédent. La tendance de Holt-Winters n'apportait
/// rien : un niveau mesuré sur sept jours suit déjà la croissance.
List<double>? projectDays(List<SeriesPoint> complete, int horizon) {
  if (complete.length < kMinHistoryDays) return null;
  final factors = _weekdayFactors(
    complete.sublist(complete.length - math.min(kProfileDays, complete.length)),
  );
  if (factors == null) return List.filled(horizon, 0);

  final recent = complete.sublist(complete.length - kLevelDays);
  var level = 0.0;
  for (final p in recent) {
    level += p.visitors / math.max(factors[p.t.weekday]!, 0.05);
  }
  level /= recent.length;

  final last = complete.last.t;
  return [
    for (var k = 1; k <= horizon; k++)
      level * factors[DateTime(last.year, last.month, last.day + k).weekday]!,
  ];
}

/// Poids de chaque jour de la semaine par rapport à la moyenne (1 = moyen).
/// Null si la période ne compte aucun visiteur.
Map<int, double>? _weekdayFactors(List<SeriesPoint> days) {
  var total = 0.0;
  final sum = <int, double>{};
  final count = <int, int>{};
  for (final p in days) {
    total += p.visitors;
    sum[p.t.weekday] = (sum[p.t.weekday] ?? 0) + p.visitors;
    count[p.t.weekday] = (count[p.t.weekday] ?? 0) + 1;
  }
  if (total <= 0) return null;
  final mean = total / days.length;
  return {
    for (var wd = DateTime.monday; wd <= DateTime.sunday; wd++)
      wd: count[wd] == null ? 1 : sum[wd]! / count[wd]! / mean,
  };
}
