import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../../data/models/period.dart';

/// Arrondit un maximum vers une valeur « ronde » avec un peu de marge, pour une
/// échelle Y lisible. Partagé par les graphiques.
double chartNiceMax(double m) {
  if (m <= 0) return 10;
  final v = m * 1.15;
  final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
  final norm = v / mag;
  // Uniquement des multiples que quatre graduations divisent proprement : avec
  // 2,5 l'intervalle vaut 0,625 × 10^k et deux libellés arrondis finissent
  // identiques (« 3 » et « 3 »).
  double nice;
  if (norm <= 1) {
    nice = 1;
  } else if (norm <= 2) {
    nice = 2;
  } else if (norm <= 4) {
    nice = 4;
  } else if (norm <= 5) {
    nice = 5;
  } else if (norm <= 8) {
    nice = 8;
  } else {
    nice = 10;
  }
  return nice * mag;
}

/// Date d'entête de tooltip selon la granularité.
String chartTooltipDate(DateTime t, TimeUnit unit) => switch (unit) {
  TimeUnit.hour => DateFormat("d MMM · HH'h'", 'fr_FR').format(t),
  TimeUnit.day => DateFormat('EEE d MMM', 'fr_FR').format(t),
  TimeUnit.month => DateFormat('MMMM yyyy', 'fr_FR').format(t),
};
