import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/account.dart';
import '../data/models/models.dart';
import 'package:dio/dio.dart';

import '../data/models/period.dart';
import '../data/providers/analytics_provider.dart';
import '../data/providers/provider_factory.dart';
import '../data/providers/umami_provider.dart';
import '../data/repository/accounts_repository.dart';
import '../data/favicon_cache.dart';
import '../data/stats_cache.dart';
import '../core/predict.dart';
import '../core/semaphore.dart';
import 'home_data.dart';
import 'workspaces.dart';

/// Garde le résultat d'un provider autoDispose en cache pendant [duration] après
/// le départ du dernier auditeur : au retour sur un écran on réaffiche la donnée
/// mise en cache instantanément (le refresh en fond met à jour ensuite), au lieu
/// de tout refetcher/réafficher. Passé ce délai sans auditeur, le cache est
/// libéré (pas de fuite mémoire).
void cacheFor(Ref ref, Duration duration) {
  final link = ref.keepAlive();
  Timer? timer;
  ref.onCancel(() {
    timer?.cancel();
    timer = Timer(duration, link.close);
  });
  ref.onResume(() => timer?.cancel());
  ref.onDispose(() => timer?.cancel());
}

/// Garde le résultat en cache pour TOUTE la session : une fois une période
/// chargée pour un site, y revenir (ou rebasculer sur cette période) l'affiche
/// instantanément — plus de squelette ni de blanc. La fraîcheur est assurée par
/// les refresh, ciblés sur la seule fenêtre courante, qui mettent à jour les
/// valeurs en place. Les autres périodes restent servies depuis le cache.
void cacheSession(Ref ref) => ref.keepAlive();

const _cacheTtl = Duration(minutes: 3);

/// Injecté au démarrage (voir main.dart).
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override in main'),
);

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    // macOS : trousseau fichier legacy (pas le « data protection keychain »),
    // qui n'exige PAS l'entitlement keychain-access-groups → signature ad-hoc OK
    // pour une app distribuée hors Mac App Store (cf. entitlements macOS).
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock,
      usesDataProtectionKeychain: false,
    ),
  ),
);

/// Cache disque des stats (résumé/série/métriques) pour un affichage instantané
/// au démarrage à froid. Une seule instance pour l'app.
final statsCacheProvider =
    Provider<StatsCache>((ref) => StatsCache(ref.watch(sharedPrefsProvider)));

/// Dernières stats connues (persistées) d'un site pour une fenêtre, lues de
/// façon synchrone → seed des cartes de l'accueil avant la réponse réseau. Null
/// si rien en cache ou trop ancien.
final cachedStatsProvider =
    Provider.autoDispose.family<SiteStats?, (Site, DateWindow)>((ref, key) {
  final (site, w) = key;
  return ref.watch(statsCacheProvider).readStats(site, w);
});

/// Dernières lignes connues (persistées) d'une dimension, lues de façon
/// synchrone → les cartes de données s'affichent au démarrage à froid sans
/// attendre le réseau.
final cachedMetricProvider = Provider.autoDispose
    .family<List<MetricRow>?, (Site, DateWindow, MetricType)>((ref, key) {
  final (site, w, type) = key;
  return ref.watch(statsCacheProvider).readMetric(site, w, type);
});

/// Cache de favicons (mémoire + disque). Une seule instance pour l'app.
final faviconCacheProvider = Provider<FaviconCache>((ref) {
  return FaviconCache(Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    headers: const {'user-agent': 'GlanceApp/1.0'},
  )));
});

/// Favicon d'un domaine (null si introuvable). Gardé longtemps en cache.
final faviconProvider =
    FutureProvider.autoDispose.family<Favicon?, String>((ref, domain) async {
  cacheFor(ref, const Duration(minutes: 30));
  if (domain.trim().isEmpty) return null;
  return ref.watch(faviconCacheProvider).get(domain.trim());
});

/// Plafond propre aux icônes. Une carte de données peut en demander quarante
/// d'un coup : sans plafond dédié, elles entreraient en concurrence avec les
/// requêtes de statistiques — l'inverse du but recherché.
final iconGateProvider = Provider<Semaphore>((ref) => Semaphore(4));

