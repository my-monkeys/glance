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

    test('thisMonth avec monthOffset : mois précédent, bornes figées', () {
      final w = Period.thisMonth.window(now: now, monthOffset: -1);
      expect(w.start, DateTime(2026, 7, 1));
      expect(w.end, DateTime(2026, 8, 1));
      expect(w.unit, TimeUnit.day);
    });

    test('thisMonth avec monthOffset : changement d\'année', () {
      final w = Period.thisMonth.window(now: now, monthOffset: -8);
      expect(w.start, DateTime(2025, 12, 1));
      expect(w.end, DateTime(2026, 1, 1));
      expect(w.unit, TimeUnit.day);
    });

    test('thisYear avec yearOffset : année précédente, bornes figées', () {
      final w = Period.thisYear.window(now: now, yearOffset: -1);
      expect(w.start, DateTime(2025, 1, 1));
      expect(w.end, DateTime(2026, 1, 1));
      expect(w.unit, TimeUnit.month);
    });

    test('allTime : 10 ans en arrière à aujourd\'hui, unité mois', () {
      final w = Period.allTime.window(now: now);
      expect(w.start, DateTime(2016, 1, 1));
      expect(w.end, DateTime(2026, 9, 1));
      expect(w.unit, TimeUnit.month);
    });
  });

  group('previousPeriodWindow', () {
    test('today : la journée calendaire d\'avant (pas un décalage de span)',
        () {
      final w = Period.today.window(now: now);
      final prev = previousPeriodWindow(w)!;
      expect(prev.start, DateTime(2026, 8, 10));
      expect(prev.end, DateTime(2026, 8, 11));
      expect(prev.unit, TimeUnit.hour);
    });

    test('h24 (glissante, non calendaire) : 24 h avant', () {
      final w = Period.h24.window(now: now);
      final prev = previousPeriodWindow(w)!;
      expect(prev.end, w.start);
      expect(w.start.difference(prev.start), w.end.difference(w.start));
      expect(prev.unit, TimeUnit.hour);
    });

    test('d7 : les 7 jours avant', () {
      final w = Period.d7.window(now: now);
      final prev = previousPeriodWindow(w)!;
      expect(prev.end, w.start);
      expect(w.start.difference(prev.start), w.end.difference(w.start));
      expect(prev.unit, TimeUnit.day);
    });

    test('d30 : les 30 jours avant', () {
      final w = Period.d30.window(now: now);
      final prev = previousPeriodWindow(w)!;
      expect(prev.end, w.start);
      expect(w.start.difference(prev.start), w.end.difference(w.start));
      expect(prev.unit, TimeUnit.day);
    });

    test('thisMonth (en cours) : le mois calendaire précédent en entier', () {
      final w = Period.thisMonth.window(now: now);
      final prev = previousPeriodWindow(w)!;
      expect(prev.start, DateTime(2026, 7, 1));
      expect(prev.end, DateTime(2026, 8, 1));
      expect(prev.unit, TimeUnit.day);
    });

    test('thisMonth (navigué, monthOffset) : le mois d\'avant celui-là', () {
      final w = Period.thisMonth.window(now: now, monthOffset: -1); // juillet
      final prev = previousPeriodWindow(w)!;
      expect(prev.start, DateTime(2026, 6, 1));
      expect(prev.end, DateTime(2026, 7, 1));
    });

    test('thisYear : l\'année civile précédente en entier', () {
      final w = Period.thisYear.window(now: now);
      final prev = previousPeriodWindow(w)!;
      expect(prev.start, DateTime(2025, 1, 1));
      expect(prev.end, DateTime(2026, 1, 1));
      expect(prev.unit, TimeUnit.month);
    });

    test('m12 (glissante, non calendaire) : décalée d\'un span identique', () {
      final w = Period.m12.window(now: now);
      final prev = previousPeriodWindow(w)!;
      expect(prev.end, w.start);
      expect(w.start.difference(prev.start), w.end.difference(w.start));
      expect(prev.unit, TimeUnit.month);
    });

    test('allTime : null (pas de "avant" pertinent)', () {
      final w = Period.allTime.window(now: now);
      expect(previousPeriodWindow(w), isNull);
    });
  });

  group('previousPeriodWindow face au découpage choisi', () {
    test('« ce mois-ci » en heures se compare au mois précédent, pas à la veille',
        () {
      final now = DateTime(2026, 9, 5, 14, 30);
      final w = Period.thisMonth.window(now: now, unit: TimeUnit.hour);
      final prev = previousPeriodWindow(w)!;
      expect(prev.start, DateTime(2026, 8, 1));
      expect(prev.end, DateTime(2026, 9, 1));
      expect(prev.unit, TimeUnit.hour);
    });

    test('« cette année » en jours se compare à l\'année précédente', () {
      final now = DateTime(2026, 3, 20, 10, 0);
      final w = Period.thisYear.window(now: now, unit: TimeUnit.day);
      final prev = previousPeriodWindow(w)!;
      expect(prev.start, DateTime(2025, 1, 1));
      expect(prev.end, DateTime(2026, 1, 1));
    });

    test('une fenêtre glissante se décale de sa propre durée', () {
      final now = DateTime(2026, 9, 16, 14, 0);
      final w = Period.d30.window(now: now, unit: TimeUnit.hour);
      final prev = previousPeriodWindow(w)!;
      expect(prev.end, w.start);
      expect(w.start.difference(prev.start), w.end.difference(w.start));
    });
  });

  group('displaySeries', () {
    // « Tout » : le rognage se déclenche sur ce drapeau, pas sur la durée — un
    // site jeune a un « Tout » de trois mois.
    DateWindow wideWindow() => DateWindow(
          DateTime(2016, 1, 1),
          DateTime(2026, 9, 1),
          TimeUnit.month,
          allTime: true,
        );
    DateWindow normalWindow() =>
        DateWindow(DateTime(2026, 8, 1), DateTime(2026, 8, 12), TimeUnit.day);

    test('fenêtre large : écarte le préfixe vide', () {
      final series = [
        SeriesPoint(DateTime(2026, 1, 1), 0, 0),
        SeriesPoint(DateTime(2026, 2, 1), 0, 0),
        SeriesPoint(DateTime(2026, 3, 1), 5, 12),
        SeriesPoint(DateTime(2026, 4, 1), 8, 20),
      ];
      final trimmed = displaySeries(series, wideWindow());
      expect(trimmed.length, 2);
      expect(trimmed.first.t, DateTime(2026, 3, 1));
    });

    test('fenêtre large mais entièrement vide : série inchangée', () {
      final series = [
        SeriesPoint(DateTime(2026, 1, 1), 0, 0),
        SeriesPoint(DateTime(2026, 2, 1), 0, 0),
      ];
      expect(displaySeries(series, wideWindow()), series);
    });

    test('fenêtre large, un seul point réel : pas de rognage sous 2 points',
        () {
      final series = [
        SeriesPoint(DateTime(2026, 1, 1), 0, 0),
        SeriesPoint(DateTime(2026, 2, 1), 0, 0),
        SeriesPoint(DateTime(2026, 3, 1), 3, 3),
      ];
      expect(displaySeries(series, wideWindow()), series);
    });

    test(
        'fenêtre large, visite isolée tôt (blip) : rogne après le vrai creux, pas au blip',
        () {
      final series = [
        SeriesPoint(DateTime(2016, 3, 1), 1, 1), // blip (test/bot) isolé
        SeriesPoint(DateTime(2016, 4, 1), 0, 0),
        SeriesPoint(DateTime(2016, 5, 1), 0, 0),
        SeriesPoint(DateTime(2016, 6, 1), 0, 0),
        SeriesPoint(DateTime(2016, 7, 1), 0, 0),
        SeriesPoint(DateTime(2016, 8, 1), 0, 0),
        SeriesPoint(DateTime(2026, 5, 1), 40, 90), // vrai démarrage
        SeriesPoint(DateTime(2026, 6, 1), 60, 140),
      ];
      final trimmed = displaySeries(series, wideWindow());
      expect(trimmed.length, 2);
      expect(trimmed.first.t, DateTime(2026, 5, 1));
    });

    test(
        'fenêtre large, creux de deux jours vers la fin : le préfixe est quand '
        'même rogné', () {
      // Le cas qui donnait un long trait plat dans les sparklines et les
      // widgets : un site jeune dans une fenêtre « Tout » commune, avec un
      // week-end creux vers la fin. L'ancienne coupe visait le DERNIER creux,
      // tombait après la fin utile, et renonçait — préfixe vide compris.
      final series = [
        for (var i = 0; i < 20; i++) SeriesPoint(DateTime(2026, 6, 1 + i), 0, 0),
        for (var i = 0; i < 10; i++)
          SeriesPoint(DateTime(2026, 6, 21 + i), 30 + i.toDouble(), 60),
        SeriesPoint(DateTime(2026, 7, 1), 0, 0),
        SeriesPoint(DateTime(2026, 7, 2), 0, 0),
        SeriesPoint(DateTime(2026, 7, 3), 25, 50),
      ];
      final trimmed = displaySeries(series, wideWindow());
      expect(trimmed.length, 13);
      expect(trimmed.first.t, DateTime(2026, 6, 21));
    });

    test('fenêtre large finissant sur des buckets vides : pas de rognage tardif',
        () {
      final series = [
        SeriesPoint(DateTime(2026, 5, 1), 10, 20),
        SeriesPoint(DateTime(2026, 6, 1), 12, 24),
        SeriesPoint(DateTime(2026, 7, 1), 0, 0),
        SeriesPoint(DateTime(2026, 8, 1), 0, 0),
      ];
      // La coupe viserait la fin de la série : mieux vaut tout garder.
      expect(displaySeries(series, wideWindow()), series);
    });

    test('fenêtre normale : jamais de rognage même avec un préfixe vide', () {
      final series = [
        SeriesPoint(DateTime(2026, 8, 1), 0, 0),
        SeriesPoint(DateTime(2026, 8, 2), 0, 0),
        SeriesPoint(DateTime(2026, 8, 3), 4, 9),
      ];
      expect(displaySeries(series, normalWindow()), series);
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

    test(
        "le 1er du mois, « aujourd'hui » n'est pas confondu avec « ce mois-ci »",
        () {
      // Les deux périodes commencent le même jour : seule la granularité les
      // distingue. Confondues, elles projetteraient trente jours à partir de
      // onze heures observées.
      final now = DateTime(2026, 9, 1, 10, 30);
      final spec = forecastSpecFor(Period.today.window(now: now), now: now)!;
      expect(spec.until, DateTime(2026, 9, 2));
      expect(spec.reference!.start, DateTime(2026, 8, 31));
      expect(spec.reference!.unit, TimeUnit.hour);
    });

    test('le 1er du mois, « ce mois-ci » projette bien la fin du mois', () {
      final now = DateTime(2026, 9, 1, 10, 30);
      final spec = forecastSpecFor(Period.thisMonth.window(now: now), now: now)!;
      expect(spec.until, DateTime(2026, 10, 1));
      expect(spec.reference!.start, DateTime(2026, 8, 1));
    });

    test('le 1er janvier, « cette année » reste « cette année »', () {
      final now = DateTime(2027, 1, 1, 9, 0);
      final spec = forecastSpecFor(Period.thisYear.window(now: now), now: now)!;
      expect(spec.until, DateTime(2028, 1, 1));
      expect(spec.reference!.start, DateTime(2026, 1, 1));
    });

    test('en janvier, « ce mois-ci » ne devient pas « cette année »', () {
      final now = DateTime(2027, 1, 10, 12, 0);
      final spec = forecastSpecFor(Period.thisMonth.window(now: now), now: now)!;
      expect(spec.until, DateTime(2027, 2, 1));
    });

    test('la référence suit la granularité forcée, sinon le profil se décale',
        () {
      // Profil indexé bucket à bucket : une référence en jours appliquée à des
      // buckets horaires surestimerait d'un facteur vingt-quatre.
      final now = DateTime(2026, 9, 16, 14, 0);
      final w = Period.thisMonth.window(now: now, unit: TimeUnit.hour);
      final spec = forecastSpecFor(w, now: now)!;
      expect(spec.reference!.unit, TimeUnit.hour);
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

    test('sans référence : bucket courant complété à son rythme et au précédent',
        () {
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
      // Rythme attendu du jour : 4 observés + 10 (veille) × 0,5 = 9.
      expect(f.points[1].visitors, closeTo(4 + 9 * 0.5, 0.001));
    });

    test('12 m : le mois en cours suit sa tendance, pas la moyenne annuelle', () {
      final on9Oct = DateTime(2026, 10, 9, 12);
      final w = Period.m12.window(now: on9Oct);
      // Site lancé en mai : sept mois vides, puis une croissance forte.
      final monthly = [0, 0, 0, 0, 0, 0, 14, 549, 753, 1923, 3605];
      final series = [
        for (var m = 0; m < monthly.length; m++)
          SeriesPoint(DateTime(2025, 11 + m), monthly[m].toDouble(), 0),
        SeriesPoint(DateTime(2026, 10), 1139, 0),
      ];

      final f = buildForecast(series: series, window: w, now: on9Oct)!;

      // L'ancienne moyenne sur 11 mois (~622) donnait ~1 590 : moins que
      // septembre, alors qu'octobre tourne plus vite.
      expect(f.points.last.visitors, greaterThan(3605));
      expect(f.points.last.visitors, lessThan(1139 / (8.5 / 31)));
    });

    test('cette année sans référence : les mois restants suivent octobre', () {
      final on9Oct = DateTime(2026, 10, 9, 12);
      final w = Period.thisYear.window(now: on9Oct);
      final monthly = [0, 0, 0, 0, 14, 549, 753, 1923, 3605];
      final series = [
        for (var m = 0; m < monthly.length; m++)
          SeriesPoint(DateTime(2026, 1 + m), monthly[m].toDouble(), 0),
        SeriesPoint(DateTime(2026, 10), 1139, 0),
      ];
      // L'an dernier est vide : pas de profil exploitable.
      final reference = [
        for (var m = 1; m <= 12; m++) SeriesPoint(DateTime(2025, m), 0, 0),
      ];

      final f = buildForecast(
        series: series,
        window: w,
        reference: reference,
        now: on9Oct,
      )!;

      final october = f.points[1].visitors;
      expect(october, greaterThan(3605));
      expect(f.points.last.t, DateTime(2026, 12));
      expect(f.points.last.visitors, closeTo(october, 0.001));
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
