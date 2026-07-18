import 'dart:io' show Platform;

import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

/// Résultat d'une tentative d'achat.
enum PurchaseOutcome { purchased, cancelled, error }

/// Fine surcouche RevenueCat pour l'achat unique « Glance Sync ».
///
/// Le serveur reste la source de vérité du statut Pro (posé par le webhook
/// RevenueCat) : ce service ne fait qu'identifier l'utilisateur (pour que
/// `app_user_id` = id Better Auth) et déclencher l'achat. L'achat n'a lieu que
/// sur **iOS/Android** ; sur desktop le Pro est hérité du même compte via la
/// sync serveur, donc aucun IAP desktop n'est requis.
class PurchasesService {
  /// Identifiant de l'entitlement configuré côté RevenueCat.
  static const entitlementId = 'sync';

  /// Clés publiques du SDK, injectées au build (vides tant que RevenueCat
  /// n'est pas configuré → la fonctionnalité d'achat reste désactivée).
  static const _appleKey = String.fromEnvironment('REVENUECAT_APPLE_KEY');
  static const _androidKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');

  bool _configured = false;

  String? get _platformKey {
    // IAP mobile uniquement : sur macOS/Windows le Pro est hérité du compte.
    if (Platform.isIOS) return _appleKey.isEmpty ? null : _appleKey;
    if (Platform.isAndroid) return _androidKey.isEmpty ? null : _androidKey;
    return null;
  }

  /// Vrai si l'achat in-app est réellement disponible ici (store mobile + clé
  /// fournie). Sur macOS/Windows on renvoie false : pas d'IAP, Pro par compte.
  bool get supported => (Platform.isIOS || Platform.isAndroid) && _platformKey != null;

  /// Configure le SDK une seule fois. Sans-op si non supporté.
  Future<void> configure() async {
    if (_configured || _platformKey == null) return;
    await Purchases.configure(PurchasesConfiguration(_platformKey!));
    _configured = true;
  }

  /// Lie l'utilisateur courant à son id Better Auth (= `app_user_id` du webhook).
  Future<void> identify(String userId) async {
    if (!_configured) return;
    await Purchases.logIn(userId);
  }

  /// Repasse en utilisateur anonyme (déconnexion du compte Glance Sync).
  Future<void> reset() async {
    if (!_configured) return;
    try {
      await Purchases.logOut();
    } on PlatformException {
      // Déjà anonyme : sans importance.
    }
  }

  /// Vrai si l'entitlement est actif côté store (achat déjà effectué/restauré).
  Future<bool> isEntitled() async {
    if (!_configured) return false;
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey(entitlementId);
  }

  /// Lance l'achat du premier package de l'offering courant.
  Future<PurchaseOutcome> buy() async {
    if (!_configured) return PurchaseOutcome.error;
    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings.current?.availablePackages.firstOrNull;
      if (package == null) return PurchaseOutcome.error;
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return result.customerInfo.entitlements.active.containsKey(entitlementId)
          ? PurchaseOutcome.purchased
          : PurchaseOutcome.error;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      return code == PurchasesErrorCode.purchaseCancelledError
          ? PurchaseOutcome.cancelled
          : PurchaseOutcome.error;
    }
  }

  /// Restaure un achat déjà effectué (bouton « Restaurer »).
  Future<bool> restore() async {
    if (!_configured) return false;
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey(entitlementId);
    } on PlatformException {
      return false;
    }
  }
}
