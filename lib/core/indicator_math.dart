import '../data/models/indicator_result.dart';
import '../data/models/models.dart';

/// Rapport [num] / [den], bucket par bucket. Les deux séries viennent de la
/// même fenêtre : on les aligne par index.
RatioData ratioOf(List<SeriesPoint> num, List<SeriesPoint> den) {
  assert(num.length == den.length, 'Séries issues de fenêtres différentes');
  var numTotal = 0.0;
  var denTotal = 0.0;
  final points = <RatioPoint>[];
  for (var i = 0; i < num.length; i++) {
    numTotal += num[i].visitors;
    denTotal += den[i].visitors;
    final d = den[i].visitors;
    points.add(RatioPoint(num[i].t, d == 0 ? null : num[i].visitors / d));
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
