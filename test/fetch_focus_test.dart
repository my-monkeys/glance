import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/semaphore.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/models/period.dart';
import 'package:glance/data/providers/analytics_provider.dart';
import 'package:glance/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Site _site(String id) => Site(id: id, accountId: 'a', name: id, domain: '$id.fr');
final _window = DateWindow(DateTime(2026, 11, 1), DateTime(2026, 11, 7), TimeUnit.day);

/// Note l'ordre des requêtes ; la première reste bloquée jusqu'à [release].
class _FakeProvider implements AnalyticsProvider {
  final order = <String>[];
  final _blocker = Completer<void>();

  void release() => _blocker.complete();

  @override
  Future<List<MetricRow>> metric(Site site, DateWindow w, MetricType type,
      {int limit = 8}) async {
    order.add(site.id);
    if (order.length == 1) await _blocker.future;
    return const [];
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
  // Changer de période relançait tous les sites dans l'ordre d'arrivée : le
  // site affiché attendait la barre latérale entière (retour du 2026-11-07).
  test('les requêtes du site affiché passent devant celles des autres sites',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fake = _FakeProvider();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      providerRegistryProvider.overrideWithValue(_Registry(fake)),
      fetchGateProvider.overrideWithValue(Semaphore(1)),
    ]);
    addTearDown(c.dispose);
    c.read(fetchFocusProvider).site = _site('affiché');

    final keys = [
      for (final id in ['autre 1', 'autre 2', 'autre 3', 'affiché'])
        (_site(id), _window, MetricType.pages),
    ];
    for (final k in keys) {
      c.listen(siteMetricProvider(k), (_, _) {});
      await Future<void>.delayed(Duration.zero);
    }
    fake.release();
    await Future.wait([for (final k in keys) c.read(siteMetricProvider(k).future)]);

    expect(fake.order, ['autre 1', 'affiché', 'autre 2', 'autre 3']);
  });
}
