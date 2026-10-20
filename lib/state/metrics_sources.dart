import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/metrics_source.dart';
import '../data/models/models.dart';
import '../data/models/workspace.dart';
import '../data/providers/metrics_api.dart';
import 'providers.dart';

/// Les sources d'agrégats par site. Les URL sont persistées en clair ; le
/// jeton, lui, ne quitte jamais le secure storage.
class MetricsSourcesNotifier extends Notifier<List<MetricsSource>> {
  static const _key = 'glance.metricsSources';
  static const _tokenPrefix = 'glance.metricsToken.';

  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  @override
  List<MetricsSource> build() =>
      MetricsSource.decodeList(_p.getString(_key));

  static String _tokenKey(SiteRef s) => '$_tokenPrefix${s.accountId}.${s.siteId}';

  Future<void> _save(List<MetricsSource> next) async {
    await _p.setString(_key, MetricsSource.encodeList(next));
    state = next;
  }

  MetricsSource? sourceFor(Site site) {
    for (final s in state) {
      if (s.site.matches(site)) return s;
    }
    return null;
  }

  Future<String?> tokenFor(SiteRef site) =>
      ref.read(secureStorageProvider).read(key: _tokenKey(site));

  /// Crée ou remplace la source d'un site. Le jeton est écrit avant la liste :
  /// une source sans jeton ne doit jamais être visible.
  Future<void> set(Site site, String baseUrl, String token) async {
    final src = MetricsSource(site: SiteRef.of(site), baseUrl: baseUrl.trim());
    await ref
        .read(secureStorageProvider)
        .write(key: _tokenKey(src.site), value: token.trim());
    await _save([...state.where((s) => s.site != src.site), src]);
  }

  Future<void> remove(Site site) async {
    final target = SiteRef.of(site);
    await ref.read(secureStorageProvider).delete(key: _tokenKey(target));
    await _save(state.where((s) => s.site != target).toList());
  }

  /// Fusionne des sources venues d'un autre appareil : par site, l'entrante
  /// gagne. Une suppression ne se propage pas (comme les tableaux).
  Future<void> upsertAll(List<SyncedMetricsSource> incoming) async {
    if (incoming.isEmpty) return;
    final secure = ref.read(secureStorageProvider);
    for (final i in incoming) {
      await secure.write(key: _tokenKey(i.source.site), value: i.token);
    }
    final sites = {for (final i in incoming) i.source.site};
    await _save([
      ...state.where((s) => !sites.contains(s.site)),
      for (final i in incoming) i.source,
    ]);
  }

  /// Les sources avec leur jeton, pour la synchro. Une source dont le jeton a
  /// disparu du trousseau est écartée : elle ne servirait à rien ailleurs.
  Future<List<SyncedMetricsSource>> withTokens() async {
    final out = <SyncedMetricsSource>[];
    for (final s in state) {
      final t = await tokenFor(s.site);
      if (t != null && t.isNotEmpty) out.add(SyncedMetricsSource(s, t));
    }
    return out;
  }
}

final metricsSourcesProvider =
    NotifierProvider<MetricsSourcesNotifier, List<MetricsSource>>(
  MetricsSourcesNotifier.new,
);

/// Vrai si le site a une source : décide de l'onglet Tableaux, de façon
/// synchrone.
final siteHasMetricsSourceProvider = Provider.family<bool, Site>(
  (ref, site) => ref.watch(
    metricsSourcesProvider.select((all) => all.any((s) => s.site.matches(site))),
  ),
);

/// Une réponse claire de la source (jeton refusé, non configurée…) ne se
/// rattrape pas en réessayant : l'erreur doit apparaître tout de suite, pas
/// après les relances par défaut de Riverpod.
Duration? retryUnlessMetricsError(int count, Object error) =>
    error is MetricsApiException
        ? null
        : ProviderContainer.defaultRetry(count, error);

/// Fabrique du client, substituable dans les tests (et sert à « Tester » une
/// source qui n'est pas encore enregistrée).
final metricsApiFactoryProvider =
    Provider<MetricsApi Function(String baseUrl, String token)>(
  (ref) => (url, token) => MetricsApi(baseUrl: url, token: token, dio: Dio()),
);

/// Le client du site, ou une erreur si le jeton manque.
Future<MetricsApi> metricsApiFor(Ref ref, Site site) async {
  final notifier = ref.read(metricsSourcesProvider.notifier);
  final source = notifier.sourceFor(site);
  final token = source == null ? null : await notifier.tokenFor(source.site);
  if (source == null || token == null || token.isEmpty) {
    throw const MetricsBadToken();
  }
  return ref.read(metricsApiFactoryProvider)(source.baseUrl, token);
}

/// Catalogue d'indicateurs d'un site. Même cache que les aides de l'éditeur.
final metricsCatalogueProvider =
    FutureProvider.autoDispose.family<List<MetricDef>, Site>(
  retry: retryUnlessMetricsError,
  (ref, site) async {
    cacheFor(ref, const Duration(minutes: 10));
    final gate = ref.watch(fetchGateProvider);
    final api = await metricsApiFor(ref, site);
    return gate.run(api.catalogue);
  },
);
