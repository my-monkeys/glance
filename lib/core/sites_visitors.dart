import 'dart:math' as math;

import '../data/models/indicator.dart';
import '../data/models/indicator_result.dart';
import '../data/models/models.dart';

/// Visiteurs uniques d'un site (ou d'une part) : par bucket, et sur toute la
/// fenêtre. Le total n'est pas la somme des buckets : un visiteur revenu deux
/// jours compte une fois.
typedef SiteVisitors = ({List<SeriesPoint> points, int total});

/// Les visiteurs d'un site moins ceux venus d'un référent. Umami n'a pas
/// d'exclusion fiable : `referrer=neq.x` écarte aussi les visites sans
/// référent (vérifié sur geography : 243 au lieu de 511 − 75 = 436).
SiteVisitors visitorsExcept(SiteVisitors all, SiteVisitors from) => (
      points: [
        for (final (i, p) in all.points.indexed)
          SeriesPoint(
            p.t,
            math.max(0, p.visitors - from.points[i].visitors),
            0,
          ),
      ],
      total: math.max(0, all.total - from.total),
    );

/// Tableau « Sites » → compteur découpé, une part par ligne : il s'affiche
/// comme les plateformes d'une métrique de site. Le total est la somme des
/// lignes (des sites différents ne partagent pas leurs visiteurs uniques).
CounterData sitesCounterOf(List<SiteLine> lines, List<SiteVisitors> values) {
  final times = values.isEmpty
      ? const <DateTime>[]
      : [for (final p in values.first.points) p.t];
  return CounterData(
    [
      for (final (i, t) in times.indexed)
        SeriesPoint(t, values.fold(0.0, (a, v) => a + v.points[i].visitors), 0),
    ],
    values.fold(0, (a, v) => a + v.total),
    segments: [
      for (final (i, l) in lines.indexed)
        CounterSegment(
          label: l.label,
          values: [for (final p in values[i].points) p.visitors],
          periodTotal: values[i].total,
        ),
    ],
  );
}
