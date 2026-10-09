import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/daily_forecast.dart';
import 'package:glance/core/predict.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/models/period.dart';

/// geography, visiteurs par jour du 1er septembre au 9 octobre 2026 midi
/// (relevé en base) ; 3 605 visiteurs uniques en septembre.
const _geoSept = [
  97, 114, 83, 88, 64, 64, 116, 105, 142, 401, 96, 73, 86, 135, 116, 110, //
  133, 92, 291, 115, 158, 142, 169, 140, 139, 145, 125, 162, 153, 152,
];
const _geoOct = [161, 146, 101, 100, 144, 169, 164, 158, 118];

List<SeriesPoint> _days(DateTime first, List<num> values) => [
  for (var k = 0; k < values.length; k++)
    SeriesPoint(DateTime(first.year, first.month, first.day + k),
        values[k].toDouble(), 0),
];

void main() {
  group('projectDays', () {
    test('reprend le creux du week-end', () {
      // Six semaines : 100 en semaine, 40 le week-end. Dernier jour : dimanche.
      final first = DateTime(2026, 8, 24); // lundi
      final values = [
        for (var k = 0; k < 42; k++) k % 7 >= 5 ? 40 : 100,
      ];
      final p = projectDays(_days(first, values), 7)!;
      expect(p[0], closeTo(100, 0.001)); // lundi
      expect(p[5], closeTo(40, 0.001)); // samedi
    });

    test('suit le niveau des sept derniers jours, pas la moyenne', () {
      final first = DateTime(2026, 8, 24);
      final values = [for (var k = 0; k < 28; k++) k < 21 ? 50 : 150];
      final p = projectDays(_days(first, values), 3)!;
      // Profil plat (rapport moyen ≈ 1) : le niveau récent l'emporte.
      expect(p.first, greaterThan(140));
    });

    test('moins de deux semaines : pas de projection', () {
      expect(projectDays(_days(DateTime(2026, 9, 1), List.filled(13, 10)), 5),
          isNull);
    });
  });

  group('buildForecast jour par jour', () {
    final now = DateTime(2026, 10, 9, 12);
    final daily = _days(DateTime(2026, 9, 1), [..._geoSept, ..._geoOct]);

    test('geography, 12 m : octobre dépasse septembre', () {
      final w = Period.m12.window(now: now);
      final monthly = [0, 0, 0, 0, 0, 0, 14, 549, 753, 1923, 3605, 1139];
      final series = [
        for (var m = 0; m < monthly.length; m++)
          SeriesPoint(DateTime(2025, 11 + m), monthly[m].toDouble(), 0),
      ];
      final f = buildForecast(
          series: series, window: w, daily: daily, now: now)!;
      final october = f.points.last.visitors;
      expect(f.points.last.t, DateTime(2026, 10));
      expect(october, inInclusiveRange(3700, 4600));
    });

    test('geography, cette année : novembre et décembre au rythme récent', () {
      final w = Period.thisYear.window(now: now);
      final monthly = [0, 0, 0, 0, 14, 549, 753, 1923, 3605, 1139];
      final series = [
        for (var m = 0; m < monthly.length; m++)
          SeriesPoint(DateTime(2026, 1 + m), monthly[m].toDouble(), 0),
      ];
      final f = buildForecast(
          series: series, window: w, daily: daily, now: now)!;
      expect(f.points.map((p) => p.t),
          [DateTime(2026, 9), DateTime(2026, 10), DateTime(2026, 11),
           DateTime(2026, 12)]);
      // Novembre, mois plein au rythme d'octobre : au-delà de septembre.
      expect(f.points[2].visitors, greaterThan(3605));
    });

    test('ce mois-ci en jours : chaque jour restant est projeté', () {
      final w = Period.thisMonth.window(now: now);
      final series = _days(DateTime(2026, 10, 1), _geoOct);
      final f = buildForecast(
          series: series, window: w, daily: daily, now: now)!;
      // Raccord (8 oct.) + aujourd'hui + 22 jours restants.
      expect(f.points.length, 2 + 22);
      expect(f.points.last.t, DateTime(2026, 10, 31));
      expect(f.points[1].visitors, greaterThanOrEqualTo(118));
    });

    test('historique désaligné sur aujourd\'hui : repli sur le modèle bucket',
        () {
      final w = Period.thisMonth.window(now: now);
      final series = _days(DateTime(2026, 10, 1), _geoOct);
      final stale = daily.sublist(0, daily.length - 1);
      final withStale = buildForecast(
          series: series, window: w, daily: stale, now: now);
      final without = buildForecast(series: series, window: w, now: now);
      expect(withStale!.growth, without!.growth);
    });
  });

  test('forecastHistoryWindow : neuf semaines en jours, rien en heures', () {
    final now = DateTime(2026, 10, 9, 12);
    final h = forecastHistoryWindow(Period.m12.window(now: now), now: now)!;
    expect(h.unit, TimeUnit.day);
    expect(h.end, DateTime(2026, 10, 10));
    expect(h.start, DateTime(2026, 10, 9 - kHistoryDays));
    expect(
        forecastHistoryWindow(Period.today.window(now: now), now: now), isNull);
  });
}
