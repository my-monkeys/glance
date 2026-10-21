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
               settings, home_data, metric_sections, indicators (tableaux)
  theme/       palette (ThemeExtension light+dark), type, theme, motion (tokens durées/curves)
  ui/          onboarding-vide (home), home, detail (+ metric_sections), dashboards (+ editor),
               direct, add (+ site_picker), settings, widgets/
  dev/         seed.dart (amorçage --dart-define, inerte sans defines)
```

**Règle d'or** : la couche UI ne parle qu'à l'interface `AnalyticsProvider`. Ajouter un fournisseur = une classe qui l'implémente + une entrée dans `buildProvider` + les `credentialFieldsFor` (+ `supportedIndicatorsFor` s'il sait calculer des tableaux). Rien d'autre à toucher.

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
oublis). Trois exceptions commentées : `siteHasEventsProvider` (30 j fixes,
indépendants de la période), le test de connexion d'`add_source_screen`, et les
suggestions de l'éditeur de tableaux (`state/indicators.dart`, 30 j fixes). Un écran
qui résoudrait la fenêtre lui-même ferait fetcher une seconde grappe complète, et
son `invalidate` viserait une clé que plus personne n'écoute — le graphe cesserait
de se rafraîchir **sans aucune erreur**.

`windowProvider` rend `null` tant que « Tout » attend sa date de première donnée :
l'appelant montre son squelette sans rien déclencher.

### La barre de contrôles

`PeriodControls` (`ui/widgets/period_controls.dart`), sous le titre de chaque
écran : les périodes sur toute la largeur, puis un bouton **« Affichage »** qui
ouvre une feuille — découpage, courbe ou barres — et, sur l'accueil, la bascule
liste/grille à droite.

Les réglages tenaient auparavant dans des boutons sans libellé posés **à droite
des périodes**, qu'ils recouvraient, et les premières périodes n'étaient plus
atteignables sans faire défiler. Dans une feuille, chaque réglage porte son nom.

**Une ligne ou deux, selon la place.** Un `LayoutBuilder` (jamais `MediaQuery.size`)
mesure les périodes sur leur contenu réel (`GlanceChip.widthOf`, `TextPainter`) et
y ajoute le bouton et la bascule : si le tout tient sans défilement, tout est sur
**une seule ligne** (périodes à gauche en `Expanded`, bouton et bascule à droite) ;
sinon les contrôles passent sur la seconde ligne (téléphone). Trois paliers, dans
l'ordre : bouton avec son libellé ; bouton **réduit à l'icône**, avec « Affichage »
dans l'infobulle (le panneau central du bureau, vers 860 px, rate le libellé de
quelques pixels) ; deux lignes. Les tests rendent en Ahem (glyphes carrés) : les
périodes y font ~980 px au lieu de ~450, d'où une « grande » largeur de test plus
grande qu'un vrai bureau.

### La comparaison vit dans la légende

« Période précédente » est un élément de la légende du grand graphique (accueil,
détail, bureau), **décoché par défaut**, à côté des courbes qu'il compare : un
interrupteur rangé dans une feuille ne disait pas ce qu'il allait ajouter au
graphique, et son état obligeait à une annonce sur le bouton « Affichage ».

⚠️ **Une seule source de vérité : `PeriodState.compare`** (non persisté, faux au
lancement). C'est lui qui déclenche le chargement de la période précédente
(`siteCompareSeriesProvider`) ; la clé `compare` n'existe plus dans
`settings.hiddenSeries`, sans quoi deux états « visible » pourraient diverger.
`GlanceChart` reçoit `compareOn` + `onToggleCompare`, et cet élément disparaît
quand `previousPeriodWindow(window) == null` (« Tout », période personnalisée trop
large) : `onToggleCompare` vaut alors `null`.

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
- **Deux axes quand les deux courbes sont visibles** : visiteurs à gauche, pages vues à droite (`ChartModel.rightMaxY`, `chartNiceMax` propre à chaque série). Les pages vues font souvent plusieurs fois les visiteurs et, sur un axe commun, écrasaient la courbe verte. fl_chart n'a qu'un axe Y : les pages vues sont tracées à `v × maxY / rightMaxY` (`toPlot`), mais les **tooltips lisent toujours les valeurs réelles**. Une seule des deux visible → un seul axe à gauche, sans gouttière à droite. `chartNiceMax` donne des entiers multiples de 4 dès 1 (quatre graduations aux libellés distincts) par paliers 1 · 1,2 · 1,6 · 2 · 2,4 · 3,2 · 4 · 4,8 · 6 · 8.
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

## Tableaux (indicateurs construits sur les événements)

3ᵉ onglet du détail d'un site, à côté de « Vue d'ensemble » et « Événements ».
L'utilisateur y compose ses propres indicateurs à partir des événements du site.
Il en existe quatre types (`data/models/indicator.dart`) :
- **Compteur** : un événement filtré.
- **Taux** : deux compteurs divisés.
- **Entonnoir** : 2 à 8 étapes.
- **Répartition** : les valeurs d'une propriété.

Côté code :
- **Données** : `state/indicators.dart`.
- **Interface** : `ui/dashboards/`, et l'éditeur libre dans `ui/dashboards/editor/`.
- **Logique pure, testée** : `IndicatorDraft` (validation, nom proposé) et `core/indicator_math.dart` (ratio).

L'onglet s'affiche si le site a des événements **et** si
`supportedIndicatorsFor(kind)` n'est pas vide, **ou** si le site a une source de
métriques (cf. plus bas). Cette fonction est synchrone, à
côté de `credentialFieldsFor` : la visibilité se décide au premier build, sans
attendre d'instance. Couverture par fournisseur :
- **Umami** : les 4 types.
- **Plausible** : compteur, taux et répartition (sa Stats API n'a pas d'entonnoir).
- **Fathom** : aucun.

- ⚠️ **Tout passe par `/events/series`, jamais `/stats?event=`** : `/stats` ne
  compte que les pages vues et rend **0** pour un événement.
- **Filtres par propriété** : paramètres `epf0`, `epf1`… (combinés en ET), de la
  forme `<type>.<op>.<nom encodé>.<valeur>`. Le type est obligatoire : 1 texte,
  2 nombre, 3 booléen (ex. `epf0=1.eq.issue.complet`, `epf0=2.gte.reussite.80`).
  C'est pour ça qu'un `EventFilter` stocke le type de sa propriété. Le nom est
  encodé et ses `.` échappés (`umamiEventFilterParams`, testé).
- ⚠️ **`window` d'un entonnoir = des MINUTES entre deux étapes**, pas des jours
  comme le dit la doc d'Umami : son SQL fait `interval <window> minute`. Le défaut
  est 60, comme le formulaire d'Umami. Mesuré sur geography : 52 % de parties
  complètes avec 1 minute, 71,6 % avec 60. Les filtres d'étape n'acceptent que
  `eq neq c dnc`, pas de comparaison numérique. L'entonnoir relie les étapes **par
  session**, pas par partie.
- **Taux global = somme(A) / somme(B)**, jamais la moyenne des taux par bucket.
  Un bucket au dénominateur nul compte pour **0 %** par défaut : les trous
  déroutaient. L'option `gapsWhenEmpty` (case « Laisser un trou quand rien ne
  s'est passé », clé JSON `gaps`) les rend : rien ne s'est passé, ce n'est pas un
  échec mesuré, et un 0 % l'affirmerait. `ratioOf` reste pur et prend le choix en
  paramètre ; le taux global n'en dépend pas.
- **Répartition** : % = part du **total des événements** de la répartition.
  C'est l'inverse de la règle du détail (part de `summary.visitors`) : ici les
  lignes partitionnent un même événement, leur somme est donc le bon dénominateur.
- **Cartes sans données masquées** : voir « Source de métriques » plus bas
  (`hasDisplayableData`, ligne « N tableaux sans données · Afficher »).
- **Éditeur** : les suggestions (événements, propriétés, valeurs) portent sur
  30 jours fixes. Sinon, un événement rare n'en proposerait aucune sur
  « Aujourd'hui ». L'aperçu attend 600 ms après la dernière frappe, et le nom
  saisi ne fait **pas** partie de la clé du provider : renommer ne relance pas de
  requête.
- **Synchro** : clé `indicators` **facultative** dans le paquet `glance-sync`.
  ⚠️ `SyncCrypto.version` reste à 1 : une app plus ancienne lit une version
  inconnue comme un mauvais mot de passe, alors qu'elle ignore une clé en plus.
  La fusion se fait par id, comme pour les groupes, et **une suppression ne se
  propage pas**. Le **QR de transfert n'emporte pas les tableaux** : sa taille est
  plafonnée.
- **Pas de rétention** : le rapport `retention` d'Umami fonctionne, mais
  sous-estime d'un tiers à la moitié. Sa session est un hash IP + navigateur, à
  sel mensuel. Comparé à la base de geography le 2026-10-19 : J1 = 7,7 % contre
  11,4 %. Et il ne voit pas les joueurs déjà installés. Une rétention juste
  viendra d'une API d'agrégats côté site : voir « Source de métriques » plus bas.
- **Amorçage de développement** : `--dart-define=SEED_INDICATORS=geography
  --dart-define=SEED_INDICATORS_SITE=<id>` pose 4 indicateurs d'exemple (inerte
  sans ces defines).

### Source de métriques (API d'agrégats)

Un site peut exposer ses propres indicateurs, calculés sur sa base (rétention,
comptes…). Glance les affiche comme un 5ᵉ genre de tableau, « Métrique du site »
(`ExternalIndicator`). Le contrat est **générique** : rien de propre à un site
dans le code.
- **Contrat** (v1), `Authorization: Bearer <jeton>` :
  - `GET {base}catalogue` → `{version, indicateurs:[{id, libelle, description, unite, granularites}]}`.
  - `GET {base}series?ids=a,b&de=&a=&granularite=jour|semaine|mois&tz=` →
    `{version, series:[{id, points:[{t, valeur, numerateur, denominateur}]}]}`.
  - `unite` = `pourcentage` (0..100) ou `nombre`. `de`/`a` : dates locales
    inclusives, 400 jours max ; `t` = début du bucket ; un point par bucket, vides
    compris ; le premier peut commencer avant `de`.
  - Statuts : 404 source non configurée, 401 jeton absent ou faux, 400
    `{error:{code}}`. Toute `version` ≠ 1 est refusée (« Version d'API non prise
    en charge »). Le serveur met en cache 5 min.
- ⚠️ **`valeur: null` = non mesurable** (cohorte pas terminée, ou dénominateur < 5 :
  seuil de confidentialité du serveur). C'est un **trou**, jamais un 0 — quelle
  que soit l'option « trous » des taux — et ses effectifs ne comptent pas dans
  le taux global. Pour un `nombre`, null vaut 0 (un compteur n'est pas
  « non mesurable »). Taux global = Σnumérateur / Σdénominateur, masqué si
  Σdénominateur < 5 (`core/external_metrics.dart`, testé).
- **Heures → jours** : l'API n'a pas d'heures. Une fenêtre horaire demande
  `granularite=jour` et la carte affiche un point par jour (`externalUnitOf`).
  `a` = le jour qui contient `w.end - 1 ms` (`end` est exclusif : pile à minuit,
  c'est la veille ; `metricsRangeFor`, testé). `semaine` n'est jamais demandée :
  Glance n'a pas de granularité hebdomadaire.
- **Stockage** : URL dans les prefs (`glance.metricsSources`), **jeton dans le
  secure storage** (`glance.metricsToken.<compte>.<site>`), jamais en prefs.
  `MetricsSourcesNotifier.remove` supprime aussi le jeton. L'URL s'accepte avec
  ou sans slash final, avec ou sans `https://`.
