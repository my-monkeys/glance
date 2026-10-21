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

  group('décalage par délai de mesure', () {
    final now = DateTime(2026, 10, 21, 14);
    // « 7 jours » : 7 jours pleins, fin = début du jour suivant.
    final sept = DateWindow(DateTime(2026, 10, 15), DateTime(2026, 10, 22), TimeUnit.day);

    test('J7 sur 7 jours → cohortes du 07 au 13, même durée', () {
      final v = externalViewOf(sept, 7, now);
      expect(v.window.start, DateTime(2026, 10, 7));
      expect(v.window.end, DateTime(2026, 10, 14));
      expect(v.window.unit, TimeUnit.day);
      expect(v.cohorts, CohortSpan(DateTime(2026, 10, 7), DateTime(2026, 10, 13)));
    });

    test('J1 : dernière cohorte = hier − 1', () {
      final v = externalViewOf(sept, 1, now);
      expect(v.window.end, DateTime(2026, 10, 20));
      expect(v.cohorts!.last, DateTime(2026, 10, 19));
    });

    test('délai 0 : fenêtre inchangée, pas de mention', () {
      final v = externalViewOf(sept, 0, now);
      expect(v.window.start, sept.start);
      expect(v.window.end, sept.end);
      expect(v.cohorts, isNull);
    });

    test('fenêtre déjà entièrement mesurable : pas décalée', () {
      final past = DateWindow(DateTime(2026, 8, 1), DateTime(2026, 9, 1), TimeUnit.day);
      final v = externalViewOf(past, 30, now);
      expect(v.window.start, past.start);
      expect(v.window.end, past.end);
      expect(v.cohorts, isNull);
    });

    test('fenêtre horaire → une seule cohorte, la dernière mesurable', () {
      final h = DateWindow(DateTime(2026, 10, 21), DateTime(2026, 10, 21, 15), TimeUnit.hour);
      final v = externalViewOf(h, 7, now);
      expect(v.window.start, DateTime(2026, 10, 13));
      expect(v.window.end, DateTime(2026, 10, 14));
      expect(v.cohorts, CohortSpan(DateTime(2026, 10, 13), DateTime(2026, 10, 13)));
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
