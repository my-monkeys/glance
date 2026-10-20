import '../data/models/indicator_result.dart';
import '../data/models/metrics_source.dart';
import '../data/models/models.dart';
import '../data/models/period.dart';
import '../data/providers/buckets.dart';

/// Sous ce dénominateur cumulé, le taux global n'est pas affiché : même seuil
/// de confidentialité que celui du serveur, qui renvoie alors `valeur: null`.
const kMinRatioDenominator = 5;

/// Granularité affichée d'une fenêtre : l'API n'a pas d'heures, donc une
/// fenêtre horaire se lit en jours (cf. `metricsRangeFor`).
TimeUnit externalUnitOf(TimeUnit u) => u == TimeUnit.hour ? TimeUnit.day : u;

/// La fenêtre telle que la source la voit : mêmes bornes, granularité
/// ramenée à [externalUnitOf], fin alignée sur le bucket suivant (une fenêtre
/// horaire s'arrête en cours de journée, et `bucketsOf` n'en verrait aucun).
DateWindow externalWindowOf(DateWindow w) {
  final unit = externalUnitOf(w.unit);
  final last = truncateBucket(w.end.subtract(const Duration(milliseconds: 1)), unit);
  return DateWindow(w.start, advanceBucket(last, unit), unit);
}

/// Points de l'API → résultat de carte, un point par bucket de la fenêtre.
/// Les buckets que l'API ne renvoie pas, ou renvoie hors fenêtre (le premier
/// peut commencer avant `de`), sont écartés ou comblés.
IndicatorData externalDataOf(
  MetricUnit unit,
  DateWindow window,
  List<MetricPoint> points,
) {
  final w = externalWindowOf(window);
  final byBucket = {for (final p in points) truncateBucket(p.t, w.unit): p};
  final buckets = bucketsOf(w);

  if (unit == MetricUnit.count) {
    // Un compteur n'est jamais « non mesurable » : un null serait un 0.
    final series = [
      for (final t in buckets)
        SeriesPoint(t, byBucket[t]?.valeur ?? 0, 0),
    ];
    final total = series.fold<double>(0, (a, s) => a + s.visitors);
    return CounterData(series, total.round());
  }

  var num = 0;
  var den = 0;
  final ratio = <RatioPoint>[];
  for (final t in buckets) {
    final p = byBucket[t];
    final v = p?.valeur;
    // Un bucket non mesurable reste un trou, quelle que soit l'option de trous
    // des taux : c'est une mesure refusée, pas un jour sans événement. Ses
    // effectifs ne comptent pas non plus dans le total.
    if (v != null) {
      num += p!.numerateur;
      den += p.denominateur;
    }
    ratio.add(RatioPoint(t, v == null ? null : v / 100));
  }
  return RatioData(
    points: ratio,
    overall: den < kMinRatioDenominator ? null : num / den,
    numeratorTotal: num,
    denominatorTotal: den,
  );
}
