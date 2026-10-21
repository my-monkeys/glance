import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/external_metrics.dart';
import 'package:glance/data/models/indicator_result.dart';
import 'package:glance/data/models/metrics_source.dart';
import 'package:glance/data/models/period.dart';

MetricPoint _p(int day, double? v, int num, int den) =>
    MetricPoint(t: DateTime(2026, 10, day), valeur: v, numerateur: num, denominateur: den);

// 5 → 8 octobre : trois jours.
final _w = DateWindow(DateTime(2026, 10, 5), DateTime(2026, 10, 8), TimeUnit.day);

void main() {
  group('taux', () {
    test('un point par bucket ; manquant ou null → trou ; valeur /100', () {
      final d = externalDataOf(MetricUnit.percent, _w, [
        _p(5, 20, 10, 50),
        _p(7, null, 0, 0),
      ]) as RatioData;

      expect(d.points.map((p) => p.t), [
        DateTime(2026, 10, 5),
        DateTime(2026, 10, 6),
        DateTime(2026, 10, 7),
      ]);
      expect(d.points[0].value, closeTo(0.2, 1e-9));
      expect(d.points[1].value, isNull); // l'API n'a rien renvoyé
      expect(d.points[2].value, isNull); // non mesurable
    });

    test('global = Σnumérateur / Σdénominateur, pas la moyenne des taux', () {
      final d = externalDataOf(MetricUnit.percent, _w, [
        _p(5, 50, 1, 2),
        _p(6, 10, 30, 300),
      ]) as RatioData;
      expect(d.numeratorTotal, 31);
      expect(d.denominatorTotal, 302);
      expect(d.overall, closeTo(31 / 302, 1e-9));
    });

    test('un bucket non mesurable ne pèse pas dans le global', () {
      final d = externalDataOf(MetricUnit.percent, _w, [
        _p(5, 50, 5, 10),
        _p(6, null, 40, 90),
      ]) as RatioData;
      expect(d.denominatorTotal, 10);
      expect(d.overall, closeTo(0.5, 1e-9));
    });

    test('Σdénominateur < 5 → global masqué (seuil de confidentialité)', () {
      final d = externalDataOf(MetricUnit.percent, _w, [_p(5, 50, 2, 4)])
          as RatioData;
      expect(d.overall, isNull);
      expect(d.denominatorTotal, 4);
    });

    test('un bucket hors fenêtre est écarté', () {
      final d = externalDataOf(MetricUnit.percent, _w, [
        _p(1, 90, 90, 100),
        _p(5, 20, 1, 5),
      ]) as RatioData;
      expect(d.points, hasLength(3));
      expect(d.denominatorTotal, 5);
    });
  });

  group('nombre', () {
    test('manquant ou null → 0, total = somme', () {
      final d = externalDataOf(MetricUnit.count, _w, [
        _p(5, 12, 12, 1),
        _p(7, null, 0, 1),
      ]) as CounterData;
      expect(d.points.map((p) => p.visitors), [12, 0, 0]);
      expect(d.total, 12);
    });
  });

  group('mois', () {
    test('le premier bucket peut commencer avant le début de la fenêtre', () {
      final w = DateWindow(DateTime(2026, 8, 15), DateTime(2026, 10, 1), TimeUnit.month);
      final d = externalDataOf(MetricUnit.count, w, [
        MetricPoint(t: DateTime(2026, 8, 1), valeur: 3, numerateur: 3, denominateur: 1),
        MetricPoint(t: DateTime(2026, 9, 1), valeur: 4, numerateur: 4, denominateur: 1),
      ]) as CounterData;
      expect(d.points.map((p) => p.t), [DateTime(2026, 8, 1), DateTime(2026, 9, 1)]);
      expect(d.total, 7);
    });
  });

  group('fenêtre horaire', () {
    test('lue en jours : un bucket par jour, jusqu\'au jour en cours', () {
      final w = DateWindow(
          DateTime(2026, 10, 19, 0), DateTime(2026, 10, 20, 15), TimeUnit.hour);
      expect(externalUnitOf(w.unit), TimeUnit.day);
      final d = externalDataOf(MetricUnit.count, w, [_p(20, 7, 7, 1)])
          as CounterData;
      expect(d.points.map((p) => p.t), [
        DateTime(2026, 10, 19),
        DateTime(2026, 10, 20),
      ]);
      expect(d.total, 7);
    });
  });

  group('placement à la date de mesure', () {
    // Aujourd'hui = 21/10 ; « 7 jours » = 15 → 21 oct., fin exclusive 22.
    final now = DateTime(2026, 10, 21, 14);
    final sept = DateWindow(DateTime(2026, 10, 15), DateTime(2026, 10, 22), TimeUnit.day);

    test('J7 : la cohorte du 8 est placée au 15, la fenêtre reste l\'axe', () {
      final d = externalDataOf(
        MetricUnit.percent,
        sept,
        [_p(8, 20, 10, 50), _p(9, 40, 20, 50), _p(13, 10, 5, 50)],
        delayDays: 7,
        now: now,
      ) as RatioData;

      expect(d.points.map((p) => p.t), [
        for (var i = 15; i <= 21; i++) DateTime(2026, 10, i),
      ]);
      expect(d.points[0].value, closeTo(0.2, 1e-9));
      expect(d.points[0].cohort, DateTime(2026, 10, 8));
      expect(d.points[1].cohort, DateTime(2026, 10, 9));
      expect(d.points[5].value, closeTo(0.1, 1e-9)); // cohorte 13 → le 20
      expect(d.cohorts, CohortSpan(DateTime(2026, 10, 8), DateTime(2026, 10, 13)));
    });

    test('le jour de mesure pas terminé reste null, même si le serveur répond',
        () {
      // Cohorte du 14 mesurée le 21 = aujourd'hui.
      final d = externalDataOf(
        MetricUnit.percent,
        sept,
        [_p(8, 20, 10, 50), _p(14, 30, 15, 50)],
        delayDays: 7,
        now: now,
      ) as RatioData;

      expect(d.points.last.t, DateTime(2026, 10, 21));
      expect(d.points.last.value, isNull);
      expect(d.points.where((p) => p.value != null), hasLength(1));
      expect(d.denominatorTotal, 50); // la mesure inachevée ne pèse pas
      expect(d.cohorts!.last, DateTime(2026, 10, 8));
    });

    test('« Aujourd\'hui », J1 : une seule cohorte, pas encore mesurable', () {
      final today = DateWindow(DateTime(2026, 10, 21), DateTime(2026, 10, 21, 15), TimeUnit.hour);
      final d = externalDataOf(
        MetricUnit.percent,
        today,
        [_p(20, 30, 15, 50)],
        delayDays: 1,
        now: now,
      ) as RatioData;

      expect(d.points, hasLength(1));
      expect(d.points.single.value, isNull);
      expect(d.pending, isTrue);
      expect(d.cohorts, isNull);
    });

    test('« Aujourd\'hui », J1, réponse réelle du serveur (null, dénominateur 0) : en attente', () {
      final today = DateWindow(DateTime(2026, 10, 21), DateTime(2026, 10, 21, 15), TimeUnit.hour);
      final d = externalDataOf(
        MetricUnit.percent,
        today,
        [_p(20, null, 0, 0)],
        delayDays: 1,
        now: now,
      ) as RatioData;

      expect(d.pending, isTrue);
      expect(d.overall, isNull);
    });

    test('sans délai, une fenêtre vide reste « aucune donnée »', () {
      final d = externalDataOf(
        MetricUnit.percent,
        _w,
        const [],
        now: now,
      ) as RatioData;

      expect(d.pending, isFalse);
    });

    test('« Hier », J1 : une seule cohorte mesurée', () {
      final yesterday =
          DateWindow(DateTime(2026, 10, 20), DateTime(2026, 10, 21), TimeUnit.day);
      final d = externalDataOf(
        MetricUnit.percent,
        yesterday,
        [_p(19, 30, 15, 50)],
        delayDays: 1,
        now: now,
      ) as RatioData;

      expect(d.points, hasLength(1));
      expect(d.points.single.cohort, DateTime(2026, 10, 19));
      expect(d.cohorts, CohortSpan(DateTime(2026, 10, 19), DateTime(2026, 10, 19)));
    });

    test('en mois : décalage de d jours puis bucket du mois, sans cohorte jour',
        () {
      final w = DateWindow(DateTime(2026, 8, 1), DateTime(2026, 11, 1), TimeUnit.month);
      final d = externalDataOf(
        MetricUnit.percent,
        w,
        [
          MetricPoint(t: DateTime(2026, 7, 1), valeur: 5, numerateur: 5, denominateur: 100),
          MetricPoint(t: DateTime(2026, 8, 1), valeur: 20, numerateur: 20, denominateur: 100),
          MetricPoint(t: DateTime(2026, 9, 1), valeur: 30, numerateur: 30, denominateur: 100),
        ],
        delayDays: 7,
        now: now,
      ) as RatioData;

      expect(d.points.map((p) => p.t), [
        DateTime(2026, 8, 1),
        DateTime(2026, 9, 1),
        DateTime(2026, 10, 1),
      ]);
      // Le 1er juillet + 7 j reste en juillet : hors fenêtre, écarté.
      expect(d.points.map((p) => p.value), [closeTo(0.2, 1e-9), closeTo(0.3, 1e-9), isNull]);
      expect(d.points.every((p) => p.cohort == null), isTrue);
      expect(d.cohorts!.first, DateTime(2026, 8, 1));
      expect(d.cohorts!.last, DateTime(2026, 9, 30));
    });

    test('délai 0 : rien n\'est déplacé ni masqué, pas de cohortes', () {
      final d = externalDataOf(MetricUnit.percent, _w, [_p(7, 20, 10, 50)],
          now: now) as RatioData;
      expect(d.points[2].value, closeTo(0.2, 1e-9));
      expect(d.cohorts, isNull);
    });

    test('un nombre à délai est placé de la même façon', () {
      final d = externalDataOf(MetricUnit.count, sept, [_p(8, 12, 12, 1)],
          delayDays: 7, now: now) as CounterData;
      expect(d.points.first.t, DateTime(2026, 10, 15));
      expect(d.points.first.visitors, 12);
    });
  });

  group('pas encore mesurable', () {
    test('tous les points null mais des gens comptés → pending', () {
      final d = externalDataOf(MetricUnit.percent, _w, [_p(5, null, 3, 40)])
          as RatioData;
      expect(d.pending, isTrue);
      expect(d.denominatorTotal, 0);
    });

    test('aucun point du tout → pas pending', () {
      final d = externalDataOf(MetricUnit.percent, _w, const []) as RatioData;
      expect(d.pending, isFalse);
    });
  });
}
