import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/indicator.dart';
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
    FunnelIndicator(
        id: 'c',
        name: 'Parcours',
        steps: const [EventQuery('vue'), q],
        windowMinutes: 7),
    const BreakdownIndicator(
        id: 'd', name: 'Niveaux', event: 'partie', property: 'niveau'),
  ];

  test('aller-retour JSON de chaque genre', () {
    for (final i in all) {
      final back = Indicator.fromJson(i.toJson());
      expect(back, i, reason: i.kind.name);
      expect(back.hashCode, i.hashCode);
    }
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
