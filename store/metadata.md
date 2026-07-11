# Glance — App Store / TestFlight

Métadonnées prêtes pour App Store Connect (langue principale : **Français (FR)**).
À saisir dans ASC → App Information / Version. Distribution via **Codemagic** (réutilise
l'infra iOS de piloo) — cf. `docs/deploy-mobile-ios.md`.

## Identité

| Champ | Valeur |
|---|---|
| Nom (30 max) | **Glance — Analytics** |
| Sous-titre (30 max) | **Vos stats, d'un coup d'œil** |
| Nom d'app (écran d'accueil) | Glance |
| Bundle ID | `fr.mymonkey.glance` |
| SKU | `glance-mymonkey` |
| Catégorie principale | Productivité |
| Catégorie secondaire | Économie et entreprise |
| Classification d'âge | 4+ |
| Prix | Gratuit |

## Texte promotionnel (170 max, modifiable sans review)

> Nouveau : graphes multi-courbes, événements par site, navigation jour par jour et vos favicons directement dans l'app.

## Description (4000 max)

Glance met toutes vos statistiques web dans votre poche — sans prise de tête.

Connectez votre instance Umami ou Plausible, choisissez les sites à suivre, et retrouvez l'essentiel en un coup d'œil : visiteurs, visites, pages vues, sources, pays, pages populaires et événements. Le tout dans une interface soignée, rapide, en clair comme en sombre.

CE QUE VOUS POUVEZ FAIRE
• Suivre plusieurs sites et plusieurs comptes au même endroit
• Voir le trafic en temps réel — qui est là, maintenant, sur chacun de vos sites
• Explorer chaque site en détail : courbes lissées avec échelles, pages, sources, pays, durée, rebond
• Suivre vos événements personnalisés, une couleur par événement, filtrables
• Naviguer dans le temps : aujourd'hui, hier, 7 / 30 jours, 12 mois, ou une plage perso
• Basculer entre vue liste et vue grille, trier par visiteurs
• Masquer une courbe pour mieux lire les autres

PENSÉE POUR LE RESPECT DE LA VIE PRIVÉE
Glance ne collecte rien. Vos identifiants restent dans le trousseau de votre appareil, et l'app ne parle qu'à VOS serveurs analytics — jamais à un tiers. Accès en lecture seule : Glance affiche vos données, ne les modifie pas.

OUTILS SUPPORTÉS
• Umami (auto-hébergé)
• Plausible (Cloud ou auto-hébergé)
• Fathom : bientôt

Glance est un projet du collectif My-Monkey. Vos retours sont les bienvenus.

## Mots-clés (100 max, séparés par des virgules)

`analytics,umami,plausible,statistiques,visiteurs,trafic,web,tableau de bord,temps réel,audience,fathom`

## URLs

| Champ | Valeur | Statut |
|---|---|---|
| URL de support | `https://glance.my-monkey.fr` (ou page support dédiée) | ⚠️ à créer/héberger |
| URL marketing (option) | `https://glance.my-monkey.fr` | ⚠️ à créer |
| Politique de confidentialité | `https://glance.my-monkey.fr/privacy` | ⚠️ **obligatoire** — à héberger (texte prêt ci-dessous) |

> Option rapide : une petite page statique déployée via `.monkey` sur `glance.my-monkey.fr` (landing + /privacy). Je peux la faire.

## Confidentialité App Store (App Privacy)

**Data Not Collected** — l'app ne collecte aucune donnée. Justification : les identifiants sont stockés localement (Keychain), les requêtes vont uniquement vers l'instance analytics de l'utilisateur, aucune donnée n'est envoyée à My-Monkey ni à un tiers, pas de tracking, pas de SDK analytique tiers dans l'app.

## Notes pour l'App Review (démo)

L'app nécessite un compte analytics pour être testée. Fournir à Apple un compte de démonstration :

```
Fournisseur : Umami
URL instance : uuu.my-monkey.fr
Utilisateur : glance
Mot de passe : <voir scratchpad / à coller dans App Store Connect>
```

Étapes de test pour le reviewer :
1. Ouvrir l'app → « Ajouter une source » → Umami.
2. Saisir l'URL, l'utilisateur et le mot de passe ci-dessus → Continuer.
3. Choisir « Tous les sites » (ou quelques-uns) → Suivre.
4. Le tableau de bord se remplit avec des données réelles.

## Build

| Champ | Valeur |
|---|---|
| Version marketing | 1.0.0 |
| Build | 1 (incrémenter à chaque upload) |
| Deployment target | iOS 15.0 |
| Devices | iPhone (portrait) |

## Distribution (build local → TestFlight)

Build signé depuis le Mac (team `5C67TFSJ2B`, certif de distribution déjà dans le
trousseau). Runbook : **`docs/deploy-mobile-ios.md`**. Étapes :

1. **App Store Connect** → *Apps → +* → créer l'app (nom, bundle `fr.mymonkey.glance`, SKU `glance-mymonkey`). *(seule action manuelle)*
2. `flutter build ipa --release` → `build/ios/ipa/glance.ipa`.
3. Upload via **Transporter** (glisser l'IPA) ou Xcode Organizer.

## Reste à produire

- [x] Icône iOS — concept « Courbe » (sparkline), `store/icon_master.svg` → appiconset
- [x] Captures d'écran stylisées 6.9" (1290×2796) — 5 visuels dans `store/screenshots/`
- [ ] Page confidentialité + support hébergée (`glance.my-monkey.fr/privacy`)
- [ ] Créer l'app dans App Store Connect + connecter le repo à Codemagic (cf. `docs/deploy-mobile-ios.md`)

### Captures (ordre suggéré dans ASC)
1. `01-apercu.png` — Tous vos sites, d'un coup d'œil
2. `02-events.png` — Vos événements, une couleur chacun
3. `03-detail.png` — Chaque site, dans le détail
4. `04-grille.png` — Liste ou grille, comme vous voulez
5. `05-direct.png` — Le trafic, en temps réel
