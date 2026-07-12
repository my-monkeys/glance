# CLAUDE.md — `glance`

**Glance** — client mobile d'analytics multi-outils (« Vos statistiques, en un clin d'œil »). Un client simple et lisible par-dessus **Umami**, **Plausible** (et bientôt Fathom). Maquette Claude Design « Glance - Analytics mobile », Direction A (crème + vert forêt).

## Stack

- **Flutter** (iOS + Android), Dart 3, `useMaterial3`
- **flutter_riverpod 3** (état + injection), **dio** (HTTP), **fl_chart** (graphiques), **flutter_secure_storage** (identifiants → Keychain), **shared_preferences** (comptes + réglages), **intl** (dates/nombres fr_FR), **flutter_timezone** (bucketing horaire correct)
- Fonts variables bundlées : **Fredoka** (titres/chiffres), **Geist** (corps), **JetBrains Mono** (labels/mono). Poids pilotés par `FontVariation('wght', …)` — voir `lib/theme/type.dart`.

## Architecture (couches)

```
lib/
  core/        format, countries (nom+drapeau), errors, pool (limiteur de concurrence)
  data/
    models/    Site, StatsSummary, SeriesPoint, MetricRow, LivePage, SiteDetail, Account, Period
    providers/ AnalyticsProvider (interface) + UmamiProvider, PlausibleProvider, FathomProvider (stub) + factory
    repository/AccountsRepository (comptes en prefs, creds en secure storage)
  state/       providers Riverpod (accounts, sites, home, detail), settings, home_data
  theme/       palette (ThemeExtension light+dark), type, theme
  ui/          onboarding-vide (home), home, detail, direct, add (+ site_picker), settings, widgets/
  dev/         seed.dart (amorçage --dart-define, inerte sans defines)
```

**Règle d'or** : la couche UI ne parle qu'à l'interface `AnalyticsProvider`. Ajouter un fournisseur = une classe qui l'implémente + une entrée dans `buildProvider` + les `credentialFieldsFor`. Rien d'autre à toucher.

## Flux produit

1. **Accueil vide brandé** (aucun compte) → « Ajouter une source ».
2. **Ajout en 2 étapes** : fournisseur + identifiants → `listSites()` → **écran de choix des sites** (`site_picker`) : *tous les sites* (suit aussi les futurs) **ou** sélection explicite.
3. Plusieurs comptes/fournisseurs coexistent. Home = union des sites sélectionnés de chaque compte.
4. Détail par site : périodes (`today/24h/7j/30j/12m/perso`), graphe, KPIs, live, top pages/sources/pays.

La sélection de sites est éditable après coup : Réglages → tap sur le compte → « Choisir les sites ».

## Chargement des données (incrémental)

**Un provider par site**, pas un gros lot. Chaque carte s'affiche/s'actualise dès que SA donnée arrive :
- `siteStatsProvider((site, window))` (autoDispose) : résumé + série d'un site.
- `siteLiveProvider(site)` (autoDispose) : visiteurs en direct (indépendant de la période).
- `homeTotalsProvider(window)` : `Provider` qui `watch` tous les providers par site et recompose les totaux **au fil de l'eau** (le total monte pendant le chargement).
- La concurrence est plafonnée par un **sémaphore** partagé (`fetchGateProvider`, 6) — sinon N sites = 3N requêtes simultanées.
- Les cartes non chargées montrent un **squelette** (`_GridSkeleton`/`_TileSkeleton`) ; une carte en échec devient `_SiteErrorCard` sans bloquer les autres.
- Accueil : cartes **triées par visiteurs** (chargés en tête, squelettes à la suite) ; `ValueKey(site)` sur chaque slot → Flutter déplace au lieu de reconstruire. Direct trie par live.
- Auto-refresh / pull : `ref.invalidate(siteStatsProvider)` + `ref.invalidate(siteLiveProvider)` (familles entières) → refetch en place, valeurs précédentes conservées (pas de flash). Une fine `RefreshBar` en haut tant que `homeTotals.loading`.

## Période partagée (synchro entre écrans)

`periodProvider` (`state/period_state.dart`, `NotifierProvider<PeriodNotifier, PeriodState>`) porte la période sélectionnée pour **tout** l'app. Accueil et détail lisent/écrivent le même état → ouvrir un site conserve la période de l'accueil, changer la période n'importe où se répercute partout. La fenêtre est **alignée sur la grille** (cf. `Period.window` : borne de fin plafonnée à l'unité suivante) donc `window()` renvoie une valeur **stable** entre deux builds d'une même heure/jour → la clé des `family` ne change pas, pas de reload en boucle (plus besoin de figer la fenêtre en state).

## Graphiques (point clé de la demande)

- `ui/widgets/glance_chart.dart` (fl_chart) : courbe **lissée** (`isCurved`, `curveSmoothness`, cap/join round), **aire dégradée**, **échelle Y arrondie**, labels X selon la granularité, tooltip tactile. Deux courbes — **Visiteurs** (vert, aire) + **Pages vues** (gris) — avec légende cliquable (masquer/afficher) sur home/détail. (Les *visites* ne sont volontairement PAS tracées : par heure elles sont égales aux visiteurs — cf. gotcha `sessions ≠ visites` — donc redondantes ; elles restent en carte KPI du détail.) Remplace la barre de la maquette. Sparkline compacte des cartes = `ui/widgets/sparkline.dart`.
- `ui/widgets/events_chart.dart` : **multi-lignes, une couleur par événement** (palette `kEventPalette`), échelle Y partagée, tooltip listant chaque événement. Onglet Événements du détail : légende = puces cliquables (cocher/décocher les courbes ; au-delà de 6 events les moins fréquents sont masqués par défaut), barres de répartition colorées assorties.
- Helpers partagés dans `ui/widgets/chart_util.dart` (`chartNiceMax`, `chartTooltipDate`).

