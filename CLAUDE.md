# CLAUDE.md — `glance`

**Glance** — client mobile d'analytics multi-outils (« Vos statistiques, en un clin d'œil »). Un client simple et lisible par-dessus **Umami**, **Plausible** (et bientôt Fathom). Maquette Claude Design « Glance - Analytics mobile », Direction A (crème + vert forêt).

## Stack

- **Flutter** (iOS + Android), Dart 3, `useMaterial3`
- **flutter_riverpod 3** (état + injection), **dio** (HTTP), **fl_chart** (graphiques), **flutter_secure_storage** (identifiants → Keychain), **shared_preferences** (comptes + réglages), **intl** (dates/nombres fr_FR), **flutter_timezone** (bucketing horaire correct)
- Fonts variables bundlées : **Fredoka** (titres/chiffres), **Geist** (corps), **JetBrains Mono** (labels/mono). Poids pilotés par `FontVariation('wght', …)` — voir `lib/theme/type.dart`.

## Architecture (couches)

```
lib/
  core/        format, countries (nom+drapeau), entities (navigateurs/appareils/canaux/langues en FR),
               metric_icon (URL + clé de cache d'une icône), errors, pool (limiteur de concurrence)
  data/
    models/    Site, StatsSummary, SeriesPoint, MetricRow, LivePage, DataRange, Account, Period,
               dimension (MetricType + MetricSection)
    providers/ AnalyticsProvider (interface) + UmamiProvider, PlausibleProvider, FathomProvider (stub) + factory
    repository/AccountsRepository (comptes en prefs, creds en secure storage)
  state/       providers Riverpod (accounts, sites, home, métriques, icônes), period_state (+ windowProvider),
               settings, home_data, metric_sections
  theme/       palette (ThemeExtension light+dark), type, theme, motion (tokens durées/curves)
  ui/          onboarding-vide (home), home, detail (+ metric_sections), direct, add (+ site_picker),
               settings, widgets/
  dev/         seed.dart (amorçage --dart-define, inerte sans defines)
```

**Règle d'or** : la couche UI ne parle qu'à l'interface `AnalyticsProvider`. Ajouter un fournisseur = une classe qui l'implémente + une entrée dans `buildProvider` + les `credentialFieldsFor`. Rien d'autre à toucher.

## Flux produit

1. **Accueil vide brandé** (aucun compte) → « Ajouter une source ».
2. **Ajout en 2 étapes** : fournisseur + identifiants → `listSites()` → **écran de choix des sites** (`site_picker`) : *tous les sites* (suit aussi les futurs) **ou** sélection explicite.
3. Plusieurs comptes/fournisseurs coexistent. Home = union des sites sélectionnés de chaque compte.
4. Détail par site : périodes (`today/24h/7j/30j/mois/12m/annee/perso`), graphe, KPIs, live, top pages/sources/pays. `mois` (« Ce mois-ci ») et `annee` (« Cette année ») sont calendaires : du 1er du mois / 1er janvier à maintenant.

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

## Les données d'un site : quatre sections, façon Umami

Le détail d'un site montre **Pages** (Chemins / Entrée / Sortie / Titre),
**Sources** (Référents / Canaux / Requêtes), **Environnement** (Navigateurs / OS /
Appareils / Écrans) et **Emplacement** (Pays / Régions / Villes / Langues) — le
découpage et les libellés d'Umami, pour qu'on retrouve son vocabulaire.

- `data/models/dimension.dart` : `MetricType` (16 dimensions) + `MetricSection`
  (leur regroupement) + la famille d'icône de chacune. `MetricType.key` est la clé
  d'API Umami **et** la clé de persistance — ne jamais la dériver de `name`.
- Un provider par dimension : `siteMetricProvider((site, window, type))`, en
  `cacheFor` (pas `cacheSession` : 16 dimensions × 9 périodes retiendraient tout ce
  qui a été feuilleté). Changer de sous-dimension ne recharge que celle-là.
- La sous-dimension choisie est persistée par section (`metricSectionsProvider`),
  pas par site : c'est une habitude de lecture.
- **Le rafraîchissement n'invalide que les 4 clés affichées** — `ref.invalidate` sur
  la famille entière relancerait des dizaines de requêtes par tick.