- **Client** : `data/providers/metrics_api.dart`, exceptions typées
  (`MetricsNotConfigured`, `MetricsBadToken`, `MetricsBadRequest`,
  `MetricsUnsupportedVersion`) dont le `message` s'affiche tel quel sur la carte.
  `indicatorDataProvider` ne relance pas ces erreurs (`retryUnlessMetricsError`) :
  sinon la carte resterait en squelette pendant la trentaine de secondes de relances
  par défaut de Riverpod. Un User-Agent de navigateur est posé (Cloudflare : 403 / 1010).
- **Carte** : libellé et unité sont **copiés du catalogue à la création** pour que
  l'en-tête se dessine avant la réponse du catalogue. En-tête « Métrique », corps
  comme un Taux (`numérateur / dénominateur`) ou un Compteur.
- **Pourquoi `external` n'est pas dans `supportedIndicatorsFor`** : la
  disponibilité dépend de la source du **site**, pas du fournisseur d'analytics du
  **compte**. Le sélecteur de genre (`IndicatorEditor._kinds`) et la visibilité de
  l'onglet (`siteHasMetricsSourceProvider`) la décident séparément.
- **Interface** : lien « Source de métriques » en bas de l'onglet (et dans l'état
  vide) → `ui/dashboards/metrics_source_screen.dart` (URL, jeton, « Tester » qui
  appelle `catalogue`, « Enregistrer », « Retirer la source »).
