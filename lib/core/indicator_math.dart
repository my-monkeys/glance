import '../data/models/indicator_result.dart';
import '../data/models/models.dart';

/// Une carte sans valeur à montrer (rien mesuré, compteur à 0 partout,
/// répartition vide) : l'onglet Tableaux la masque.
bool hasDisplayableData(IndicatorData d) => switch (d) {
      CounterData() => d.total != 0 || d.points.any((s) => s.visitors != 0),
      RatioData() => d.denominatorTotal > 0,
      FunnelData() => d.steps.isNotEmpty && d.steps.first.visitors > 0,
      BreakdownData() => d.rows.isNotEmpty,
    };

/// Rapport [num] / [den], bucket par bucket. Les deux séries viennent de la
/// même fenêtre : on les aligne par index. Un bucket au dénominateur nul vaut
/// 0 %, ou null (un trou) avec [gapsWhenEmpty]. Le taux global n'en dépend pas.
RatioData ratioOf(List<SeriesPoint> num, List<SeriesPoint> den,
    {bool gapsWhenEmpty = false}) {
  assert(num.length == den.length, 'Séries issues de fenêtres différentes');
  var numTotal = 0.0;
  var denTotal = 0.0;
  final points = <RatioPoint>[];
  for (var i = 0; i < num.length; i++) {
    numTotal += num[i].visitors;
    denTotal += den[i].visitors;
    final d = den[i].visitors;
    final value = d == 0 ? (gapsWhenEmpty ? null : 0.0) : num[i].visitors / d;
    points.add(RatioPoint(num[i].t, value));
  }
  // Ratio des sommes, jamais moyenne des ratios par bucket : un jour à 3 parties
  // pèserait autant qu'un jour à 300 et fausserait le taux global.
  return RatioData(
    points: points,
    overall: denTotal == 0 ? null : numTotal / denTotal,
    numeratorTotal: numTotal.round(),
    denominatorTotal: denTotal.round(),
  );
}