- Grille : `MetricSectionGrid` répartit en colonnes-seaux (`LayoutBuilder` +
  `Row` de `Column`), 1 à 3 colonnes selon `constraints.maxWidth` — **jamais**
  `MediaQuery.size` : le panneau central du bureau est plus étroit que la fenêtre,
  et franchir `kDesktopBreakpoint` fait apparaître 320 px de barre latérale, donc
  *élargir* la fenêtre peut *réduire* la place. Une `GridView` imposerait à chaque
  rangée la hauteur de sa plus haute carte ; ici `MetricBars.reserveRows` garde
  toutes les cartes à la même hauteur.
- **Pourcentage = part de `summary.visitors`**, jamais la somme des lignes reçues
  (qui dépend du nombre de lignes demandées : en afficher une de plus changerait
  tous les pourcentages). Vérifié sur l'instance : toutes les dimensions Umami
  comptent des visiteurs uniques (`max(y) ≤ visitors` sur 3 sites × 9 dimensions).
  Les dimensions multivaluées (chemins, titres) dépassent 100 % cumulés — c'est
  correct (« part des visiteurs qui ont vu cette page »), et chaque ligne est
  bornée à 100 %.

## Icônes des lignes de données

`core/metric_icon.dart` (pur, testé) dit d'où vient l'icône ; `FaviconCache.fromUrl`
la télécharge et la garde sur disque ; `iconProvider` la sert, derrière un
**sémaphore dédié** (`iconGateProvider`, 4) — une carte peut en demander 40 d'un
coup, elles ne doivent pas concurrencer les requêtes de statistiques.

- **Référents** → `icons.duckduckgo.com/ip3/<domaine>.ico`, comme Umami. Le domaine
  passe par `normDomain` (sans `www.`, sans port) : sinon 404, et un échec est
  mémorisé 7 jours.
- **Navigateurs / OS** → `<instance>/images/{browser,os}/<slug>.png`, servis
  publiquement par Umami. ⚠️ Le slug vient du **code brut**, jamais du libellé
  français : `browserName('crios')` vaut « Chrome (iOS) », dont le slug n'existe pas.
  La clé de cache porte l'hôte de l'instance — deux comptes peuvent servir des
  images différentes sous le même nom.
- **Appareils / pays** → dessinés localement (glyphe Material, drapeau émoji).
- ⚠️ Le slug remplace **tout** caractère non alphanumérique par un tiret, pas
  seulement les espaces : « Windows 8.1 » donne `windows-8-1.png`. Et seule une
  réponse du serveur vaut « pas d'icône » — une coupure réseau ne doit pas
  inscrire une absence pour sept jours.
- Flutter décode nativement les `.ico`, y compris les vrais ICO 32 bits non-PNG
  (vérifié sur google.com et github.com) : aucun décodeur à embarquer.

## Période partagée (synchro entre écrans)

`periodProvider` (`state/period_state.dart`) porte la période **et la granularité**
sélectionnées pour toute l'app. La fenêtre est **alignée sur la grille** (cf.
`Period.window` : borne de fin plafonnée à l'unité suivante) donc elle est **stable**
entre deux builds d'une même heure/jour → la clé des `family` ne change pas, pas de
reload en boucle.

⚠️ **Tous les écrans et toutes les minuteries lisent `windowProvider`**, jamais
`PeriodState.resolve()` (volontairement renommé pour que le compilateur signale les
oublis). Deux exceptions commentées : `siteHasEventsProvider` (30 j fixes,
indépendants de la période) et le test de connexion d'`add_source_screen`. Un écran
qui résoudrait la fenêtre lui-même ferait fetcher une seconde grappe complète, et
son `invalidate` viserait une clé que plus personne n'écoute — le graphe cesserait
de se rafraîchir **sans aucune erreur**.

`windowProvider` rend `null` tant que « Tout » attend sa date de première donnée :
l'appelant montre son squelette sans rien déclencher.

### La barre de contrôles

`PeriodControls` (`ui/widgets/period_controls.dart`), sous le titre de chaque
écran : les périodes sur toute la largeur, puis un bouton **« Affichage »** qui
ouvre une feuille — comparaison, découpage, courbe ou barres — et, sur
l'accueil, la bascule liste/grille à droite.

Les réglages tenaient auparavant dans des boutons sans libellé posés **à droite
des périodes**, qu'ils recouvraient : deux flèches ne disent pas « comparer à la
période précédente », et les premières périodes n'étaient plus atteignables sans
faire défiler. Dans une feuille, chaque réglage porte son nom et une phrase.

