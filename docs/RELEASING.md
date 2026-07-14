# Releasing (macOS)

The macOS build is distributed **outside the Mac App Store**: signed with a
Developer ID Application certificate, notarized by Apple, shipped as a DMG on
GitHub Releases and installed via the Homebrew cask
`my-monkeys/tap/glance`.

## Prerequisites (one-off)

- **Developer ID Application** certificate in the login keychain
  (`security find-identity -v -p codesigning` → `Developer ID Application: … (5C67TFSJ2B)`).
- App Store Connect API key for `notarytool` at
  `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8` (+ key id + issuer id).

## ⚠️ Gotcha — build with **stable Xcode**, not Xcode-beta

Xcode-beta 27's `lipo` has stricter CLI parsing that breaks Flutter's
`thinFramework` step (`lipo <file> -verify_arch arm64 x86_64` →
*"requires exactly one input file"*), so `flutter build macos` fails at packaging
with *"does not contain architectures"*. Force the stable Xcode for the build:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

## Steps

```sh
# 1. Build (universal arm64 + x86_64)
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer flutter build macos --release
APP="build/macos/Build/Products/Release/Glance.app"
ID="Developer ID Application: Maxim Costa (5C67TFSJ2B)"
ENT="macos/Runner/Release-hardened.entitlements"

# 2. Sign inside-out (hardened runtime + timestamp)
find "$APP/Contents/Frameworks" -maxdepth 1 -name "*.framework" \
  -exec codesign --force --options runtime --timestamp --sign "$ID" {} \;
# L'extension widget doit être signée avec SES entitlements (sandbox + app-group),
# pas ceux de l'app — sinon le widget ne partage pas l'App Group une fois distribué.
codesign --force --options runtime --timestamp \
  --entitlements macos/GlanceWidget/GlanceWidget.entitlements --sign "$ID" \
  "$APP/Contents/PlugIns/GlanceWidgetExtension.appex"
codesign --force --options runtime --timestamp --entitlements "$ENT" --sign "$ID" "$APP"
codesign --verify --deep --strict "$APP"

# 3. DMG (with /Applications symlink) + sign it
STAGE=$(mktemp -d); cp -R "$APP" "$STAGE/Glance.app"; ln -s /Applications "$STAGE/Applications"
hdiutil create -volname Glance -srcfolder "$STAGE" -ov -format UDZO Glance-1.0.0.dmg
codesign --force --sign "$ID" --timestamp Glance-1.0.0.dmg

# 4. Notarize + staple
xcrun notarytool submit Glance-1.0.0.dmg \
  --key ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8 \
  --key-id <KEY_ID> --issuer <ISSUER_ID> --wait
xcrun stapler staple Glance-1.0.0.dmg
spctl -a -vvv -t install Glance-1.0.0.dmg      # → accepted, source=Notarized Developer ID

# 5. Release + cask
shasum -a 256 Glance-1.0.0.dmg
gh release create v1.0.0 Glance-1.0.0.dmg --repo my-monkeys/glance --title "Glance 1.0.0"
# then bump version + sha256 in my-monkeys/homebrew-tap → Casks/glance.rb
```

Verify the whole chain: `brew install --cask my-monkeys/tap/glance`.
