# Déploiement iOS — build local + TestFlight (Glance)

Build signé **depuis le Mac** (pas de CI). App Store Connect via le compte Apple
My-Monkey (team `5C67TFSJ2B`, la même que piloo).

> **Sortie** : `.ipa` App Store signé → upload TestFlight.

---

## Pré-requis (déjà en place)

| Élément | État |
|---|---|
| Apple Developer Program (team `5C67TFSJ2B`) | ✅ |
| Certif **Apple Distribution: Maxim Costa (5C67TFSJ2B)** dans le trousseau | ✅ |
| Xcode 27 + compte Apple connecté | ✅ |
| Signature projet : `DEVELOPMENT_TEAM = 5C67TFSJ2B`, automatique | ✅ (dans `ios/Runner.xcodeproj`) |

**Une seule action manuelle restante** : créer l'app dans App Store Connect
(obligatoire avant le 1er upload) — *Apps → +* :
- Nom : **Glance — Analytics** · Bundle : **`fr.mymonkey.glance`** · SKU : **`glance-mymonkey`** · Plateforme iOS
- Le bundle ID côté *Certificates, Identifiers & Profiles* est auto-créé par la signature automatique de Xcode.

---

## Build de l'IPA

```bash
# depuis la racine du projet
flutter clean
flutter build ipa --release
# → build/ios/ipa/glance.ipa
```

La signature est automatique : Xcode récupère/crée le provisioning profile
App Store pour `fr.mymonkey.glance` via le compte connecté.

Pour bumper la version avant un build : éditer `version:` dans `pubspec.yaml`
(`X.Y.Z+build`, incrémenter le `+build` à chaque upload).

---

## Upload TestFlight — 3 options

### A. Transporter (le plus simple, GUI)
1. Installer **Transporter** (Mac App Store, gratuit, Apple).
2. Se connecter avec l'Apple ID, glisser `build/ios/ipa/glance.ipa`, **Deliver**.

### B. Xcode Organizer (tout-en-un)
1. Ouvrir `ios/Runner.xcworkspace` dans Xcode.
2. *Product → Archive* → l'Organizer s'ouvre.
3. *Distribute App → App Store Connect → Upload*. Xcode signe et envoie.

### C. Ligne de commande (clé API App Store Connect)
Générer une clé (ASC → *Users and Access → Integrations → App Store Connect API*,
rôle App Manager) → `AuthKey_XXXX.p8` + Key ID + Issuer ID. Puis :
```bash
xcrun altool --upload-app -t ios \
  -f build/ios/ipa/glance.ipa \
  --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
# le .p8 doit être dans ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8
```

---

## Après l'upload

- Le build apparaît dans ASC → **TestFlight** (Processing ~5–15 min).
- Renseigner les *Test Details* (compte démo : cf. `store/metadata.md`).
- Inviter les testeurs (internes ≤ 100, ou groupe externe + review bêta légère).
- Métadonnées de la fiche App Store : `store/metadata.md`. Captures : `store/screenshots/`.

## Signature — qui fait quoi

| Élément | Géré par |
|---|---|
| Distribution certificate | Trousseau local (`Apple Distribution … 5C67TFSJ2B`) |
| Provisioning profile App Store | Auto (Xcode automatic signing, `-allowProvisioningUpdates`) |
| Build number | Manuel (`pubspec.yaml`, incrémenter le `+build`) |
| App record ASC | Manuel, une fois (voir plus haut) |
