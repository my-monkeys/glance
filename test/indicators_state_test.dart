import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/grid_layout.dart';
import 'package:glance/data/models/indicator.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/models/workspace.dart';
import 'package:glance/state/indicators.dart';
import 'package:glance/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

CounterIndicator _c(String id, [String event = 'e']) =>
    CounterIndicator(id: id, name: id, query: EventQuery(event));

void main() {
  const site = Site(id: 's', accountId: 'a', name: 'S', domain: 's.fr');
  late ProviderContainer c;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    c = ProviderContainer(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
  });

  IndicatorsNotifier n() => c.read(indicatorsProvider.notifier);
  List<String> ids() => c.read(siteIndicatorsProvider(site)).map((i) => i.id).toList();

  test('ajout, mise à jour, déplacement, suppression', () async {
    await n().add(site, _c('1'));
    await n().add(site, _c('2'));
    await n().add(site, _c('3'));
    await n().update(site, _c('2', 'autre'));
    expect((c.read(siteIndicatorsProvider(site))[1] as CounterIndicator).query.event,
        'autre');

    await n().remove(site, '3');
    expect(ids(), ['1', '2']);
  });

  Map<int, Map<String, GridSlot>> layouts() =>
      c.read(siteLayoutsProvider(site));

  test('setLayout : la liste suit l\'ordre de lecture de la grille', () async {
    for (final id in ['1', '2', '3']) {
      await n().add(site, _c(id));
    }
    await n().setLayout(site, 4, {
      '1': const GridSlot(0, 4, 2, 4),
      '2': const GridSlot(2, 0, 2, 4),
      '3': const GridSlot(0, 0, 2, 4),
    });
    expect(ids(), ['3', '2', '1']);
    expect(layouts()[4]!['1'], const GridSlot(0, 4, 2, 4));
  });

  test('chaque largeur de grille garde la sienne ; supprimer en retire la carte',
      () async {
    await n().add(site, _c('1'));
    await n().add(site, _c('2'));
    await n().setLayout(site, 2, {
      '1': const GridSlot(0, 0, 2, 4),
      '2': const GridSlot(0, 4, 2, 4),
    });
    await n().setLayout(site, 6, {
      '1': const GridSlot(0, 0, 2, 4),
      '2': const GridSlot(2, 0, 2, 4),
    });
    await n().update(site, _c('2', 'autre'));
    expect(layouts().keys, unorderedEquals([2, 6]));

    await n().remove(site, '1');
    expect(layouts()[2]!.keys, ['2']);
    expect(layouts()[6]!.keys, ['2']);
  });

  test('la grille voyage en JSON et dans la fusion', () async {
    await n().add(site, _c('1'));
    await n().setLayout(site, 2, {'1': const GridSlot(0, 0, 2, 5)});
    final prefs = c.read(sharedPrefsProvider);
    final back = SiteIndicators.decodeList(prefs.getString('glance.indicators'));
    expect(back.single.layouts[2]!['1'], const GridSlot(0, 0, 2, 5));

    await n().upsertAll([
      SiteIndicators(SiteRef.of(site), [_c('1')], {
        4: {'1': const GridSlot(0, 0, 4, 6)},
      }),
    ]);
    expect(layouts()[2]!['1'], const GridSlot(0, 0, 2, 5));
    expect(layouts()[4]!['1'], const GridSlot(0, 0, 4, 6));
  });

  test('un paquet sans grille (app plus ancienne) se lit', () {
    final s = SiteIndicators.fromJson({
      'site': {'a': 'a', 's': 's'},
      'indicators': [_c('1').toJson()],
    });
    expect(s.layouts, isEmpty);
    expect(s.toJson().containsKey('layouts'), isFalse);
  });

  test('persistance et fusion par id', () async {
    await n().add(site, _c('1'));
    await n().upsertAll([
      SiteIndicators(SiteRef.of(site), [_c('1', 'neuf'), _c('2')]),
    ]);
    expect(ids(), ['1', '2']);
    final prefs = c.read(sharedPrefsProvider);
    final back = SiteIndicators.decodeList(prefs.getString('glance.indicators'));
    expect(back.single.indicators.length, 2);
    expect((back.single.indicators.first as CounterIndicator).query.event, 'neuf');
  });
}