- **Synchro** : clé `metricSources` **facultative** du paquet `glance-sync`
  (`{site, url, token}`), `SyncCrypto.version` reste à 1 (même raison que
  `indicators`). Le jeton voyage dans le blob chiffré de bout en bout, comme les
  identifiants des comptes. Fusion par site (l'entrante gagne), une suppression
  ne se propage pas, et le **QR de transfert ne l'emporte pas**.
- **Délai de mesure (`delai_jours`)** : champ facultatif du catalogue (J1 → 1,
  J7 → 7, J30 → 30 ; absent ou 0 pour un `nombre`). La cohorte du jour J n'est
  mesurable qu'une fois J + délai terminé : sa valeur est **mesurée** à la date
  J + délai. Chaque point est donc **placé à sa date de mesure** : la carte
  demande les cohortes de `[début − d, fin − d]` (`metricsRangeFor(delayDays:)`) et
  `externalDataOf` range chaque point à `t + d`. L'axe reste **celui de la
  période choisie**, comme sur toutes les autres cartes (un décalage de fenêtre
  donnait un axe sans rapport avec la période, et une seule cohorte sur
  « Aujourd'hui »). Sur « 7 jours » (15 → 21 oct.), J7 montre les cohortes du 8 au
  14 oct. aux dates du 15 au 21.
  - Un point dont le jour de mesure n'est pas terminé (aujourd'hui) reste un trou,
    quoi que réponde le serveur ; ses effectifs ne comptent pas dans le total.
    Donc « Aujourd'hui » en J1 n'a rien de mesurable : « Pas encore mesurable sur
    cette période » (`RatioData.pending`, dénominateurs > 0 mais aucun point
    mesurable), pas « Aucune donnée ».
  - **En mois** : on demande des mois au serveur, on décale chaque bucket de `d`
    jours puis on le rattache au mois (`truncateBucket`). On ne regroupe pas des
    cohortes journalières côté client : le serveur agrège le mois entier, alors
    que chaque jour isolé tombe souvent sous le seuil de confidentialité. Limite :
    à partir de J28, deux mois voisins peuvent retomber dans le même bucket.
  - **Libellés** : « Mesurée sur les cohortes du 8 au 14 oct. » (ou « …sur la
    cohorte du 19 oct. »), bornes = première et dernière cohortes **mesurées** de
    la carte. Infobulle : « 20 oct. · cohorte du 13 oct. · 15,4 % » (en jours).
  - Le délai est lu **à l'exécution** dans le catalogue (`metricsCatalogueProvider`,
    en cache), pas figé dans l'`ExternalIndicator` : les cartes existantes en
    profitent et le serveur reste la source de vérité. Catalogue en échec (ou
    vieux serveur) → délai 0, et le catalogue n'est pas relancé (une relance
    garderait les cartes en squelette).
  - ⚠️ `now` se lit **dans** le provider : la clé de `indicatorDataProvider` ne
    change pas (cf. « Chargement infini »).
