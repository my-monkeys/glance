import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/account.dart';
import '../data/models/models.dart';
import '../data/models/period.dart';
import '../data/providers/analytics_provider.dart';
import '../data/providers/provider_factory.dart';
import '../data/repository/accounts_repository.dart';
import '../core/semaphore.dart';
import 'home_data.dart';

/// Injecté au démarrage (voir main.dart).
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override in main'),
);

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  ),
);

final accountsRepoProvider = Provider<AccountsRepository>(
  (ref) => AccountsRepository(
    ref.watch(sharedPrefsProvider),
    ref.watch(secureStorageProvider),
  ),
);

/// Liste des comptes configurés (source de vérité en mémoire).
class AccountsNotifier extends Notifier<List<Account>> {
  AccountsRepository get _repo => ref.read(accountsRepoProvider);

  @override
  List<Account> build() => _repo.loadAccounts();

  Future<void> add(Account account, Map<String, String> creds) async {
    await _repo.addAccount(account, creds);
    state = _repo.loadAccounts();
  }

  Future<void> updateSites(String accountId, List<String>? sites) async {
    final account = state.firstWhere((a) => a.id == accountId);
    await _repo.updateAccount(account.copyWith(sites: sites, allSites: sites == null));
    state = _repo.loadAccounts();
  }

  Future<void> remove(String id) async {
    await _repo.removeAccount(id);
    state = _repo.loadAccounts();
  }

  Future<void> clear() async {
    await _repo.clear();
    state = const [];
  }
}

final accountsProvider =
    NotifierProvider<AccountsNotifier, List<Account>>(AccountsNotifier.new);

/// Cache les instances de provider par compte (le token Umami y est réutilisé).
/// Rebuild à chaque changement de la liste de comptes → cache remis à neuf.
class ProviderRegistry {
  ProviderRegistry(this._repo, this._accounts);

  final AccountsRepository _repo;
  final List<Account> _accounts;
  final Map<String, Future<AnalyticsProvider>> _cache = {};

  Future<AnalyticsProvider> forAccount(String id) {
    return _cache.putIfAbsent(id, () async {
      final account = _accounts.firstWhere((a) => a.id == id);
      final creds = await _repo.credentials(id);
      return buildProvider(account, creds);
    });
  }
}

final providerRegistryProvider = Provider<ProviderRegistry>((ref) {
  return ProviderRegistry(
    ref.watch(accountsRepoProvider),
    ref.watch(accountsProvider),
  );
});

/// Sites affichés = sites de chaque compte filtrés par sa sélection.
final sitesProvider = FutureProvider<List<Site>>((ref) async {
  final accounts = ref.watch(accountsProvider);
  final reg = ref.watch(providerRegistryProvider);
  final all = <Site>[];
  for (final a in accounts) {
    final p = await reg.forAccount(a.id);
    final sites = await p.listSites();
    all.addAll(sites.where((s) => a.includesSite(s.id)));
  }
  return all;
});

/// Tous les sites d'un compte (pour l'écran de sélection), sans filtre.
final accountSitesProvider =
    FutureProvider.family<List<Site>, String>((ref, accountId) async {
  final reg = ref.watch(providerRegistryProvider);
  final p = await reg.forAccount(accountId);
  return p.listSites();
});

Future<AnalyticsProvider> _providerFor(Ref ref, Site site) =>
    ref.read(providerRegistryProvider).forAccount(site.accountId);

/// Plafonne la concurrence des requêtes analytics (chargement incrémental).
final fetchGateProvider = Provider<Semaphore>((ref) => Semaphore(6));

/// Visiteurs en direct d'un site (indépendant de la période sélectionnée).
final siteLiveProvider = FutureProvider.autoDispose.family<int, Site>((ref, site) async {
  final gate = ref.watch(fetchGateProvider);
  final p = await _providerFor(ref, site);
  return gate.run(() => p.active(site)).catchError((_) => 0);
});

