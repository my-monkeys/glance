import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/indicator.dart';
import 'package:glance/data/models/indicator_result.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/models/period.dart';
import 'package:glance/data/providers/analytics_provider.dart';
import 'package:glance/state/indicators.dart';
import 'package:glance/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _site = Site(id: 's', accountId: 'a', name: 'S', domain: 's.fr');
final _window = DateWindow(DateTime(2026, 7, 1), DateTime(2026, 7, 4), TimeUnit.day);

/// Fournisseur sans réseau : 10 valeurs de propriété, et il note les requêtes.
class _FakeProvider implements AnalyticsProvider {
  final queries = <EventQuery>[];
  var propertyCalls = 0;

  @override
  Future<List<MetricRow>> propertyValues(Site site, DateWindow w, String event,
      String property, {int limit = 30}) async {
    propertyCalls++;
    return [for (var i = 0; i < 10; i++) MetricRow(label: 'jeu$i', value: 10 - i)];
  }

  @override
  Future<List<EventProperty>> eventProperties(
          Site site, DateWindow w, String event) async =>
      const [EventProperty('niveau', PropertyType.number)];

  @override
  Future<List<SeriesPoint>> eventCountSeries(
      Site site, DateWindow w, EventQuery q) async {
    queries.add(q);
    return [
      SeriesPoint(DateTime(2026, 7, 1), 2, 0),
      SeriesPoint(DateTime(2026, 7, 2), 3, 0),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Registry implements ProviderRegistry {
  _Registry(this.provider);
  final AnalyticsProvider provider;

  @override
  Future<AnalyticsProvider> forAccount(String id) async => provider;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeProvider fake;
  late ProviderContainer c;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    fake = _FakeProvider();
    c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      providerRegistryProvider.overrideWithValue(_Registry(fake)),
    ]);
    addTearDown(c.dispose);
  });

  Future<BreakdownData> load(BreakdownIndicator i) async =>
      await c.read(indicatorDataProvider((_site, _window, i)).future)
          as BreakdownData;

  test('overTime : une série par valeur (8 max), filtre eq typé', () async {
    final d = await load(const BreakdownIndicator(
        id: 'b', name: 'n', event: 'partie', property: 'jeu', overTime: true));
    expect(d.series!.map((s) => s.name), [for (var i = 0; i < 8; i++) 'jeu$i']);
    expect(d.series!.first.total, 5);
    expect(fake.queries, hasLength(8));
    for (final q in fake.queries) {
      expect(q.event, 'partie');
      final f = q.filters.single;
      expect((f.property, f.op), ('jeu', FilterOp.eq));
      // Propriété inconnue du fournisseur : texte.
      expect(f.type, PropertyType.string);
    }
    expect(fake.queries.map((q) => q.filters.single.value).toList(),
        [for (var i = 0; i < 8; i++) 'jeu$i']);
  });

  test('overTime : le type de la propriété vient du fournisseur', () async {
    await load(const BreakdownIndicator(
        id: 'b', name: 'n', event: 'partie', property: 'niveau', overTime: true));
    expect(fake.queries.first.filters.single.type, PropertyType.number);
  });

  test('sans overTime : aucune requête de plus', () async {
    final d = await load(const BreakdownIndicator(
        id: 'b', name: 'n', event: 'partie', property: 'jeu'));
    expect(d.series, isNull);
    expect(fake.queries, isEmpty);
  });
}
