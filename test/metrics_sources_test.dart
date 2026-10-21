import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/metrics_source.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/models/workspace.dart';
import 'package:glance/state/metrics_sources.dart';
import 'package:glance/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _site = Site(id: 's', accountId: 'a', name: 'S', domain: 's.fr');
const _ref = SiteRef('a', 's');
const _tokenKey = 'glance.metricsToken.a.s';

Future<(ProviderContainer, SharedPreferences)> _container() async {
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
  ]);
  addTearDown(c.dispose);
  return (c, prefs);
}

void main() {
  test('MetricsSource : aller-retour JSON', () {
    const s = MetricsSource(site: _ref, baseUrl: 'https://x.eu/api/');
    expect(MetricsSource.decodeList(MetricsSource.encodeList([s])), [s]);
    expect(MetricsSource.decodeList(null), isEmpty);
  });

  test('set : URL en prefs, jeton dans le secure storage seulement', () async {
    final (c, prefs) = await _container();
    final n = c.read(metricsSourcesProvider.notifier);
    await n.set(_site, ' https://x.eu/api/ ', ' sekret ');

    expect(n.sourceFor(_site)!.baseUrl, 'https://x.eu/api/');
    expect(c.read(siteHasMetricsSourceProvider(_site)), isTrue);
    expect(await n.tokenFor(_ref), 'sekret');
    expect(prefs.getString('glance.metricsSources'), isNot(contains('sekret')));
    expect(
      await const FlutterSecureStorage().read(key: _tokenKey),
      'sekret',
    );
  });

  test('set sur un site déjà configuré remplace, sans doublon', () async {
    final (c, _) = await _container();
    final n = c.read(metricsSourcesProvider.notifier);
    await n.set(_site, 'https://a.eu/', 't1');
    await n.set(_site, 'https://b.eu/', 't2');

    expect(c.read(metricsSourcesProvider), hasLength(1));
    expect(n.sourceFor(_site)!.baseUrl, 'https://b.eu/');
    expect(await n.tokenFor(_ref), 't2');
  });

  test('remove efface aussi le jeton', () async {
    final (c, _) = await _container();
    final n = c.read(metricsSourcesProvider.notifier);
    await n.set(_site, 'https://x.eu/', 't');
    await n.remove(_site);

    expect(n.sourceFor(_site), isNull);
    expect(c.read(siteHasMetricsSourceProvider(_site)), isFalse);
    expect(await n.tokenFor(_ref), isNull);
  });

  test('upsertAll écrit les jetons ; withTokens les relit', () async {
    final (c, _) = await _container();
    final n = c.read(metricsSourcesProvider.notifier);
    const incoming = SyncedMetricsSource(
      MetricsSource(site: _ref, baseUrl: 'https://x.eu/'),
      'tok',
    );
    await n.upsertAll([incoming]);

    expect(await n.tokenFor(_ref), 'tok');
    expect(await n.withTokens(), [incoming]);
  });

  test('withTokens écarte une source dont le jeton a disparu', () async {
    final (c, _) = await _container();
    final n = c.read(metricsSourcesProvider.notifier);
    await n.set(_site, 'https://x.eu/', 't');
    await const FlutterSecureStorage().delete(key: _tokenKey);

    expect(await n.withTokens(), isEmpty);
  });
}
