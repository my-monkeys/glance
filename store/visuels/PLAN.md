# Visuels des stores — plan

Huit visuels **stylisés** à la place des captures brutes (`store/screenshots/`, `store/play/`, qui
restent en place jusqu'à validation) : une idée par image, mise en avant de ce que les captures ne
montraient pas (tableaux, événements, entonnoir, rétention, prévision). Seul le premier montre une
vraie capture, dans un téléphone dessiné en CSS. La mécanique est celle de GeoDaily
(`geodaily-app/publication/visuels/`), le style est celui de Glance : calme et éditorial.

Ticket : #20. Le site viendra dans un autre lot (il reprendra les mêmes scènes).

## La grammaire commune

- **Palette de l'app** (`lib/theme/palette.dart`) : crème `#F7F5F1`, encre `#211E19`, vert forêt
  `#3B7A5A`, orange prévision `#C98A2E`, brique `#B15A42`, gris chauds ; thème sombre `#16140F` /
  `#201D16` / `#5AA57E`. Un fond par idée, dans cette palette. Ni dégradé violet ou bleu, ni
  glassmorphism, ni émoji.
- **Polices de l'app**, servies depuis `assets/fonts/` : Fredoka (titres, chiffres), Geist (texte),
  JetBrains Mono (étiquettes en capitales espacées).
- **En haut, toujours au même endroit** : l'icône (`store/icon_master.svg`) et « Glance », le titre
  (2 à 5 mots, aligné à gauche), une ligne d'appui. Le bloc fait une hauteur fixe : la scène
  commence au même endroit d'une image à l'autre.
- **En dessous, la scène** : des éléments de l'interface redessinés (cartes arrondies, courbes
  lissées avec aire en dégradé vert, légendes en pastilles, barres de répartition), fidèles à
  `glance_chart.dart`, `events_chart.dart` et `lib/ui/dashboards/`. Les courbes sont tracées par
  `commun.js` (`graphe`, `spark`), lissage monotone comme `isCurved` de fl_chart.
- **Rien n'est inventé** : chaque fonction montrée existe (cf. `CLAUDE.md`). Les chiffres sont des
  exemples, les noms de sites sont fictifs (`atelier-lune.fr`, `carnet.app`, `studio-nord.com`…).
  Exception : le visuel 1 est une vraie capture, avec les sites réels de son compte de démonstration.

## Les visuels, dans l'ordre de la galerie

| # | Fichier | Fond | Titre FR | Titre EN | Ce qu'on voit |
|---|---|---|---|---|---|
| 1 | `1-accueil` | crème | Tous vos sites, d'un coup d'œil | All your sites, at a glance | La vraie capture de l'accueil (`sources/cap-accueil.png`) dans un téléphone ; pastilles Umami, Plausible, rien n'est collecté |
| 2 | `2-sites` | vert forêt | Croisez vos sites | Compare your sites | Le tableau « Sites » : 4 lignes, une courbe par ligne plus le total, parts, filtre « venus de » |
| 3 | `3-evenements` | sable | Suivez chaque événement | Track every event | Courbes à une couleur par événement (`kEventPalette`), compteur filtré par propriété, répartition |
| 4 | `4-entonnoir` | sombre | Voyez où ils décrochent | See where they drop off | Entonnoir en 4 étapes, perte à chaque passage, taux final |
| 5 | `5-retention` | chip `#F0EDE7` | Mesurez la rétention | Measure retention | Trois cartes « Métrique du site » J1, J7, J30 et l'écran « Source de métriques » |
| 6 | `6-prevision` | crème | Anticipez la fin du mois | Forecast your month | Courbe observée, prévision en pointillé orange, total projeté, méthode |
| 7 | `7-direct` | vert forêt | En direct sur l'écran d'accueil | Live, right on your home screen | Visiteurs en direct, widgets iOS et Android sur un écran d'accueil |
| 8 | `8-appareils` | sombre | Sur tous vos appareils | On all your devices | iPhone, Android, Mac, Windows, et la synchronisation chiffrée de bout en bout |

