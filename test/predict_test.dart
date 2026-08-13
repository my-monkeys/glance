import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/predict.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/models/period.dart';

void main() {
  // Un mardi en milieu de mois/d'année, à la demi-heure (fractions simples).
  final now = DateTime(2026, 8, 11, 12, 30);

  group('Period.window (nouvelles périodes)', () {
    test('thisMonth : du 1er du mois à demain minuit, unité jour', () {
      final w = Period.thisMonth.window(now: now);
      expect(w.start, DateTime(2026, 8, 1));
      expect(w.end, DateTime(2026, 8, 12));
      expect(w.unit, TimeUnit.day);
    });

    test('thisYear : du 1er janvier au 1er du mois prochain, unité mois', () {
      final w = Period.thisYear.window(now: now);
      expect(w.start, DateTime(2026, 1, 1));
      expect(w.end, DateTime(2026, 9, 1));
      expect(w.unit, TimeUnit.month);
    });
  });

  group('forecastSpecFor', () {
    test("aujourd'hui → projette jusqu'à minuit, référence = hier", () {
      final w = Period.today.window(now: now);
      final spec = forecastSpecFor(w, now: now)!;
      expect(spec.until, DateTime(2026, 8, 12));
      expect(spec.reference!.start, DateTime(2026, 8, 10));
      expect(spec.reference!.end, DateTime(2026, 8, 11));
      expect(spec.reference!.unit, TimeUnit.hour);
    });

    test('ce mois-ci → fin du mois, référence = mois précédent', () {
      final w = Period.thisMonth.window(now: now);
      final spec = forecastSpecFor(w, now: now)!;
      expect(spec.until, DateTime(2026, 9, 1));
      expect(spec.reference!.start, DateTime(2026, 7, 1));
      expect(spec.reference!.end, DateTime(2026, 8, 1));
    });

    test('cette année → fin de l’année, référence = année précédente', () {
      final w = Period.thisYear.window(now: now);
      final spec = forecastSpecFor(w, now: now)!;
      expect(spec.until, DateTime(2027, 1, 1));
      expect(spec.reference!.start, DateTime(2025, 1, 1));
      expect(spec.reference!.end, DateTime(2026, 1, 1));
    });

    test('fenêtre glissante (7 j) → complète le bucket courant, sans référence',
        () {
      final w = Period.d7.window(now: now);
      final spec = forecastSpecFor(w, now: now)!;
      expect(spec.until, w.end);
      expect(spec.reference, isNull);
    });

    test('fenêtre entièrement passée (hier) → rien à projeter', () {
      final w = Period.today.window(now: now, dayOffset: -1);
      expect(forecastSpecFor(w, now: now), isNull);
    });
  });

  group('buildForecast', () {
    test('avec référence : profil rescalé par le ratio observé/référence', () {
      final w = Period.today.window(now: now);
      // 13 buckets observés (0 h → 12 h) : 20/h, bucket courant à 10 (mi-heure).
      final series = [
        for (var h = 0; h < 12; h++)
          SeriesPoint(DateTime(2026, 8, 11, h), 20, 0),
        SeriesPoint(DateTime(2026, 8, 11, 12), 10, 0),
      ];
      // Hier : 10/h constant → on tourne à ×2 du rythme d'hier.
      final reference = [
        for (var h = 0; h < 24; h++)
          SeriesPoint(DateTime(2026, 8, 10, h), 10, 0),
      ];

      final f = buildForecast(
        series: series,
        window: w,
        reference: reference,
        now: now,
      )!;

      // Raccord sur 11 h (valeur réelle), bucket courant complété à 20,
      // puis 13 h → 23 h au profil d'hier ×2.
      expect(f.points.first.t, DateTime(2026, 8, 11, 11));
      expect(f.points.first.visitors, 20);
      expect(f.points[1].t, DateTime(2026, 8, 11, 12));
      expect(f.points[1].visitors, closeTo(20, 0.001));
      expect(f.points.length, 2 + 11);
      expect(f.points.last.t, DateTime(2026, 8, 11, 23));
      expect(f.points.last.visitors, closeTo(20, 0.001));
      // Somme projetée : 240 (complets) + 20 + 11×20 = 480 sur 250 observés.
      expect(f.growth, closeTo(480 / 250, 0.001));
      expect(f.projectedTotal(250), 480);
    });

    test('sans référence : bucket courant complété au rythme moyen', () {
      final atNoon = DateTime(2026, 8, 11, 12); // moitié du jour → f = 0,5
      final w = Period.d7.window(now: atNoon);
      final series = [
        for (var d = 0; d < 6; d++)
          SeriesPoint(DateTime(2026, 8, 5 + d), 10, 0),
        SeriesPoint(DateTime(2026, 8, 11), 4, 0),
      ];

      final f = buildForecast(series: series, window: w, now: atNoon)!;

      // Pas de bucket futur (fenêtre glissante) : raccord + projection du jour.
      expect(f.points.length, 2);
      expect(f.points[1].visitors, closeTo(4 + 10 * 0.5, 0.001));
    });

    test('référence morte sur le reste → repli sur le rythme moyen', () {
      final w = Period.today.window(now: now);
      final series = [
        for (var h = 0; h < 12; h++)
          SeriesPoint(DateTime(2026, 8, 11, h), 20, 0),
        SeriesPoint(DateTime(2026, 8, 11, 12), 10, 0),
      ];
      // Hier : collecte morte à partir de midi (instance down).
      final reference = [
        for (var h = 0; h < 24; h++)
          SeriesPoint(DateTime(2026, 8, 10, h), h < 12 ? 10.0 : 0.0, 0),
      ];

      final f = buildForecast(
        series: series,
        window: w,
        reference: reference,
        now: now,
      )!;

      // Sans le garde-fou, tous les buckets restants seraient à 0. Avec :
      // rythme moyen des 12 buckets complets (20/h).
      expect(f.points.last.visitors, closeTo(20, 0.001));
      expect(f.points[1].visitors, greaterThan(10)); // bucket courant complété
    });

    test('série désalignée sur le bucket courant → pas de prévision', () {
      final w = Period.d7.window(now: now);
      final series = [SeriesPoint(DateTime(2026, 8, 5), 10, 0)];
      expect(buildForecast(series: series, window: w, now: now), isNull);
    });
  });
}
