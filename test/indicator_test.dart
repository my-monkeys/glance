import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/indicator.dart';
import 'package:glance/data/models/metrics_source.dart';
import 'package:glance/data/models/workspace.dart';

void main() {
  const filters = [
    EventFilter(
        property: 'issue',
        type: PropertyType.string,
        op: FilterOp.eq,
        value: 'complet'),
    EventFilter(
        property: 'reussite',
        type: PropertyType.number,
        op: FilterOp.gte,
        value: '80'),
    EventFilter(
        property: 'record',
        type: PropertyType.boolean,
        op: FilterOp.eq,
        value: 'true'),
  ];
  const q = EventQuery('partie', filters);

  final all = <Indicator>[
    const CounterIndicator(id: 'a', name: 'Parties', query: q),
    const RatioIndicator(
        id: 'b', name: 'Complétion', numerator: q, denominator: EventQuery('debut')),
    const RatioIndicator(
        id: 'g',
        name: 'Complétion à trous',
        numerator: q,
        denominator: EventQuery('debut'),
        gapsWhenEmpty: true),
    FunnelIndicator(
        id: 'c',
        name: 'Parcours',
        steps: const [EventQuery('vue'), q],
        windowMinutes: 7),
    const BreakdownIndicator(
        id: 'd', name: 'Niveaux', event: 'partie', property: 'niveau'),
    const BreakdownIndicator(
        id: 'd2',
        name: 'Niveaux dans le temps',
        event: 'partie',
        property: 'niveau',
        overTime: true),
    const ExternalIndicator(
        id: 'e',
        name: 'Rétention J1',
        metricId: 'retention_j1_nouveaux',
        label: 'Rétention J1 · nouveaux joueurs',
        unit: MetricUnit.percent),
  ];

  test('aller-retour JSON de chaque genre', () {
    for (final i in all) {
      final back = Indicator.fromJson(i.toJson());
      expect(back, i, reason: i.kind.name);
      expect(back.hashCode, i.hashCode);
    }
  });

  test('overTime : écrit seulement quand vrai, absent = faux', () {
    const base = BreakdownIndicator(
        id: 'd', name: 'Niveaux', event: 'partie', property: 'niveau');
    expect(base.toJson().containsKey('overTime'), isFalse);
    expect(base.copyWith(overTime: true).toJson()['overTime'], isTrue);
    final back = Indicator.fromJson(base.toJson()) as BreakdownIndicator;
    expect(back.overTime, isFalse);
  });

  test('gaps : écrit seulement quand vrai, absent = faux', () {
    const base = RatioIndicator(
        id: 'r', name: 'T', numerator: q, denominator: EventQuery('debut'));
    expect(base.toJson().containsKey('gaps'), isFalse);
    expect(base.copyWith(gapsWhenEmpty: true).toJson()['gaps'], isTrue);
    final legacy = Indicator.fromJson(base.toJson()) as RatioIndicator;
    expect(legacy.gapsWhenEmpty, isFalse);
  });

  test('kind inconnu : null, et écarté par SiteIndicators', () {
    final unknown = {'id': 'x', 'name': 'Futur', 'kind': 'heatmap'};
    expect(Indicator.fromJson(unknown), isNull);

    final si = SiteIndicators.fromJson({
      'site': const SiteRef('acc', 'site').toJson(),
      'indicators': [all.first.toJson(), unknown],
    });
    expect(si.indicators, [all.first]);
  });

  test('external : clés JSON et unité', () {
    final json = all.last.toJson();
    expect(json['kind'], 'external');
    expect(json['metric'], 'retention_j1_nouveaux');
    expect(json['label'], 'Rétention J1 · nouveaux joueurs');
    expect(json['unit'], 'pourcentage');
  });

  test('liste encodée puis décodée', () {
    final l = [SiteIndicators(const SiteRef('acc', 'site'), all)];
    final back = SiteIndicators.decodeList(SiteIndicators.encodeList(l));
    expect(back.single.site, const SiteRef('acc', 'site'));
    expect(back.single.indicators, all);
    expect(SiteIndicators.decodeList(null), isEmpty);
  });

  test("modifier un filtre change l'égalité", () {
    final base = all.first as CounterIndicator;
    final changed = base.copyWith(
      query: q.copyWith(filters: [
        filters.first,
        EventFilter(
            property: 'reussite',
            type: PropertyType.number,
            op: FilterOp.gte,
            value: '90'),
      ]),
    );
    expect(changed, isNot(base));
    expect(changed.hashCode, isNot(base.hashCode));
    expect(base.copyWith(), base);
  });

  test('opérateurs par type', () {
    expect(FilterOp.forType(PropertyType.boolean), [FilterOp.eq]);
    expect(FilterOp.forType(PropertyType.number), contains(FilterOp.gte));
    expect(FilterOp.forType(PropertyType.string), contains(FilterOp.contains));
  });
}