⚠️ Quand la comparaison est active, l'indication vit **sur la ligne du bouton**,
pas sur une ligne à elle : une ligne qui apparaît et disparaît ferait sauter tout
l'écran. Et c'est un `Expanded`, pas un `Flexible` suivi d'un `Spacer` — les deux
se disputeraient la place et le texte se ferait tronquer alors qu'il y en a.

### Découpage du graphique (heure / jour / mois)

Dans la feuille « Affichage », le découpage n'offre que
`allowedUnits(window)` — la règle d'Umami (`getMinimumUnit` : heure jusqu'à 30 j,
jour jusqu'à 7 mois, mois au-delà), bornée à **800 buckets** et à au moins 3 (pour
ne pas proposer « Mois » sur sept jours, qui donnerait une seule barre). Rien à
choisir sur « Aujourd'hui » → la section disparaît de la feuille.

⚠️ La granularité est appliquée **avant** le calcul des bornes (`Period.window(unit:)`),
jamais posée après coup dans le 3ᵉ champ de `DateWindow` : une journée demandée en
granularité jour donnerait alors une fenêtre plus courte qu'un bucket, donc une
**série vide et un graphe blanc, sans erreur**.

⚠️ Pas de `TimeUnit.year` : Umami la ramène de toute façon à `month`, et recoller
les 12 mois côté client surcompterait les visiteurs uniques.

### « Tout » part des vraies données

`/api/websites/:id/daterange` donne la première (et la dernière) mesure d'un site.
`siteDataStartProvider` la résout et la persiste ; `allTimeStartProvider` en prend
le minimum sur les sites affichés, **tout-ou-rien** (une borne qui reculerait à
chaque réponse relancerait une vague de requêtes par site).

⚠️ **Seul le début vient de l'API.** `endDate` bouge à chaque visite enregistrée :
l'utiliser ferait changer la clé des providers à chaque build — le bug
« chargement infini » documenté plus bas, en pire (`cacheSession` ne libère rien).
La fin reste `_ceil(now, unit)`, comme pour toutes les autres périodes.

⚠️ La fenêtre de « Tout » est **commune à tous les sites** de l'accueil :
`HomeData.fromCards` additionne les séries **par index de bucket**, donc des
fenêtres par site y additionneraient 2019 avec 2024. Corollaire assumé : changer
de groupe pendant que « Tout » est actif peut déplacer la borne commune, donc
tout recharger. C'est le prix d'un total juste.

### La portée d'une fenêtre ne se devine pas de son début seul

`calendarScopeOf` (core/predict.dart) dit ce qu'une fenêtre recouvre — jour,
mois, année, ou rien de calendaire — et la prévision comme la comparaison s'y
adossent. Il lui faut les **trois** informations :
- le début seul confond, le 1er du mois, « aujourd'hui » et « ce mois-ci » ;
- la granularité seule confond « ce mois-ci » en heures avec « aujourd'hui » ;
- c'est la **fin** qui tranche : une journée ne dure pas plus de 24 h.