/// Icône dont l'URL est connue d'avance (favicon d'un domaine référent, logo
/// de navigateur ou de système servi par une instance Umami).
final iconProvider = FutureProvider.autoDispose
    .family<Favicon?, ({String cacheKey, String url})>((ref, src) async {
  cacheFor(ref, const Duration(minutes: 30));
  final gate = ref.watch(iconGateProvider);
  return gate.run(
    () => ref.watch(faviconCacheProvider).fromUrl(src.cacheKey, src.url),
  );
});

/// Origine de l'instance Umami d'un compte (`https://hôte`), null pour les
/// autres fournisseurs. Normalisée : l'URL peut avoir été saisie sans schéma.
final instanceBaseProvider = Provider.family<String?, String>((ref, accountId) {
  for (final a in ref.watch(accountsProvider)) {
    if (a.id != accountId) continue;
    return a.kind == ProviderKind.umami
        ? UmamiProvider.normalizeBase(a.baseUrl)
        : null;
  }
  return null;
});

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

  /// Fusionne des comptes venus d'un autre appareil. Les ids sont conservés →
  /// réimporter le même transfert remplace au lieu de dupliquer.
  Future<void> import(
    List<Account> accounts,
    Map<String, Map<String, String>> credentials,
  ) async {
    for (final a in accounts) {
      await _repo.addAccount(a, credentials[a.id] ?? const {});
    }
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

/// Périmètre suivi = sites de chaque compte filtrés par sa sélection. C'est ce
/// que Glance va chercher ; ce qui est *affiché* passe encore par le groupe
/// actif (cf. `visibleSitesProvider`).
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

/// Santé d'un compte (auth valide ?) pour signaler un souci dans les réglages.
/// Diagnostic léger, mis en cache : recalculé au retour sur l'écran passé le TTL.
final accountHealthProvider =
    FutureProvider.autoDispose.family<AccountHealth, String>((ref, accountId) async {
  cacheFor(ref, _cacheTtl);
  final reg = ref.watch(providerRegistryProvider);
  final p = await reg.forAccount(accountId);
  return p.health();
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

String _dataStartKey(Site s) => 'glance.dataStart.${s.accountId}.${s.id}';

/// Date de première donnée d'un site, telle que la donne le fournisseur.
/// Persistée : au lancement suivant, « Tout » s'ouvre sans attendre le réseau.
/// Null quand le fournisseur ne sait pas répondre (Plausible, Fathom).
final siteDataStartProvider =
    FutureProvider.family<DateTime?, Site>((ref, site) async {
  // Une résolution par session : la date de naissance d'un site ne bouge pas.
  ref.keepAlive();
  final gate = ref.watch(fetchGateProvider);
  final p = await _providerFor(ref, site);
  final range = await gate.run(() => p.dataRange(site)).catchError((_) => null);
  if (range == null) return null;
  ref
      .read(sharedPrefsProvider)
      .setInt(_dataStartKey(site), range.start.millisecondsSinceEpoch);
  return range.start;
});

/// Début de l'historique commun aux sites affichés, pour la période « Tout ».
///
/// Tout-ou-rien : tant qu'un site n'a pas répondu, on ne propose pas de borne.
/// Une borne qui reculerait à chaque réponse ferait repartir, à chaque fois,
/// une vague de requêtes sur une fenêtre différente.
///
/// La fenêtre est **commune à tous les sites** parce que l'accueil additionne
/// les séries bucket par bucket (`HomeData.fromCards`) : des fenêtres
/// différentes y feraient additionner 2019 avec 2024.
final allTimeStartProvider = Provider<DateTime?>((ref) {
  final sitesAsync = ref.watch(visibleSitesProvider);
  final sites = sitesAsync.value;
  if (sites == null) return null;
  if (sites.isEmpty) return DateTime.now();

  final prefs = ref.watch(sharedPrefsProvider);
  DateTime? min;
  var known = 0;
  for (final s in sites) {
    final cached = prefs.getInt(_dataStartKey(s));
    final resolved = ref.watch(siteDataStartProvider(s));
    // Le fournisseur ne sait pas dater ses données : on n'attend pas après lui,
    // le cadrage large et le rognage à l'affichage prennent le relais.
    if (resolved.hasValue && resolved.value == null) {
      known++;
      continue;
    }
    final ms = resolved.value?.millisecondsSinceEpoch ?? cached;
    if (ms == null) continue;
    known++;
    final t = DateTime.fromMillisecondsSinceEpoch(ms);
    if (min == null || t.isBefore(min)) min = t;
  }
  if (known < sites.length) return null;
  return min ?? DateTime.now().subtract(const Duration(days: 3650));
});

/// Visiteurs en direct d'un site (indépendant de la période sélectionnée).
final siteLiveProvider = FutureProvider.autoDispose.family<int, Site>((ref, site) async {
  cacheFor(ref, _cacheTtl);
  final gate = ref.watch(fetchGateProvider);
  final p = await _providerFor(ref, site);
  return gate.run(() => p.active(site)).catchError((_) => 0);
});

/// Stats (résumé + série) d'un site sur une fenêtre. Chargé indépendamment des
/// autres sites → chaque carte apparaît dès que SA donnée arrive.
final siteStatsProvider =
    FutureProvider.autoDispose.family<SiteStats, (Site, DateWindow)>((ref, key) async {
  cacheSession(ref);
  final (site, w) = key;
  final gate = ref.watch(fetchGateProvider);
  final p = await _providerFor(ref, site);
  // Série de la période précédente équivalente quand la fenêtre permet une
  // prévision profilée (aujourd'hui / ce mois-ci / cette année). Best-effort :
  // un échec ne bloque pas les stats (la prévision retombe sur le rythme moyen).
  final refW = forecastReferenceWindow(w);
  return gate.run(() async {
    final r = await Future.wait([
      p.summary(site, w),
      p.series(site, w),
      if (refW != null)
        p.series(site, refW).catchError((_) => <SeriesPoint>[]),
    ]);
    final stats = SiteStats(
      summary: r[0] as StatsSummary,
      series: r[1] as List<SeriesPoint>,
      refSeries: refW == null ? null : r[2] as List<SeriesPoint>,
    );
    ref.read(statsCacheProvider).writeStats(site, w, stats);
    return stats;
  });
});

/// Série de la période précédente équivalente, pour la comparaison superposée
/// sur le graphique (bascule « Comparer »). Fetch distinct de `refSeries`
/// (qui sert au profilage de la prévision, toujours calculée pour les 3
/// périodes calendaires) : celui-ci n'est déclenché que si l'appelant le
/// demande explicitement (watch conditionnel, cf. [homeTotalsProvider]).
final siteCompareSeriesProvider = FutureProvider.autoDispose
    .family<List<SeriesPoint>?, (Site, DateWindow)>((ref, key) async {
  cacheSession(ref);
  final (site, w) = key;
  final prevW = previousPeriodWindow(w);
  if (prevW == null) return null;
  final gate = ref.watch(fetchGateProvider);
  final p = await _providerFor(ref, site);
  return gate
      .run(() => p.series(site, prevW))
      .catchError((_) => <SeriesPoint>[]);
});

/// Agrégat vivant de la home : recalculé à chaque site qui se charge (watch de
/// tous les providers par site). Fournit les totaux sur les sites déjà chargés.
///
/// Porté par le **groupe actif** : les totaux, la courbe et les cartes ne
/// comptent que ses sites. « Tous » = le périmètre entier. [compare] déclenche
/// en plus, par site, le fetch de la période précédente (cf.
/// [siteCompareSeriesProvider]) — pas de coût quand la comparaison est
/// désactivée.
final homeTotalsProvider =
    Provider.autoDispose.family<HomeTotals, (DateWindow, bool)>((ref, key) {
  final (w, compare) = key;
  final sitesAsync = ref.watch(visibleSitesProvider);
  final sites = sitesAsync.value ?? const <Site>[];
  final cards = <SiteCard>[];
  var pending = 0;
  var loading = sitesAsync.isLoading;

  for (final s in sites) {
    final stats = ref.watch(siteStatsProvider((s, w)));
    final live = ref.watch(siteLiveProvider(s));
    final cmp = compare ? ref.watch(siteCompareSeriesProvider((s, w))) : null;
    if (stats.isLoading || live.isLoading) loading = true;
    // Seed depuis le cache disque au démarrage à froid : la carte s'affiche
    // avec la dernière valeur connue au lieu d'un squelette, le refresh corrige.
    final sv = stats.value ?? ref.watch(cachedStatsProvider((s, w)));
    if (sv != null) {
      cards.add(SiteCard(
        site: s,
        summary: sv.summary,
        series: sv.series,
        live: live.value ?? 0,
        refSeries: sv.refSeries,
        compareSeries: cmp?.value,
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

/// Nombre de lignes demandées par dimension : on en affiche huit, on garde de
/// quoi ouvrir « Voir tout » sans repasser par le réseau.
const kMetricFetchLimit = 30;

/// Lignes d'une dimension pour un site et une fenêtre. Une carte de données =
/// un provider : changer de sous-dimension ne recharge que celle-là.
///
/// `cacheFor` et non `cacheSession` : avec seize dimensions et neuf périodes,
/// un keepAlive sans limite retiendrait tout ce qui a été feuilleté dans la
/// session, et un rafraîchissement de famille entière relancerait des dizaines
/// de requêtes.
final siteMetricProvider = FutureProvider.autoDispose
    .family<List<MetricRow>, (Site, DateWindow, MetricType)>((ref, key) async {
  cacheFor(ref, _cacheTtl);
  final (site, w, type) = key;
  final gate = ref.watch(fetchGateProvider);
  final p = await _providerFor(ref, site);
  final rows =
      await gate.run(() => p.metric(site, w, type, limit: kMetricFetchLimit));
  ref.read(statsCacheProvider).writeMetric(site, w, type, rows);
  return rows;
});

/// Pages consultées dans les dernières minutes (indépendant de la période).
final siteLivePagesProvider =
    FutureProvider.autoDispose.family<List<LivePage>, Site>((ref, site) async {
  cacheFor(ref, _cacheTtl);
  final gate = ref.watch(fetchGateProvider);
  final p = await _providerFor(ref, site);
  return gate.run(() => p.livePages(site)).catchError((_) => <LivePage>[]);
});

/// Données d'événements d'un site pour une fenêtre (série + répartition).
final eventsProvider =
    FutureProvider.autoDispose.family<EventsData, (Site, DateWindow)>((ref, key) async {
  cacheSession(ref);
  final (site, w) = key;
  final gate = ref.watch(fetchGateProvider);
  final p = await _providerFor(ref, site);
  return gate.run(() async {
    final series = await p.eventSeries(site, w);
    final total = series.fold<int>(0, (a, b) => a + b.total);
    return EventsData(total: total, series: series, unit: w.unit);
  });
});

/// Clé de persistance du flag « ce site a des événements ».
String _hasEventsKey(Site s) => 'glance.hasEvents.${s.accountId}.${s.id}';

/// Dernière réponse connue (persistée) de [siteHasEventsProvider], lue de façon
/// synchrone. Sert à décider l'affichage de l'onglet Événements dès l'ouverture
/// du site, avant la réponse réseau → pas de décalage de mise en page. Null tant
/// qu'un site n'a jamais été vérifié.
final siteHasEventsCachedProvider = Provider.autoDispose.family<bool?, Site>(
  (ref, site) => ref.watch(sharedPrefsProvider).getBool(_hasEventsKey(site)),
);

/// Un site a-t-il des événements ? Vérifié sur ~30 jours (indépendant de la
/// période sélectionnée) → visibilité stable de l'onglet Événements. Le résultat
/// est persisté pour un affichage instantané et sans décalage à la réouverture.
final siteHasEventsProvider =
    FutureProvider.autoDispose.family<bool, Site>((ref, site) async {
  cacheFor(ref, const Duration(minutes: 10));
  final gate = ref.watch(fetchGateProvider);
  final p = await _providerFor(ref, site);
  final w = Period.d30.window();
  final rows = await gate
      .run(() => p.metric(site, w, MetricType.events, limit: 1))
      .catchError((_) => <MetricRow>[]);
  final has = rows.isNotEmpty;
  ref.read(sharedPrefsProvider).setBool(_hasEventsKey(site), has);
  return has;
});
