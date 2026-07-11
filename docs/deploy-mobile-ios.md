# Déploiement iOS — Codemagic + TestFlight (Glance)

Pipeline iOS de Glance. Réutilise l'infra Codemagic **déjà en place pour piloo** :
rien à régénérer côté Apple, tout est account-level dans Codemagic.

> **Stack** : Codemagic (`codemagic.yaml` à la racine).
> **Trigger** : tag git `vX.Y.Z`.
> **Sortie** : build signé uploadé sur TestFlight.

---

## Ce qui est réutilisé de piloo (aucune action)

Ces ressources Codemagic sont partagées par tout le compte, Glance les référence
telles quelles dans `codemagic.yaml` :

| Ressource | Où | Rôle |
|---|---|---|
| Intégration **« Personnal »** (App Store Connect API key) | `Teams → Integrations → App Store Connect` | Auth CI ↔ Apple : fetch cert/profil, upload TestFlight |
| Groupe de variables **`ios_signing`** (`CERTIFICATE_PRIVATE_KEY`) | `Teams → Environment variables` | Certif de distribution auto-géré |

Le bundle ID `fr.mymonkey.glance` et son provisioning profile App Store sont
**auto-créés** au premier build via `app-store-connect fetch-signing-files --create`.

---

## Setup one-time (à faire une seule fois)

### 1. Pousser le repo sur GitHub
Fait : `my-monkeys/glance` (privé). Codemagic build depuis là.

### 2. Créer l'app dans Codemagic
1. `codemagic.io` → **Add application** → GitHub → sélectionner `my-monkeys/glance`.
2. Type : **Flutter App**. Codemagic détecte le `codemagic.yaml` à la racine.
3. Vérifier que l'intégration `Personnal` et le groupe `ios_signing` sont bien
   visibles (ils le sont, account-level).

### 3. Créer l'enregistrement app dans App Store Connect
Le build ne peut uploader que si l'app existe côté ASC. Une seule fois :
- `appstoreconnect.apple.com` → **Apps → +** → New App
  - Plateforme : **iOS**
  - Nom : **Glance — Analytics**
  - Langue principale : **Français (France)**
  - Bundle ID : **`fr.mymonkey.glance`** (le sélectionner ; auto-créé par le 1er build de signing, sinon le créer dans *Certificates, Identifiers & Profiles*)
  - SKU : **`glance-mymonkey`**
- Les métadonnées (titre, description, mots-clés, captures…) → cf. `store/metadata.md`.

### 4. (Optionnel) Beta group TestFlight
Pour distribuer à des testeurs : ASC → TestFlight → créer un groupe interne, puis
ajouter `beta_groups: ["<nom>"]` sous `publishing.app_store_connect` dans le yaml.
Sans ça, le build arrive dans TestFlight mais n'est notifié à personne.

---

## Runbook de release

```bash
# 1. Repo propre, tests verts en local.
flutter analyze --no-fatal-infos && flutter test

# 2. Tagger (déclenche le workflow ios-testflight).
git tag v1.0.0
git push origin v1.0.0

# 3. Suivre : codemagic.io/app/<id>/builds  (~8–12 min sur mac_mini_m2).
# 4. Build vert → apparaît dans ASC → TestFlight (Processing ~5–15 min).
```

Le `codemagic.yaml` dérive `version:` du tag (`v1.0.0` → `1.0.0+<build monotone>`),
donc **ne pas** bumper `pubspec.yaml` à la main pour une release — juste tagger.

---

## Qui gère quoi

| Élément | Géré par |
|---|---|
| API key ASC (`.p8`) | Intégration Codemagic « Personnal » (déjà en place) |
| Distribution certificate | Codemagic via `CERTIFICATE_PRIVATE_KEY` (auto, ~1 an) |
| Provisioning profile | Auto (`fetch-signing-files --create`) |
| Build number | Codemagic (monotone, garantit l'unicité App Store) |
| Métadonnées store | Manuel dans ASC (source : `store/metadata.md`) |