## API par fournisseur

### Umami (self-hosted, **v3** — vérifié sur `uuu.my-monkey.fr`)
- Auth : `POST /api/auth/login` {username,password} → `{token, user:{isAdmin,role}}`. Bearer réutilisé, re-login auto sur 401.
- **Liste des sites** : `/api/websites` ne renvoie **que** les sites possédés/partagés → un compte **admin** doit passer par **`/api/admin/websites`** (routage selon `isAdmin`).
- `/api/websites/:id/stats` → nombres **plats** `{pageviews,visitors,visits,bounces,totaltime}` (le champ `comparison` n'est pas peuplé sans params dédiés → on fait un **2e appel** sur la période précédente pour le delta).
- `/api/websites/:id/pageviews?unit=&timezone=` → `{pageviews:[{x,y}], sessions:[{x,y}]}`, `x` = `"YYYY-MM-DD HH:MM:SS"`. On remplit des buckets continus. **`sessions` = visiteurs uniques par bucket, pas les visites** (cf. gotchas).
- `/api/websites/:id/active` → `{visitors:N}`.
- `/api/websites/:id/metrics?type=` : **`path`** (pages, ⚠️ pas `url` en v3), `referrer` (sources), `country` (pays).

### Plausible (Stats API v2, implémenté d'après la doc — à valider sur instance)
- `POST /api/v2/query` Bearer, `{site_id, metrics, date_range, dimensions:['time:day'|'event:page'|…], timezone}`.
- Un compte Plausible = **un domaine** (`site_id`) : la Stats API ne liste pas les sites.
- Temps réel : `GET /api/v1/stats/realtime/visitors?site_id=`.

## Dev / test sur simulateur

```bash
# lancer
flutter run -d <udid-simulateur-ios>

# amorçage rapide d'un compte (évite de re-saisir le formulaire) — defines inertes sinon
flutter run -d <udid> \
  --dart-define=SEED_UMAMI_URL=uuu.my-monkey.fr \
  --dart-define=SEED_UMAMI_USER=<user> \
  --dart-define=SEED_UMAMI_PASS=<pass> \
  --dart-define=SEED_UMAMI_SITES=<id1,id2,...>   # optionnel, sinon tous
```

- Piloter le simulateur : **idb** (`idb ui tap/text/swipe --udid …`), coordonnées en **points logiques** (= pixels du screenshot / 3 sur @3x). Screenshots via `xcrun simctl io <udid> screenshot`.
- iOS deployment target **15.0** (Podfile + pbxproj). Intégration **CocoaPods** (SPM désactivé : `flutter config --no-enable-swift-package-manager`), sinon conflit plugins/Pods au build.

### Instance de test
Umami `uuu.my-monkey.fr` (cookie-server). Un utilisateur **service** dédié `glance` (role admin, lecture) a été créé **directement en base** (bcrypt via `bcryptjs`, insert Postgres `umami-db`). C'est un compte technique — pas le compte perso de Maxim.

## Gotchas rencontrés

- **Chargement infini du détail** : `_window` calculé à chaque build avec `DateTime.now()` → la clé de `FutureProvider.family` changeait en continu → reload en boucle. Fix : figer `_window` dans l'état (recalcul uniquement au changement de période / refresh). Toute fenêtre passée à une `family` doit être stable entre les builds.
- **`Cannot remove from an unmodifiable list`** : `Account.decodeList` renvoie `growable:false` ; `loadAccounts()` doit renvoyer une copie modifiable.
- **Delta « explosif »** : quand la période précédente ≈ 0 (Umami récemment ajouté), le % explose. Au-delà de +400 %, `DeltaText` bascule en multiplicateur « ×N ».
- Umami v3 : `type=path` (pas `url`) ; sites admin via `/api/admin/websites` ; deltas via 2e appel stats.
- **⚠️ `sessions` de `/pageviews` = visiteurs *uniques*, PAS les visites.** Vérifié sur toutes les instances/granularités : la série `sessions` de `/api/websites/:id/pageviews` est *strictement égale* aux `visitors` de `/stats` par bucket (une personne = 1 session/bucket). Donc `SeriesPoint.visitors` (courbe verte) vient de `sessions` et `SeriesPoint.pageviews` (gris) de `pageviews`. Ne PAS croire « sessions = visites » (ça donnerait deux courbes identiques). Les **visites** (`visit_id`, navigations distinctes) sont un autre nombre (≥ visiteurs) mais **Umami ne les expose pas en série** — et par bucket fin (heure) elles = visiteurs, l'écart (visites totales > visiteurs) ne venant que de la déduplication inter-bucket. On a donc choisi de **ne PAS tracer les visites** (redondantes) ; elles restent en résumé (`StatsSummary.visits`, carte KPI du détail). Si un jour on veut la courbe : 1 appel `/stats` par point (reconstitution) — cf. historique git.

## Pas encore fait

- Déploiement / distribution (pas de `.monkey` — c'est une app mobile, pas un site).
- Fathom (interface prête, `FathomProvider` = stub).
- Plausible : implémenté mais non validé sur une vraie instance.
- Notifications (pic de trafic / rapport quotidien) : UI présente, back non branché.
