import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/indicator.dart';
import 'package:glance/data/models/metrics_source.dart';
import 'package:glance/ui/dashboards/editor/draft.dart';

const _issue = EventFilter(
  property: 'issue',
  type: PropertyType.string,
  op: FilterOp.eq,
  value: 'complet',
);

void main() {
  group('aller-retour fromIndicator → toIndicator', () {
    final all = <Indicator>[
      const CounterIndicator(
          id: 'c', name: 'Parties', query: EventQuery('partie', [_issue])),
      const RatioIndicator(
        id: 'r',
        name: 'Complétion',
        numerator: EventQuery('fin', [_issue]),
        denominator: EventQuery('debut'),
      ),
      const RatioIndicator(
        id: 'g',
        name: 'Complétion à trous',
        numerator: EventQuery('fin'),
        denominator: EventQuery('debut'),
        gapsWhenEmpty: true,
      ),
      FunnelIndicator(
        id: 'f',
        name: 'Parcours',
        steps: const [EventQuery('a'), EventQuery('b'), EventQuery('c')],
        windowMinutes: 90,
      ),
      const BreakdownIndicator(
          id: 'b', name: 'Par jeu', event: 'partie', property: 'jeu'),
      const ExternalIndicator(
        id: 'x',
        name: 'Comptes',
        metricId: 'comptes',
        label: 'Comptes',
        unit: MetricUnit.count,
      ),
    ];
    for (final i in all) {
      test(i.kind.name, () {
        expect(IndicatorDraft.fromIndicator(i).toIndicator(i.id), i);
      });
    }
  });

  group('métrique du site', () {
    const d = IndicatorDraft(kind: IndicatorKind.external);

    test('sans métrique : refusé', () {
      expect(d.validationError(), 'Choisissez une métrique');
      expect(d.toIndicator('x'), isNull);
    });

    test('le nom proposé est le libellé du catalogue', () {
      final chosen = d.copyWith(
        metricId: 'r1',
        metricLabel: 'Rétention J1',
        metricUnit: MetricUnit.percent,
      );
      expect(chosen.validationError(), isNull);
      expect(chosen.suggestedName(), 'Rétention J1');
      final i = chosen.toIndicator('i') as ExternalIndicator;
      expect(i.unit, MetricUnit.percent);
    });

    test('changer de genre ne reporte rien depuis ni vers une métrique', () {
      final from = const IndicatorDraft(query: EventQuery('partie'))
          .withKind(IndicatorKind.external);
      expect(from.metricId, isEmpty);
      final to = d.copyWith(metricId: 'r').withKind(IndicatorKind.counter);
      expect(to.query.event, isEmpty);
    });
  });

  group('validationError', () {
    test('compteur sans événement', () {
      expect(const IndicatorDraft().validationError(), 'Choisissez un événement');
    });

    test('taux : numérateur puis dénominateur', () {
      const d = IndicatorDraft(kind: IndicatorKind.ratio);
      expect(d.validationError(), contains('compter'));
      expect(
        d.copyWith(query: const EventQuery('a')).validationError(),
        contains('référence'),
      );
      expect(
        d
            .copyWith(
                query: const EventQuery('a'), denominator: const EventQuery('b'))
            .validationError(),
        isNull,
      );
    });

    test('entonnoir : étapes, événements, délai', () {
      const d = IndicatorDraft(kind: IndicatorKind.funnel);
      expect(d.validationError(), contains('étape 1'));
      expect(
        d.copyWith(steps: const [EventQuery('a')]).validationError(),
        'Un entonnoir compte au moins 2 étapes',
      );
      final ok = d.copyWith(steps: const [EventQuery('a'), EventQuery('b')]);
      expect(ok.validationError(), isNull);
      for (final bad in ['', 'abc', '0', '1441', '1.5']) {
        expect(ok.copyWith(windowText: bad).validationError(), 'Délai invalide',
            reason: bad);
      }
      expect(ok.copyWith(windowText: '1440').validationError(), isNull);
      expect(
        ok
            .copyWith(steps: [for (var i = 0; i < 9; i++) EventQuery('e$i')])
            .validationError(),
        contains('au plus 8'),
      );
    });

    test('entonnoir : un opérateur numérique est refusé', () {
      const gt = EventFilter(
          property: 'n', type: PropertyType.number, op: FilterOp.gt, value: '3');
      final d = IndicatorDraft(
        kind: IndicatorKind.funnel,
        steps: const [EventQuery('a', [gt]), EventQuery('b')],
      );
      expect(d.validationError(), contains('retirez ce filtre'));
      expect(d.toIndicator('x'), isNull);
    });

    test('filtres : valeur manquante, nombre invalide', () {
      const empty = EventFilter(
          property: 'p', type: PropertyType.string, op: FilterOp.eq, value: ' ');
      const nan = EventFilter(
          property: 'n', type: PropertyType.number, op: FilterOp.gt, value: 'x');
      expect(
        const IndicatorDraft(query: EventQuery('a', [empty])).validationError(),
        'Valeur du filtre manquante',
      );
      expect(
        const IndicatorDraft(query: EventQuery('a', [nan])).validationError(),
        'Valeur de filtre non numérique',
      );
    });

    test('répartition : événement puis propriété', () {
      const d = IndicatorDraft(kind: IndicatorKind.breakdown);
      expect(d.validationError(), 'Choisissez un événement');
      expect(d.copyWith(breakdownEvent: 'e').validationError(),
          'Choisissez une propriété');
    });
  });

  group('suggestedName', () {
    test('un nom saisi prime, sinon la suggestion', () {
      const d = IndicatorDraft(query: EventQuery('partie', [_issue]));
      expect(d.suggestedName(), 'partie · issue = complet');
      expect(d.toIndicator('x')!.name, 'partie · issue = complet');
      expect(d.copyWith(name: ' Mes parties ').toIndicator('x')!.name,
          'Mes parties');
    });

    test('un nom par genre', () {
      expect(const IndicatorDraft().suggestedName(), 'Sans titre');
      expect(
        const IndicatorDraft(
          kind: IndicatorKind.ratio,
          query: EventQuery('fin'),
          denominator: EventQuery('debut'),
        ).suggestedName(),
        'fin / debut',
      );
      expect(
        const IndicatorDraft(
          kind: IndicatorKind.funnel,
          steps: [EventQuery('a'), EventQuery('b'), EventQuery('c')],
        ).suggestedName(),
        'a → c',
      );
      expect(
        const IndicatorDraft(
          kind: IndicatorKind.breakdown,
          breakdownEvent: 'partie',
          breakdownProperty: 'jeu',
        ).suggestedName(),
        'partie par jeu',
      );
    });
  });

  group('withKind', () {
    const q = EventQuery('partie', [_issue]);

    test('la requête du compteur devient le numérateur, puis revient', () {
      final ratio = const IndicatorDraft(query: q).withKind(IndicatorKind.ratio);
      expect(ratio.query, q);
      expect(ratio.withKind(IndicatorKind.counter).query, q);
    });

    test('elle devient la première étape, sans écraser une saisie', () {
      final funnel = const IndicatorDraft(query: q).withKind(IndicatorKind.funnel);
      expect(funnel.steps.first, q);
      expect(funnel.steps.length, 2);

      const typed = [EventQuery('x'), EventQuery('y')];
      final kept = const IndicatorDraft(query: q, steps: typed)
          .withKind(IndicatorKind.funnel);
      expect(kept.steps, typed);
    });

    test('l\'entonnoir et la répartition rendent leur événement au compteur', () {
      final f = const IndicatorDraft(
        kind: IndicatorKind.funnel,
        steps: [EventQuery('a'), EventQuery('b')],
      ).withKind(IndicatorKind.counter);
      expect(f.query.event, 'a');

      final b = const IndicatorDraft(
        kind: IndicatorKind.breakdown,
        breakdownEvent: 'e',
      ).withKind(IndicatorKind.counter);
      expect(b.query.event, 'e');
      expect(const IndicatorDraft(query: q).withKind(IndicatorKind.breakdown)
          .breakdownEvent, 'partie');
    });
  });
}