Reste un cas que rien ne départage : le 1er du mois, « aujourd'hui » et « ce
mois-ci en heures » donnent la même fenêtre. On retient la portée la plus
étroite — un horizon sous-estimé se lit, un horizon surestimé donne un chiffre
aberrant (mesuré avant correction : une prévision à ×65 sur l'écran du jour).

## Graphiques (point clé de la demande)

- `ui/widgets/chart_model.dart` : `ChartModel` décide une fois pour toutes des séries visibles, de l'échelle, de l'axe des temps — la courbe et les barres partagent exactement les mêmes décisions. Le réglage « Courbe / Barres » (Réglages → Apparence) choisit le moteur. En barres, la comparaison passe **derrière** la barre courante (`backDrawRodData`) et la prévision devient un remplissage bordé de pointillés (une barre ne se trace pas en trait discontinu) ; sous 2 px de large, le rendu **revient à la courbe**. `EventsChart` reste en lignes : 8 séries groupées y donneraient des barres d'un pixel.
- `ui/widgets/glance_chart.dart` (fl_chart) : courbe **lissée** (`isCurved`, `curveSmoothness`, cap/join round), **aire dégradée**, **échelle Y arrondie**, labels X selon la granularité, tooltip tactile. Deux courbes — **Visiteurs** (vert, aire) + **Pages vues** (gris) — avec légende cliquable (masquer/afficher) sur home/détail. (Les *visites* ne sont volontairement PAS tracées : par heure elles sont égales aux visiteurs — cf. gotcha `sessions ≠ visites` — donc redondantes ; elles restent en carte KPI du détail.) Remplace la barre de la maquette. Sparkline compacte des cartes = `ui/widgets/sparkline.dart`.
- `ui/widgets/events_chart.dart` : **multi-lignes, une couleur par événement** (palette `kEventPalette`), échelle Y partagée, tooltip listant chaque événement. Onglet Événements du détail : légende = puces cliquables (cocher/décocher les courbes ; au-delà de 6 events les moins fréquents sont masqués par défaut), barres de répartition colorées assorties.
- Helpers partagés dans `ui/widgets/chart_util.dart` (`chartNiceMax`, `chartTooltipDate`).

### Prévision (pointillé orange)

Les gros graphes (home/détail/desktop) prolongent la courbe visiteurs d'une **prévision en pointillé orange** (`palette.forecast`) quand la fenêtre contient du futur. Moteur pur dans `core/predict.dart` (testé dans `test/predict_test.dart`) :
- **En jours et en mois : projection jour par jour** (`core/daily_forecast.dart`, testé dans `test/daily_forecast_test.dart`). `siteStatsProvider` récupère en plus 63 jours de visiteurs par jour (`forecastHistoryWindow`, best-effort, porté par `SiteStats.daily` / `HomeData.totalDaily`). Chaque jour restant = **niveau des 7 derniers jours** (désaisonnalisé) × **profil de la semaine** sur 8 semaines, puis regroupé dans les buckets de la fenêtre. Un bucket mensuel compte des visiteurs *uniques* : la somme des jours est convertie au taux uniques/somme-des-jours observé (mois précédent complet, sinon mois en cours).
  - Choisi sur **banc d'essai** (2026-10-09, 96 mois réels de 10 sites Umami, coupures du 3 au 25) — erreur médiane sur le total du mois : **9,7 %**, contre 10,7 % Holt-Winters amorti (sa tendance n'apporte rien : 7 jours de niveau suivent déjà la croissance), 11,6 % rythme du mois seul, 16,1 % profil du mois précédent (l'ancienne méthode de « ce mois-ci »). Rejouer un banc d'essai avant de changer de modèle.
  - ⚠️ Ne jamais projeter à la **moyenne de la fenêtre** : sur « 12 m » / « cette année », elle inclut les mois d'avant le lancement (vécu : 1 565 annoncés pour un mois parti pour ~4 000).
- **En heures (et en repli si l'historique manque ou fait < 14 jours)** : « observé + rythme attendu × temps restant ». Pour « aujourd'hui », le rythme attendu = profil d'**hier** rescalé par le ratio observé/référence (`forecastReferenceWindow`, seule fenêtre de référence encore récupérée, `SiteStats.refSeries`). Sans profil, le bucket courant se complète à son propre rythme adossé au dernier bucket complet, et les buckets futurs le reprennent.
- La détection se fait **sur la fenêtre, pas sur la `Period`** (`forecastSpecFor`) : deux périodes qui résolvent la même fenêtre (ex. 12 m en décembre ≡ cette année) affichent la même prévision.
- Le total projeté de la légende = `total visiteurs uniques × growth` (ne PAS sommer les buckets projetés : un visiteur peut apparaître dans plusieurs buckets).
- Légende « Prévision » basculable, clé `forecast` dans `settings.hiddenSeries` (comme visiteurs/pages vues).

## Navigation interne (« Entre vos sites »)

Reprise mobile de la vue « referrals » du dashboard monkey : les referrers de chaque site sont croisés avec les domaines de TOUS les sites suivis (`core/internal_traffic.dart`, testé) → visiteurs que vos sites s'envoient entre eux. `state/internal_traffic.dart` : `siteReferrersProvider` (metric sources limit 50, cache session) + `internalTrafficProvider` (composition au fil de l'eau, pattern homeTotals). UI : carte compacte sur l'accueil (masquée si zéro flux) → écran `ui/network/internal_screen.dart` (KPI, qui envoie/reçoit, flux) ; badge « INTERNE » sur les sources du détail (self exclu). **Fenêtre courante seulement** — pas de séries journalières (N×30 appels, trop pour mobile).

## API par fournisseur

### Umami (self-hosted, **v3** — vérifié sur `uuu.my-monkey.fr`)
- Auth : `POST /api/auth/login` {username,password} → `{token, user:{isAdmin,role}}`. Bearer réutilisé, re-login auto sur 401.
- **Liste des sites** : `/api/websites` ne renvoie **que** les sites possédés/partagés → un compte **admin** doit passer par **`/api/admin/websites`** (routage selon `isAdmin`).
- `/api/websites/:id/stats` → nombres **plats** `{pageviews,visitors,visits,bounces,totaltime}` **+ `comparison`**, qui contient la période précédente de même durée (vérifié au chiffre près contre un appel manuel). Le 2ᵉ appel d'avant a disparu ; le repli reste en place si le champ manque.
- `/api/websites/:id/daterange` → `{startDate, endDate}` : la vraie plage de données du site.
- `/api/websites/:id/pageviews?unit=&timezone=` → `{pageviews:[{x,y}], sessions:[{x,y}]}`, `x` = `"YYYY-MM-DD HH:MM:SS"`. On remplit des buckets continus. **`sessions` = visiteurs uniques par bucket, pas les visites** (cf. gotchas).
- `/api/websites/:id/active` → `{visitors:N}`.
- `/api/websites/:id/metrics?type=` — 17 dimensions vérifiées sur l'instance : `path` (⚠️ pas `url` en v3), `entry`, `exit`, `title`, `referrer`, `channel`, `query`, `browser`, `os`, `device`, `screen`, `country`, `region`, `city`, `language`, `event`, `tag`. ⚠️ `region` et `city` répondent 200 mais **vides** sur `uuu.my-monkey.fr` : l'instance n'a pas de base GeoLite City (0 ligne sur 33 637 sessions). Le paramètre `metric=views|visitors` n'existe pas : les valeurs sont toujours des **visiteurs uniques**.
- `unit=` de `/pageviews` accepte `hour|day|month|year` — **pas `week`**.

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
- iOS deployment target **15.0** (pbxproj ; le `post_install` du Podfile qui le forçait n'existe plus).
- **Plugins via Swift Package Manager.** **iOS n'a plus CocoaPods du tout** (2026-08-16 : `pod deintegrate`, `Podfile`/`Podfile.lock`/`Pods/` supprimés, `#include?` retirés des xcconfig, référence Pods sortie du workspace) — tous ses plugins sont des Swift Packages. **macOS garde un pod** : `auto_updater_macos` (Sparkle) ne supporte pas SPM, d'où un `pod install` encore joué et un `Podfile.lock` réduit à ces deux-là. Ne pas remettre `flutter config --no-enable-swift-package-manager` : les deux pbxproj référencent `FlutterGeneratedPluginSwiftPackage`. Versions RevenueCat figées par les `Package.resolved`, commités des deux côtés.
- ⚠️ **Les cibles widget n'héritent d'aucun xcconfig** (le projet n'en fournit pas) : leur `baseConfigurationReference` pointe explicitement le xcconfig généré par Flutter, sans quoi `$(FLUTTER_BUILD_NUMBER)` / `$(FLUTTER_BUILD_NAME)` sont vides et la version de l'extension doit être écrite en dur — c'est ainsi qu'elle avait dérivé (widgets en 1.6.1, builds 11 et 3, pendant que l'app était en 1.8.0+14). Vérifier après une release : `PlistBuddy -c "Print :CFBundleVersion"` sur l'app **et** sur le `.appex`.
- ⚠️ **Xcode 27 (stable depuis octobre 2026) casse le build macOS universel avec Flutter 3.44.** Son `lipo` refuse `-verify_arch arm64 x86_64` (« requires exactly one input file ») ; `thinFramework` (`flutter_tools/…/build_system/targets/darwin.dart`) en fait un échec au message trompeur — « Binary … does not contain architectures "arm64 x86_64" » suivi d'un `lipo -info` qui montre les deux. Corrigé en amont dans **Flutter 3.47** (commit `879ec7d5750`, #188625). Tant que le projet reste en 3.44 : `git -C <sdk> cherry-pick -n 879ec7d5750 && rm <sdk>/bin/cache/flutter_tools.stamp`, builder, puis `git -C <sdk> reset -q HEAD -- packages/flutter_tools && git -C <sdk> checkout -- packages/flutter_tools` (fait pour la 1.10.1). Un wrapper `lipo` dans le `PATH` ne marche pas : Xcode réinitialise le `PATH` de ses phases de script. ⚠️ Toujours vérifier `CFBundleShortVersionString` du `.app` avant de signer : un build raté laisse l'ancienne version dans `build/`, que la suite signe et notarise sans broncher.

### Instance de test
Umami `uuu.my-monkey.fr` (dev-cookie). Un utilisateur **service** dédié `glance` (role admin, lecture) a été créé **directement en base** (bcrypt via `bcryptjs`, insert Postgres `umami-db`). C'est un compte technique — pas le compte perso de Maxim.

## Motion & feedback (depuis 1.6.2)

- **Tokens** : `theme/motion.dart` (`kMotionFast/Base/Slow`, `kCurveOut/OutCubic`) — toute nouvelle animation les utilise, pas de durées en dur.
- **Widgets** (`ui/widgets/motion.dart`) : `GlanceSwap` (fondu+glissement entre sous-arbres, keyer l'enfant), `GlanceFadeIndexedStack` (onglets animés, état préservé), `GlanceReveal` (sections conditionnelles dépliées — les espacements conditionnels vivent DANS le child).
- **Toasts** : `showGlanceToast(context, msg, {kind})` (`ui/widgets/toast.dart`) — overlay racine via `glanceNavKey`, appeler **avant** un éventuel `Navigator.pop`. Toute action qui réussit silencieusement doit en montrer un.
- `showGlanceModal` : slide-up mobile par défaut, `fullscreenDialog: false` pour l'étape 2 d'un flux ; desktop = fade+scale, barrier atténué en modale-dans-modale.

## Gotchas rencontrés

- **⚠️ `TickerMode` + animations implicites = gel** : couper `TickerMode(enabled: false)` sur un sous-arbre dont une animation implicite (`AnimatedOpacity`…) est en cours la fige à sa valeur courante — l'écran « sortant » reste peint en surimpression. Toute transition de visibilité d'un sous-arbre sous TickerMode doit être pilotée par un contrôleur du **parent** (cf. `GlanceFadeIndexedStack`). Symptôme vécu en 1.6.2 : écrans superposés au changement d'onglet, uniquement dans le sens retour (non couvert par le test simulateur initial — tester les deux sens).

- **Chargement infini du détail** : `_window` calculé à chaque build avec `DateTime.now()` → la clé de `FutureProvider.family` changeait en continu → reload en boucle. Fix : figer `_window` dans l'état (recalcul uniquement au changement de période / refresh). Toute fenêtre passée à une `family` doit être stable entre les builds.
- **`Cannot remove from an unmodifiable list`** : `Account.decodeList` renvoie `growable:false` ; `loadAccounts()` doit renvoyer une copie modifiable.
- **Delta « explosif »** : quand la période précédente ≈ 0 (Umami récemment ajouté), le % explose. Au-delà de +400 %, `DeltaText` bascule en multiplicateur « ×N ».
- Umami v3 : `type=path` (pas `url`) ; sites admin via `/api/admin/websites`.
- **⚠️ Le `guard` de `_buckets` tronquait la FIN de la série** (les données les plus récentes) sans lever d'erreur. Il lève maintenant : une série tronquée ressemble à un trou de collecte, une erreur se voit.
- **⚠️ `sessions` de `/pageviews` = visiteurs *uniques*, PAS les visites.** Vérifié sur toutes les instances/granularités : la série `sessions` de `/api/websites/:id/pageviews` est *strictement égale* aux `visitors` de `/stats` par bucket (une personne = 1 session/bucket). Donc `SeriesPoint.visitors` (courbe verte) vient de `sessions` et `SeriesPoint.pageviews` (gris) de `pageviews`. Ne PAS croire « sessions = visites » (ça donnerait deux courbes identiques). Les **visites** (`visit_id`, navigations distinctes) sont un autre nombre (≥ visiteurs) mais **Umami ne les expose pas en série** — et par bucket fin (heure) elles = visiteurs, l'écart (visites totales > visiteurs) ne venant que de la déduplication inter-bucket. On a donc choisi de **ne PAS tracer les visites** (redondantes) ; elles restent en résumé (`StatsSummary.visits`, carte KPI du détail). Si un jour on veut la courbe : 1 appel `/stats` par point (reconstitution) — cf. historique git.

## Pas encore fait

- Déploiement / distribution (pas de `.monkey` — c'est une app mobile, pas un site).
- Fathom (interface prête, `FathomProvider` = stub).
- Plausible : implémenté mais non validé sur une vraie instance.
- Notifications (pic de trafic / rapport quotidien) : UI présente, back non branché.
