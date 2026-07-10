import 'dart:math' as math;

import 'package:intl/intl.dart';

/// Arrondit un maximum vers une valeur « ronde » avec un peu de marge, pour une
/// échelle Y lisible. Partagé par les graphiques.
double chartNiceMax(double m) {
  if (m <= 0) return 10;
  final v = m * 1.15;
  final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
  final norm = v / mag;
  double nice;
  if (norm <= 1) {
    nice = 1;
  } else if (norm <= 2) {
    nice = 2;
  } else if (norm <= 2.5) {
    nice = 2.5;
  } else if (norm <= 5) {
    nice = 5;
  } else {
    nice = 10;
  }
  return nice * mag;
}

/// Date d'entête de tooltip selon la granularité.
String chartTooltipDate(DateTime t, String unit) {
  switch (unit) {
    case 'hour':
      return DateFormat("d MMM · HH'h'", 'fr_FR').format(t);
    case 'month':
      return DateFormat('MMMM yyyy', 'fr_FR').format(t);
    default:
      return DateFormat('EEE d MMM', 'fr_FR').format(t);
  }
}
