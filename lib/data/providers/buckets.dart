import '../models/period.dart';

/// Au-delà, la série ne se lit plus et la remplir coûte plus que ce qu'elle
/// apprend. `allowedUnits` (data/models/period.dart) n'offre jamais une
/// granularité qui y mène ; si on y arrive quand même, mieux vaut une erreur
/// visible qu'une courbe tronquée par la fin, qui passerait pour un trou de
/// collecte.
const kMaxBuckets = 2000;

DateTime truncateBucket(DateTime t, TimeUnit u) => switch (u) {
      TimeUnit.hour => DateTime(t.year, t.month, t.day, t.hour),
      TimeUnit.day => DateTime(t.year, t.month, t.day),
      TimeUnit.month => DateTime(t.year, t.month, 1),
    };

DateTime advanceBucket(DateTime t, TimeUnit u) => switch (u) {
      TimeUnit.hour => t.add(const Duration(hours: 1)),
      TimeUnit.day => DateTime(t.year, t.month, t.day + 1),
      TimeUnit.month => DateTime(t.year, t.month + 1, 1),
    };

/// Buckets continus de la fenêtre (les fournisseurs renvoient des séries
/// creuses).
List<DateTime> bucketsOf(DateWindow w) {
  final out = <DateTime>[];
  var c = truncateBucket(w.start, w.unit);
  // Borne de fin exclusive : `w.end` est plafonné au début de l'unité
  // suivante, donc on s'arrête avant (pas de bucket futur vide).
  final end = truncateBucket(w.end, w.unit);
  while (c.isBefore(end)) {
    if (out.length >= kMaxBuckets) {
      throw StateError(
        'Découpage trop fin : plus de $kMaxBuckets points sur la période.',
      );
    }
    out.add(c);
    c = advanceBucket(c, w.unit);
  }
  return out;
}
