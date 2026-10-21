import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

    await n().reorder(site, 0, 3); // convention onReorder : 1 passe en dernier
    expect(ids(), ['2', '3', '1']);
    await n().remove(site, '3');
    expect(ids(), ['2', '1']);
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
