import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/indicator.dart';
import 'package:glance/data/providers/umami_filters.dart';

EventFilter _f(String p, PropertyType t, FilterOp o, String v) =>
    EventFilter(property: p, type: t, op: o, value: v);

void main() {
  test('texte, nombre et booléen, combinés en ET', () {
    expect(
      umamiEventFilterParams([
        _f('issue', PropertyType.string, FilterOp.eq, 'complet'),
        _f('reussite', PropertyType.number, FilterOp.gte, '80'),
        _f('record', PropertyType.boolean, FilterOp.eq, 'true'),
      ]),
      {
        'epf0': '1.eq.issue.complet',
        'epf1': '2.gte.reussite.80',
        'epf2': '3.eq.record.true',
      },
    );
  });

  test("le point d'un nom de propriété est échappé", () {
    expect(
      umamiEventFilterParams(
          [_f('niveau.max', PropertyType.string, FilterOp.notContains, 'x')]),
      {'epf0': '1.dnc.niveau%2Emax.x'},
    );
  });

  test('nom avec espace encodé, aucun filtre = aucun paramètre', () {
    expect(
      umamiEventFilterParams(
          [_f('mode jeu', PropertyType.string, FilterOp.contains, 'a')]),
      {'epf0': '1.c.mode%20jeu.a'},
    );
    expect(umamiEventFilterParams(const []), isEmpty);
  });
}
