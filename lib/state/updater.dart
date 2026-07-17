import 'dart:io' show Platform;

import 'package:auto_updater/auto_updater.dart';

/// Mises à jour automatiques des versions **desktop** (téléchargement direct,
/// hors store) via Sparkle sur macOS et WinSparkle sur Windows — le même moteur
/// et le même modèle d'« appcast » qu'OpenSuperWhisper.
///
/// L'app interroge le flux (`appcast.xml` hébergé sur le repo), compare à sa
/// version et, si une plus récente existe, propose de la télécharger et de
/// l'installer — signature vérifiée par la clé publique de l'`Info.plist`.
///
/// iOS/Android ne passent pas par ici : leurs mises à jour viennent des stores.
class Updater {
  Updater._();

  /// Flux des versions macOS (signé EdDSA). Windows aura le sien quand son
  /// portage sera fait (clé DSA + ressource WinSparkle).
  static const _macFeed =
      'https://raw.githubusercontent.com/my-monkeys/glance/main/appcast.xml';

  /// Vérification auto une fois par jour (le minimum Sparkle est 1 h).
  static const _dailySeconds = 86400;

  static bool get isSupported => Platform.isMacOS; // Windows : à venir.

  static String? get _feed => Platform.isMacOS ? _macFeed : null;

  /// À appeler au démarrage : arme la vérification périodique en fond.
  static Future<void> init() async {
    final feed = _feed;
    if (feed == null) return;
    await autoUpdater.setFeedURL(feed);
    await autoUpdater.setScheduledCheckInterval(_dailySeconds);
  }

  /// Vérification manuelle (bouton des réglages) : montre l'UI Sparkle, y
  /// compris « vous êtes à jour ».
  static Future<void> checkNow() async {
    if (_feed == null) return;
    await autoUpdater.checkForUpdates(inBackground: false);
  }
}
