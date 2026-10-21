import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../../data/models/period.dart';

/// Paliers d'une décade, en dixièmes de la puissance de 10 : 1 · 1,2 · 1,6 · 2 ·
/// 2,4 · 3,2 · 4 · 4,8 · 6 · 8. Plus fin que {1, 2, 4, 5, 8}, dont le saut 2 → 4
/// laissait la courbe à moitié de la hauteur (pic de 185 sur un axe à 400).
const _kNiceSteps = [10, 12, 16, 20, 24, 32, 40, 48, 60, 80];

/// Arrondit un maximum vers une valeur « ronde » avec 15 % de marge, pour une
/// échelle Y lisible. Partagé par les graphiques.
///
/// À partir de 1, le résultat est un entier multiple de 4 : l'axe a quatre
/// intervalles et des comptes sont entiers, donc deux libellés arrondis ne
/// peuvent pas se confondre (avec 2,5 l'intervalle vaut 0,625 × 10^k et l'on
/// lisait « 3 » deux fois). Sous 10 cela ne laisse que 4, 8 et 12 ; dès 10 les
/// paliers se suivent d'au plus 33 %, donc au plus ~34 % de vide au-dessus de
/// la marge.
double chartNiceMax(double m) {
  // Série toute à zéro : 8 et non 10, dont le quart (2,5) s'arrondirait en
  // « 3 % » et « 8 % » sur les graduations.
  if (m <= 0) return 8;
  final v = m * 1.15;
  final integral = m >= 1;
  final decade = (math.log(v) / math.ln10).floor();
  for (final exp in [decade, decade + 1]) {
    final unit = math.pow(10, exp).toDouble();
    for (final step in _kNiceSteps) {
      final c = step * unit / 10;
      if (c < v) continue;
      if (integral && c % 4 != 0) continue;
      return c;
    }
  }
  return math.pow(10, decade + 2).toDouble();
}

/// Date d'entête de tooltip selon la granularité.
String chartTooltipDate(DateTime t, TimeUnit unit) => switch (unit) {
  TimeUnit.hour => DateFormat("d MMM · HH'h'", 'fr_FR').format(t),
  TimeUnit.day => DateFormat('EEE d MMM', 'fr_FR').format(t),
  TimeUnit.month => DateFormat('MMMM yyyy', 'fr_FR').format(t),
};