- **Familles** : le catalogue peut porter, par indicateur, `famille` et
  `libelle_famille` (facultatifs). Les membres d'une famille ne diffèrent que par
  leur `delai_jours` (J1, J7, J30). `metricFamiliesOf` les regroupe (membres triés
  par délai) ; l'éditeur propose d'abord les familles, puis les métriques sans
  famille. Un `ExternalIndicator` vise une métrique (`metric`) **ou** une famille
  (`family`) ; le membre est choisi **au calcul** : le plus grand délai ≤ durée de
  la fenêtre en jours (`windowDays`, arrondie au-dessus : « Aujourd'hui » et
  « 24 h » → J1, « 7 jours » → J7, « Ce mois-ci » le 21 → J7, « 12 m » → J30),
  sinon le plus court (`chooseFamilyMember`, pure, testée). Pourquoi : une carte
  J7 sur « Aujourd'hui » n'a rien de mesurable, d'où six cartes vides ; une seule
  carte suit la période. La carte porte le nom de la famille et la ligne
  « J7 · s'ajuste à la période ».
  - ⚠️ En JSON, une famille écrit **aussi** `metric` (= son membre de plus long
    délai), `label` et `unit` : `Indicator.fromJson` d'une app antérieure lit
    `metric` sans condition et planterait sinon. Elle affiche alors cette
    métrique réelle.