/// Stats (résumé + série) d'un site sur une fenêtre. Chargé indépendamment des
/// autres sites → chaque carte apparaît dès que SA donnée arrive.
final siteStatsProvider =
    FutureProvider.autoDispose.family<SiteStats, (Site, DateWindow)>((ref, key) async {
  final (site, w) = key;
  final gate = ref.watch(fetchGateProvider);
  final p = await _providerFor(ref, site);
  return gate.run(() async {
    final r = await Future.wait([p.summary(site, w), p.series(site, w)]);
    return SiteStats(
      summary: r[0] as StatsSummary,
      series: r[1] as List<SeriesPoint>,
    );
  });
});

/// Agrégat vivant de la home : recalculé à chaque site qui se charge (watch de
/// tous les providers par site). Fournit les totaux sur les sites déjà chargés.
final homeTotalsProvider =
    Provider.autoDispose.family<HomeTotals, DateWindow>((ref, w) {
  final sitesAsync = ref.watch(sitesProvider);
  final sites = sitesAsync.value ?? const <Site>[];
  final cards = <SiteCard>[];
  var pending = 0;
  var loading = sitesAsync.isLoading;

  for (final s in sites) {
    final stats = ref.watch(siteStatsProvider((s, w)));
    final live = ref.watch(siteLiveProvider(s));
    if (stats.isLoading || live.isLoading) loading = true;
    final sv = stats.value;
    if (sv != null) {
      cards.add(SiteCard(
        site: s,
        summary: sv.summary,
        series: sv.series,
        live: live.value ?? 0,
      ));
    } else {
      pending++;
    }
  }

  return HomeTotals(
    data: HomeData.fromCards(cards),
    pending: pending,
    siteCount: sites.length,
    loading: loading,
  );
});

/// Détail complet d'un site (tout en parallèle).
final detailProvider =
    FutureProvider.family<SiteDetail, (Site, DateWindow)>((ref, key) async {
  final (site, w) = key;
  final p = await _providerFor(ref, site);
  final r = await Future.wait([
    p.summary(site, w),
    p.series(site, w),
    p.metric(site, w, MetricType.pages, limit: 6),
    p.metric(site, w, MetricType.sources, limit: 6),
    p.metric(site, w, MetricType.countries, limit: 6),
    p.active(site).catchError((_) => 0),
    p.livePages(site).catchError((_) => <LivePage>[]),
  ]);
  return SiteDetail(
    summary: r[0] as StatsSummary,
    series: r[1] as List<SeriesPoint>,
    unit: w.unit.api,
    topPages: r[2] as List<MetricRow>,
    sources: r[3] as List<MetricRow>,
    countries: r[4] as List<MetricRow>,
    live: r[5] as int,
    livePages: r[6] as List<LivePage>,
  );
});

/// Données d'événements d'un site pour une fenêtre (série + répartition).
final eventsProvider =
    FutureProvider.autoDispose.family<EventsData, (Site, DateWindow)>((ref, key) async {
  final (site, w) = key;
  final gate = ref.watch(fetchGateProvider);
  final p = await _providerFor(ref, site);
  return gate.run(() async {
    final series = await p.eventSeries(site, w);
    final total = series.fold<int>(0, (a, b) => a + b.total);
    return EventsData(total: total, series: series, unit: w.unit.api);
  });
});

/// Un site a-t-il des événements ? Vérifié sur ~30 jours (indépendant de la
/// période sélectionnée) → visibilité stable de l'onglet Événements.
final siteHasEventsProvider =
    FutureProvider.autoDispose.family<bool, Site>((ref, site) async {
  final gate = ref.watch(fetchGateProvider);
  final p = await _providerFor(ref, site);
  final w = Period.d30.window();
  final rows = await gate
      .run(() => p.metric(site, w, MetricType.events, limit: 1))
      .catchError((_) => <MetricRow>[]);
  return rows.isNotEmpty;
});
