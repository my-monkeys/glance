# Fiche Google Play — Glance

Textes à coller dans la Play Console (package `fr.mymonkey.glance`). Langue par défaut :
**français (fr-FR)**, plus **anglais (en-US)**. Les autres langues viendront avec la traduction de
l'app (ticket #16).

Les limites de Google sont entre crochets ; `python3 -I store/compter.py` les vérifie. Les visuels
vivent dans `store/visuels/google-play/` : captures téléphone 1080 × 1920 (8 par langue) et image de
présentation 1024 × 500 (`presentation-<langue>.png`).

Ce qui reste de `store/play/listing.md` : catégorie (Outils), coordonnées, déclaration Data safety
(aucune collecte), questionnaire IARC (tout public). Rien de cela ne change.

## Français (fr-FR)

**Titre** [30]

```
Glance: Umami & Plausible
```

**Description courte** [80]

> Vos stats Umami et Plausible : tableaux, événements, entonnoir, prévision.

**Description complète** [4000]

```
Glance est le client mobile et bureau d’Umami et de Plausible. Tous vos sites d’un coup d’œil, et de vrais tableaux pour comprendre ce qui s’y passe. Rien n’est collecté : l’appli ne parle qu’à vos serveurs.

VOS SITES, RÉUNIS
• Plusieurs comptes Umami et Plausible dans une seule liste, avec un total et une courbe lissée.
• Chaque site s’affiche dès que sa donnée arrive. Recherche par nom ou domaine, groupes, vue liste ou grille.
• Aujourd’hui, 24 h, 7 jours, 30 jours, ce mois-ci, 12 mois, cette année ou une plage libre, avec la comparaison à la période précédente.

DES TABLEAUX À VOTRE MESURE
• Compteurs, taux et répartitions : composez vos indicateurs à partir des événements de vos sites.
• Croisez vos sites : plusieurs sites côte à côte, une courbe par site plus le total, avec un filtre « venus de » ou « sauf venus de » un domaine.
• Une grille que vous organisez au doigt : on déplace et on redimensionne chaque carte.

CHAQUE ÉVÉNEMENT, SA COULEUR
• Une courbe par événement, filtrable par propriété (plan = pro, montant ≥ 20…).
• La répartition des valeurs d’une propriété, et son évolution dans le temps.

L’ENTONNOIR
• De 2 à 8 étapes, avec le nombre de visiteurs et le taux de perte à chaque passage. Propre à Umami.

LA RÉTENTION, CALCULÉE SUR VOTRE BASE
• Branchez une source de métriques : une petite API sur votre site, protégée par un jeton.
• Glance affiche alors la rétention J1, J7 et J30, les comptes créés, tout indicateur que votre site expose, avec ses effectifs.
• Une carte peut suivre la période : J1 sur une journée, J7 sur 30 jours, J30 sur un an.

ANTICIPEZ LA FIN DU MOIS
• Sur « ce mois-ci » et « cette année », la courbe se prolonge en pointillé orange, avec le total attendu. La prévision part du niveau des 7 derniers jours et du rythme de la semaine.

EN DIRECT, JUSQUE SUR L’ÉCRAN D’ACCUEIL
• Les visiteurs présents maintenant sur chaque site, triés par activité.
• Des widgets pour vos totaux ou pour un site précis.

SUR TOUS VOS APPAREILS
• Android, iPhone, Mac et Windows, en clair comme en sombre.
• Un QR code chiffré pour reprendre votre configuration en un scan, ou une synchronisation chiffrée de bout en bout entre vos appareils (option, achat unique).

VIE PRIVÉE
• Aucun serveur intermédiaire : Glance parle directement à vos instances.
• Vos identifiants restent chiffrés sur l’appareil. Accès en lecture seule.
• Pas de publicité, pas de pistage.

OUTILS SUPPORTÉS
• Umami, auto-hébergé.
• Plausible, Cloud ou auto-hébergé : compteurs, taux et répartitions.
• Fathom : bientôt.

Glance est un projet du collectif My-Monkey. Vos retours sont les bienvenus.
```

## English (en-US)

**Title** [30]

```
Glance: Umami & Plausible
```

**Short description** [80]

> Your Umami and Plausible stats: dashboards, events, funnels, forecasts.

**Full description** [4000]

```
Glance is the mobile and desktop client for Umami and Plausible. All your sites at a glance, plus real dashboards to understand what is happening on them. Nothing is collected: the app only talks to your own servers.

ALL YOUR SITES, TOGETHER
• Several Umami and Plausible accounts in one list, with a total and a smooth chart.
• Each site shows up as soon as its data arrives. Search by name or domain, groups, list or grid view.
• Today, 24 h, 7 days, 30 days, this month, 12 months, this year or a custom range, compared with the previous period.

DASHBOARDS YOUR WAY
• Counters, rates and breakdowns: build your own indicators from your sites' events.
• Compare your sites: several sites side by side, one curve per site plus the total, with a "from" or "excluding visitors from" filter on a domain.
• A grid you arrange by hand: move and resize each card.

EVERY EVENT, ITS OWN COLOR
• One curve per event, filterable by property (plan = pro, amount ≥ 20...).
• The breakdown of a property's values, and how it evolves over time.

THE FUNNEL
• From 2 to 8 steps, with the number of visitors and the drop-off at every step. Umami only.

RETENTION, COMPUTED ON YOUR OWN DATABASE
• Plug in a metrics source: a small API on your site, protected by a token.
• Glance then shows D1, D7 and D30 retention, accounts created, any indicator your site exposes, with its counts.
• A card can follow the period: D1 over a day, D7 over 30 days, D30 over a year.

SEE THE MONTH'S END COMING
• On "this month" and "this year", your curve continues as an orange dotted line, with the expected total. The forecast starts from the last 7 days' level and the weekly rhythm.

LIVE, RIGHT ON YOUR HOME SCREEN
• Who is on each site right now, sorted by activity.
• Widgets for your totals or for a specific site.

ON ALL YOUR DEVICES
• Android, iPhone, Mac and Windows, in light and dark.
• An encrypted QR code to pick up your setup in one scan, or end-to-end encrypted sync between your devices (optional, one-time purchase).

PRIVACY
• No middle server: Glance talks straight to your instances.
• Your credentials stay encrypted on the device. Read-only access.
• No ads, no tracking.

SUPPORTED TOOLS
• Umami, self-hosted.
• Plausible, Cloud or self-hosted: counters, rates and breakdowns.
• Fathom: coming soon.

Glance is a project by the My-Monkey collective. Your feedback is welcome.
```