## Les formats

| Store | Dossier | Taille | Nombre |
|---|---|---|---|
| App Store, iPhone 6,9" | `app-store/iphone-6.9/<langue>/` | 1320 × 2868 | 8 par langue |
| App Store, iPad 13" | `app-store/ipad-13/<langue>/` | 2064 × 2752 | 8 par langue, mises en page élargies (grilles à deux colonnes, cartes côte à côte) |
| Google Play, téléphone | `google-play/telephone/<langue>/` | 1080 × 1920 | 8 par langue |
| Google Play, présentation | `google-play/presentation-<langue>.png` | 1024 × 500 | 1 par langue ; texte dans la moitié gauche |

PNG RGB 8 bits, **sans canal alpha** (le script aplatit chaque capture). `planche.png` les montre
tous. Langues rendues : `fr` et `en`.

## Refaire les images

```bash
python3 -I store/visuels/rendre.py                  # tout et la planche (~25 s)
python3 -I store/visuels/rendre.py 4-entonnoir      # un gabarit
python3 -I store/visuels/rendre.py --langue fr      # une langue
```

Prérequis : Playwright pour Python, Google Chrome, Pillow. Le script lance un serveur local sur la
racine du dépôt et imprime `ATTENTION` quand un texte est coupé ou qu'une carte déborde de l'image.
Pour voir un gabarit dans un navigateur : `python3 -m http.server` à la racine, puis
`/store/visuels/gabarits/4-entonnoir.html?lang=en&format=ipad`.

- `--site` : rend la scène seule (sans l'en-tête marque + titre) en WebP, 1320 px de large, dans
  `store/site/img/scenes/<langue>/` (visuels 2 à 8) et `store/site/img/scenes/1-accueil.webp` (le téléphone,
  commun aux langues). Le site pose ses propres titres en HTML ; il charge ces images.
- `gabarits/commun.css` : palette, en-tête, cartes, pastilles, unité `--u`.
- `gabarits/commun.js` : format et langue lus dans l'adresse, textes, nombres localisés
  (`Intl`), données d'exemple déterministes, graphiques.
- `textes/<langue>.json` : **tous** les textes visibles, par visuel (`v1` à `v8`, `presentation`),
  plus `commun`. Les noms d'événements (`signup`, `purchase`…) et les domaines fictifs restent dans
  les gabarits : ce sont des données, pas des textes.

## Ajouter une langue (allemand, espagnol, portugais du Brésil, chinois simplifié)

1. Copier `textes/en.json` en `textes/<langue>.json` (`de`, `es`, `pt-BR`, `zh-Hans`) et traduire.
2. Relancer `rendre.py` : la langue est découverte toute seule, les nombres suivent la locale
   (`LOCALE` dans `commun.js` pour un code à ajouter).
3. Regarder la planche : un titre plus long peut passer à trois lignes (le bloc d'en-tête garde sa
   hauteur, mais l'appui peut alors toucher la scène), et le chinois demande une police CJK
   (Fredoka et Geist n'ont pas les idéogrammes : ajouter un `@font-face`).

## À valider

1. **La capture du visuel 1** montre les sites réels du compte de démonstration (`opensuperwhisper`,
   `tamdoku.fr`…), qui sont des projets My-Monkey. Les huit autres scènes utilisent des noms fictifs.
2. **Visuel 6** : les 30 jours sont des données fixes écrites dans le gabarit (semaine haute,
   week-end bas, un pic le 9, un creux le 14, 2 570 visiteurs sur les 19 jours observés).
3. **Les chiffres** (4 812 visiteurs, 31,4 % de rétention J1, 4 010 projetés…) sont des exemples.
4. **Le visuel 5** suppose que le site de l'utilisateur expose l'API d'agrégats : la fiche le dit
   (« branchez une source de métriques »).
5. **iPad** : les visuels 13" sont faits ; l'app est déclarée iPhone + iPad, la revue d'Apple la
   teste quand même sur iPad.