- **Onglet : les cartes sans données sont masquées** (tous types, pas l'aperçu de
  l'éditeur). `hasDisplayableData` (pure, `core/indicator_math.dart`) : taux sans
  dénominateur mesuré, compteur à 0 partout, entonnoir sans première étape,
  répartition vide. L'onglet lit les mêmes providers que les cartes (même clé,
  donc aucune requête de plus). Chargement → squelette ; **erreur → carte
  affichée** (il faut pouvoir la corriger). Une ligne « 3 tableaux sans données
  sur cette période · Afficher » les rend, jusqu'au prochain changement de
  période (leur menu ⋯ disparaît avec elles) ; tout masqué → « Aucun tableau n'a
  de données sur cette période ».
- **Cartes lisibles (tous les types)** : un graphique à moins de 2 points non nuls
  n'est pas dessiné (la carte garde son chiffre et ses lignes) ; sans point
  mesurable, seul le message ; un compteur à 0 partout affiche « 0 » et « Aucun
  événement sur la période », sans courbe plate. La ligne de contexte (requête,
  libellé) est omise quand elle répète le titre : toujours pour une métrique de
  site, sinon si elle ne diffère que par les séparateurs (` ÷ `/` / `, ` · `/` par `).
- **Retirer une source supprime aussi ses cartes « Métrique »** : sans elle elles
  afficheraient « Jeton refusé » pour toujours. La confirmation et le toast
  annoncent le nombre de tableaux emportés.
- ⚠️ Le serveur refuse plus de 400 jours : `metricsRangeFor` ramène `de` à
  `a − 399 jours` (« Tout », période perso). Les buckets d'avant la borne restent
  vides : trou pour un %, 0 pour un nombre.

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
- **Tableaux** (vérifié sur l'instance 3.3.0, le 2026-10-20) :
  - `/events/series?event=&epfN=` → `[{x: nom, t, y}]`.
  - `/event-data/properties?event=` → `[{eventName, propertyName, dataType, total}]`.
  - `/event-data/values?event=&propertyName=` → `[{value, total}]`.
  - `POST /api/reports/funnel` → par étape, `{visitors, previous, dropped, dropoff, remaining}`.
- ⚠️ Cloudflare devant l'instance renvoie **403 / 1010** à un client sans
  User-Agent de navigateur ou de curl (urllib Python, par exemple). Ça compte pour
  les scripts de sonde, pas pour l'app.

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
- ⚠️ **Xcode 27 casse idb.** `SimulatorKit.framework` est passé de
  `Contents/Developer/Library/PrivateFrameworks` à `Contents/SharedFrameworks`, et
  `idb ui tap` échoue même avec `DEVELOPER_DIR`. Pour vérifier un écran sans clic :
  - une modification temporaire non commitée qui ouvre l'écran au lancement ;
  - `flutter run` avec l'entrée standard sur un fifo : `mkfifo f; (tail -f /dev/null > f &); flutter run … < f` ;
  - `echo r > f` pour recharger, `echo R > f` pour redémarrer, `echo q > f` pour quitter.

  Les parcours (taper, saisir) passent par des tests de widgets. Même cause pour
  le build : `flutter build ios --simulator` échoue (bug `lipo` ci-dessous), alors
  que `flutter run -d <udid>`, qui ne compile qu'une architecture, passe.
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
