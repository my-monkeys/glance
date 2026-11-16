import 'dart:ui' show Color;

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

  group('données publiées jusqu\'au', () {
    // 5 → 7 oct. ; la source a publié jusqu'au 5.
    final until = DateTime(2026, 10, 5);

    test('nombre : les jours d\'après sont signalés, hors du total', () {
      final d = externalDataOf(
        MetricUnit.count,
        _w,
        [_p(5, 12, 12, 1), _p(6, 3, 3, 1), _p(7, null, 0, 0)],
        dataUntil: until,
      ) as CounterData;
      expect(d.total, 12); // le 6 n'est pas publié : sa valeur est ignorée
      expect(d.unpublished!.until, until);
      expect(d.unpublished!.from, DateTime(2026, 10, 6));
      expect(d.points.map((p) => d.unpublished!.covers(p.t)), [false, true, true]);
    });

    test('taux : trous après la date, effectifs exclus', () {
      final d = externalDataOf(
        MetricUnit.percent,
        _w,
        [_p(5, 20, 10, 50), _p(6, 40, 20, 50)],
        dataUntil: until,
      ) as RatioData;
      expect(d.points.map((p) => p.value), [closeTo(0.2, 1e-9), isNull, isNull]);
      expect(d.denominatorTotal, 50);
      expect(d.unpublished, isNotNull);
    });

    test('fenêtre entièrement publiée : rien à signaler', () {
      final d = externalDataOf(MetricUnit.count, _w, [_p(5, 1, 1, 1)],
          dataUntil: DateTime(2026, 10, 9)) as CounterData;
      expect(d.unpublished, isNull);
    });

    test('mois : le mois en cours reste, les mois d\'après sont des trous', () {
      final w = DateWindow(DateTime(2026, 8, 1), DateTime(2026, 11, 1), TimeUnit.month);
      final d = externalDataOf(
        MetricUnit.count,
        w,
        [
          MetricPoint(t: DateTime(2026, 8, 1), valeur: 3, numerateur: 3, denominateur: 1),
          MetricPoint(t: DateTime(2026, 9, 1), valeur: 4, numerateur: 4, denominateur: 1),
          MetricPoint(t: DateTime(2026, 10, 1), valeur: 9, numerateur: 9, denominateur: 1),
        ],
        dataUntil: DateTime(2026, 9, 28),
      ) as CounterData;
      expect(d.total, 7);
      expect(d.unpublished!.from, DateTime(2026, 10, 1));
    });

    test('catalogue : donnees_jusqu_au lu en date locale, sinon null', () {
      MetricDef def(Object? v) => MetricDef.fromJson(
          {'id': 'a', 'libelle': 'A', 'unite': 'nombre', 'donnees_jusqu_au': v});
      expect(def('2026-10-18').donneesJusquAu, DateTime(2026, 10, 18));
      expect(def(null).donneesJusquAu, isNull);
      expect(def('18/10/2026').donneesJusquAu, isNull);
    });
  });

  group('compteur découpé', () {
    const parts = [
      MetricSegment(id: 'site', libelle: 'Site'),
      MetricSegment(id: 'alldle', libelle: 'Alldle', estime: true),
    ];
    MetricPoint split(int day, double v, Map<String, double>? segments) =>
        MetricPoint(
          t: DateTime(2026, 10, day),
          valeur: v,
          numerateur: 0,
          denominateur: 0,
          segments: segments,
        );

    test('un point sans découpage est un trou de chaque part, pas un zéro', () {
      final d = externalDataOf(
        MetricUnit.count,
        _w,
        [
          split(5, 120, null),
          split(6, 12, {'site': 7, 'alldle': 5}),
        ],
        segments: parts,
        totals: {'site': 7, 'alldle': 5},
      ) as CounterData;

      expect(d.total, 132);
      expect(d.segments.map((s) => s.label), ['Site', 'Alldle']);
      expect(d.segments.first.values, [null, 7, null]);
      expect(d.segments.last.values, [null, 5, null]);
      expect(d.segments.last.estimated, isTrue);
      expect(d.segments.first.periodTotal, 7);
    });

    test('un jour pas encore publié reste un trou, même découpé', () {
      final d = externalDataOf(
        MetricUnit.count,
        _w,
        [split(7, 4, {'site': 4, 'alldle': 0})],
        segments: parts,
        dataUntil: DateTime(2026, 10, 6),
      ) as CounterData;
      expect(d.segments.first.values, [null, null, null]);
      expect(d.segments.first.periodTotal, isNull);
    });

    test('sans parts au catalogue, pas de découpage', () {
      final d = externalDataOf(
        MetricUnit.count,
        _w,
        [split(5, 3, {'site': 3})],
      ) as CounterData;
      expect(d.segments, isEmpty);
    });
  });

  group('heures', () {
    // 30 octobre, de 10 h à 13 h : trois heures.
    final hours =
        DateWindow(DateTime(2026, 10, 30, 10), DateTime(2026, 10, 30, 13), TimeUnit.hour);
    MetricPoint at(int hour, double v, [Map<String, double>? segments]) => MetricPoint(
          t: DateTime(2026, 10, 30, hour),
          valeur: v,
          numerateur: 0,
          denominateur: 0,
          segments: segments,
        );

    test('une source horaire est rangée heure par heure', () {
      final d = externalDataOf(
        MetricUnit.count,
        hours,
        [at(9, 50), at(10, 4), at(12, 6, {'site': 6})],
        hourly: true,
        segments: const [MetricSegment(id: 'site', libelle: 'Site')],
      ) as CounterData;
      expect(d.unit, TimeUnit.hour);
      expect(d.points.map((p) => p.t.hour), [10, 11, 12]);
      expect(d.points.map((p) => p.visitors), [4, 0, 6]); // 9 h hors fenêtre
      expect(d.segments.single.values, [null, null, 6]);
    });

    test('sans heures à la source, la fenêtre se lit en jours', () {
      final d = externalDataOf(
        MetricUnit.count,
        hours,
        [MetricPoint(t: DateTime(2026, 10, 30), valeur: 12, numerateur: 0, denominateur: 0)],
      ) as CounterData;
      expect(d.unit, TimeUnit.day);
      expect(d.total, 12);
    });

    test('toutes les heures du dernier jour publié le sont', () {
      final d = externalDataOf(
        MetricUnit.count,
        hours,
        [at(10, 1), at(11, 2), at(12, 3)],
        hourly: true,
        dataUntil: DateTime(2026, 10, 30),
      ) as CounterData;
      expect(d.unpublished, isNull);
      expect(d.total, 6);
    });
  });

  group('hebdomadaire', () {
    // Les 6 semaines du 5 oct. au 9 nov. 2026 (GeoDaily) ; la dernière est en cours.
    final mondays = [
      DateTime(2026, 10, 5),
      DateTime(2026, 10, 12),
      DateTime(2026, 10, 19),
      DateTime(2026, 10, 26), // passage à l'heure d'hiver le 25
      DateTime(2026, 11, 2),
      DateTime(2026, 11, 9),
    ];
    const totals = [170.0, 258.0, 360.0, 483.0, 519.0, 557.0];
    const lastParts = {
      'explorateur': 446.0,
      'navigateur': 88.0,
      'cartographe': 20.0,
      'geographe': 1.0,
      'globe_trotter': 1.0,
      'legende': 1.0,
    };
    final points = [
      for (final (i, t) in mondays.indexed)
        MetricPoint(
          t: t,
          valeur: totals[i],
          numerateur: 0,
          denominateur: 0,
          segments: i == 5 ? lastParts : {'explorateur': totals[i]},
        ),
    ];
    final segments = [
      for (final k in lastParts.keys) MetricSegment(id: k, libelle: k),
    ];
    // Un mercredi (7 oct.) jusqu'au lendemain de la semaine en cours.
    final window = DateWindow(DateTime(2026, 10, 7), DateTime(2026, 11, 14), TimeUnit.day);
    final now = DateTime(2026, 11, 13, 10);

    CounterData run({
      MetricAggregation aggregation = MetricAggregation.sum,
      DateWindow? w,
      DateTime? at,
      List<MetricPoint>? pts,
    }) =>
        externalDataOf(
          MetricUnit.count,
          w ?? window,
          pts ?? points,
          now: at ?? now,
          weekly: true,
          aggregation: aggregation,
          segments: segments,
          totals: {'explorateur': 9999},
        ) as CounterData;

    test('un bucket par lundi, dès le lundi de la fenêtre, passage à l\'heure d\'hiver compris',
        () {
      final d = run();
      expect(d.points.map((p) => p.t), mondays);
      expect(d.points.map((p) => p.visitors), totals);
      expect(d.weekly, isTrue);
      expect(d.unit, TimeUnit.day);
    });

    test('un point daté d\'un autre jour de la semaine est rangé à son lundi', () {
      final d = run(pts: [
        MetricPoint(t: DateTime(2026, 10, 14), valeur: 7, numerateur: 0, denominateur: 0),
      ]);
      // La semaine du 5 oct., vide, précède la première valeur : pas tracée.
      expect(d.points.first.t, DateTime(2026, 10, 12));
      expect(d.points.map((p) => p.visitors), [7, 0, 0, 0, 0]);
    });

    test('12 m : les semaines vides d\'avant le lancement ne sont pas tracées', () {
      final d = run(
        w: DateWindow(DateTime(2025, 12), DateTime(2026, 12), TimeUnit.month),
      );
      expect(d.points.map((p) => p.t), mondays);
    });

    test('une semaine vide au milieu reste un zéro', () {
      final d = run(pts: [
        for (final (i, p) in points.indexed)
          i == 2
              ? MetricPoint(t: p.t, valeur: 0, numerateur: 0, denominateur: 0,
                  segments: {'explorateur': 0})
              : p,
      ]);
      expect(d.points, hasLength(6));
      expect(d.points[2].visitors, 0);
      expect(d.segments.first.values[2], 0);
    });

    test('tout vide : toutes les semaines, la carte dira 0', () {
      final d = run(pts: const []);
      expect(d.points.map((p) => p.t), mondays);
    });

    test('pas de semaine qui n\'a pas commencé', () {
      final d = run(at: DateTime(2026, 11, 4)); // mercredi de la semaine du 2
      expect(d.points.last.t, DateTime(2026, 11, 2));
    });

    test('somme par défaut', () {
      expect(run().total, 2347);
      expect(run().latest, isNull);
    });

    test('« dernier » : le total est le dernier bucket, pas la somme', () {
      // Lundi suivant : la semaine du 9 nov. est terminée.
      final d = run(aggregation: MetricAggregation.last, at: DateTime(2026, 11, 16, 10));
      expect(d.total, 557);
      expect(d.latest, (t: DateTime(2026, 11, 9), ongoing: false));
      expect(d.lastInProgress, isFalse);
    });

    test('« dernier » : la semaine en cours n\'est pas résumée, elle est en pointillé',
        () {
      // Vendredi 13 : la semaine du 9 se remplit encore, le chiffre est celle du 2.
      final d = run(aggregation: MetricAggregation.last);
      expect(d.total, 519);
      expect(d.latest, (t: DateTime(2026, 11, 2), ongoing: false));
      expect(d.lastInProgress, isTrue);
      expect(d.points.last.visitors, 557);
    });

    test('« dernier » : seule la semaine en cours → elle, marquée en cours', () {
      final d = run(
        aggregation: MetricAggregation.last,
        w: DateWindow(DateTime(2026, 11, 13), DateTime(2026, 11, 14), TimeUnit.hour),
      );
      expect(d.total, 557);
      expect(d.latest, (t: DateTime(2026, 11, 9), ongoing: true));
    });

    test('« dernier » : les parts sont celles de la dernière semaine, `totaux` ignoré',
        () {
      final d = run(aggregation: MetricAggregation.last, at: DateTime(2026, 11, 16, 10));
      expect({for (final s in d.segments) s.label: s.periodTotal}, {
        'explorateur': 446,
        'navigateur': 88,
        'cartographe': 20,
        'geographe': 1,
        'globe_trotter': 1,
        'legende': 1,
      });
    });

    test('« dernier » : la semaine n\'est plus en cours si la fenêtre s\'arrête avant', () {
      final d = run(
        aggregation: MetricAggregation.last,
        w: DateWindow(DateTime(2026, 10, 7), DateTime(2026, 10, 26), TimeUnit.day),
      );
      expect(d.total, 360);
      expect(d.latest, (t: DateTime(2026, 10, 19), ongoing: false));
    });

    test('« dernier » : une semaine non publiée est sautée', () {
      final d = externalDataOf(
        MetricUnit.count,
        window,
        points,
        now: now,
        weekly: true,
        aggregation: MetricAggregation.last,
        dataUntil: DateTime(2026, 11, 8),
      ) as CounterData;
      expect(d.total, 519);
      expect(d.latest!.t, DateTime(2026, 11, 2));
    });

    test('« dernier » en jours et en mois', () {
      final days = externalDataOf(
        MetricUnit.count,
        _w,
        [_p(5, 3, 0, 0), _p(6, 8, 0, 0)],
        now: DateTime(2026, 10, 7, 9),
        aggregation: MetricAggregation.last,
      ) as CounterData;
      expect(days.total, 8);
      expect(days.latest, (t: DateTime(2026, 10, 6), ongoing: false));

      final months = externalDataOf(
        MetricUnit.count,
        DateWindow(DateTime(2026, 9, 1), DateTime(2026, 12, 1), TimeUnit.month),
        [
          MetricPoint(t: DateTime(2026, 10), valeur: 40, numerateur: 0, denominateur: 0),
          MetricPoint(t: DateTime(2026, 11), valeur: 12, numerateur: 0, denominateur: 0),
        ],
        now: DateTime(2026, 11, 13),
        aggregation: MetricAggregation.last,
      ) as CounterData;
      // Novembre est en cours : le chiffre est celui d'octobre.
      expect(months.total, 40);
      expect(months.latest, (t: DateTime(2026, 10), ongoing: false));
      expect(months.lastInProgress, isTrue);
    });

    test('un taux ignore l\'agrégation', () {
      final d = externalDataOf(
        MetricUnit.percent,
        window,
        [for (final t in mondays) MetricPoint(t: t, valeur: 50, numerateur: 5, denominateur: 10)],
        now: now,
        weekly: true,
        aggregation: MetricAggregation.last,
      ) as RatioData;
      expect(d.weekly, isTrue);
      expect(d.points.map((p) => p.t), mondays);
      expect(d.denominatorTotal, 60);
      expect(d.overall, closeTo(0.5, 1e-9));
    });

    test('les couleurs du catalogue passent aux parts', () {
      final d = externalDataOf(
        MetricUnit.count,
        window,
        points,
        now: now,
        weekly: true,
        segments: const [
          MetricSegment(
            id: 'legende',
            libelle: 'Légende',
            couleur: Color(0xFF1E3241),
            couleurSombre: Color(0xFF9FB3C8),
          ),
        ],
      ) as CounterData;
      expect(d.segments.single.color, const Color(0xFF1E3241));
      expect(d.segments.single.darkColor, const Color(0xFF9FB3C8));
    });
  });
}
