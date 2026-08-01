import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync/purchases_service.dart';
import '../data/sync/sync_api.dart';
import '../data/sync/sync_crypto.dart';
import '../data/transfer/config_transfer.dart' show TransferPayload;
import 'providers.dart';
import 'workspaces.dart';

enum SyncStatus { unknown, signedOut, signedIn }

@immutable
class SyncState {
  const SyncState({
    this.status = SyncStatus.unknown,
    this.email,
    this.isPro = false,
    this.lastSyncAt,
    this.busy = false,
    this.error,
    this.notice,
  });

  final SyncStatus status;
  final String? email;
  final bool isPro;
  final DateTime? lastSyncAt;
  final bool busy;
  final String? error;

  /// Message d'information non bloquant (ex. « activation en cours ») —
  /// distinct de [error] pour ne pas afficher du positif en rouge.
  final String? notice;

  SyncState copyWith({
    SyncStatus? status,
    String? email,
    bool? isPro,
    DateTime? lastSyncAt,
    bool? busy,
    String? error,
    String? notice,
    bool clearError = false,
  }) =>
      SyncState(
        status: status ?? this.status,
        email: email ?? this.email,
        isPro: isPro ?? this.isPro,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        busy: busy ?? this.busy,
        error: clearError ? null : (error ?? this.error),
        // clearError remet aussi le notice à zéro : les deux canaux suivent
        // le même cycle de vie (nouvelle opération = messages précédents purgés).
        notice: clearError ? null : (notice ?? this.notice),
      );
}

final syncApiProvider = Provider<SyncApi>(
  (ref) => SyncApi(SecureTokenStore(ref.watch(secureStorageProvider))),
);

final purchasesProvider = Provider<PurchasesService>((_) => PurchasesService());

/// Vrai si l'achat in-app « Glance Sync » est disponible sur cet appareil
/// (store mobile + clé RevenueCat fournie). Faux sur desktop et tant que
/// RevenueCat n'est pas configuré → l'UI reste en « Bientôt disponible ».
final purchasesSupportedProvider =
    Provider<bool>((ref) => ref.read(purchasesProvider).supported);

/// Pilote la synchronisation cloud : auth (Better Auth), chiffrement E2E de la
/// config avec le mot de passe du compte, pull/push du blob.
///
/// Le mot de passe est gardé dans le secure storage de l'appareil (il faut le
/// dériver à chaque opération, sel aléatoire par blob) — jamais côté serveur.
class SyncController extends Notifier<SyncState> {
  static const _kPassword = 'glance.sync.pw';

  SyncApi get _api => ref.read(syncApiProvider);
  PurchasesService get _purchases => ref.read(purchasesProvider);

  /// Vrai pendant l'application d'un pull → évite qu'un push automatique se
  /// déclenche sur les changements qu'on vient d'importer (boucle).
  bool applying = false;

  @override
  SyncState build() {
    Future.microtask(() async {
      await _purchases.configure();
      await _restore();
    });
    return const SyncState();
  }

  Future<String?> _password() =>
      ref.read(secureStorageProvider).read(key: _kPassword);

  Future<void> _restore() async {
    try {
      final user = await _api.session();
      if (user == null) {
        state = state.copyWith(status: SyncStatus.signedOut);
        return;
      }
      state = state.copyWith(
        status: SyncStatus.signedIn,
        email: user.email,
        isPro: user.isPro,
      );
      await _purchases.identify(user.id);
      await pull();
    } catch (_) {
      state = state.copyWith(status: SyncStatus.signedOut);
    }
  }

  Future<bool> signUp(String email, String password) => _enter(
        () => _api.signUp(email, password),
        password,
        (msg) => msg.toLowerCase().contains('exist')
            ? 'Cet e-mail est déjà utilisé.'
            : 'Impossible de créer le compte.',
      );

  Future<bool> signIn(String email, String password) => _enter(
        () => _api.signIn(email, password),
        password,
        (_) => 'E-mail ou mot de passe incorrect.',
      );

  Future<bool> _enter(
    Future<SyncUser> Function() call,
    String password,
    String Function(String backendMessage) frenchError,
  ) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final user = await call();
      await ref.read(secureStorageProvider).write(key: _kPassword, value: password);
      state = state.copyWith(
        status: SyncStatus.signedIn,
        email: user.email,
        isPro: user.isPro,
        busy: false,
      );
      await _purchases.identify(user.id);
      await pull(); // récupère une éventuelle config existante
      return true;
    } on SyncAuthError catch (e) {
      state = state.copyWith(busy: false, error: frenchError(e.message));
      return false;
    } on SyncNetworkError {
      state = state.copyWith(busy: false, error: 'Serveur injoignable.');
      return false;
    }
  }

  Future<void> signOut() async {
    await _api.signOut();
    await _purchases.reset();
    await ref.read(secureStorageProvider).delete(key: _kPassword);
    state = const SyncState(status: SyncStatus.signedOut);
  }

  /// Supprime définitivement le compte (serveur + local). Irréversible : la
  /// config synchronisée est effacée côté serveur et la session est fermée.
  /// Renvoie vrai si la suppression a bien eu lieu.
  Future<bool> deleteAccount() async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _api.deleteAccount();
    } on SyncNetworkError {
      state = state.copyWith(busy: false, error: 'Serveur injoignable. Réessayez.');
      return false;
    } on SyncAuthError {
      state = state.copyWith(
        busy: false,
        error: 'Session expirée. Reconnectez-vous puis réessayez.',
      );
      return false;
    }
    await _purchases.reset();
    await ref.read(secureStorageProvider).delete(key: _kPassword);
    state = const SyncState(status: SyncStatus.signedOut);
    return true;
  }

  /// Achète « Glance Sync » (achat unique). L'achat déclenche le webhook
  /// RevenueCat qui pose `isPro` côté serveur ; on attend cette bascule avant
  /// de confirmer, puis on lance une première synchro. Renvoie vrai si le Pro
  /// est actif à l'issue de l'appel.
  Future<bool> buyPro() async {
    if (state.status != SyncStatus.signedIn) return false;
    state = state.copyWith(busy: true, clearError: true);
    final outcome = await _purchases.buy();
    switch (outcome) {
      case PurchaseOutcome.cancelled:
        state = state.copyWith(busy: false);
        return false;
      case PurchaseOutcome.error:
        state = state.copyWith(busy: false, error: 'Achat impossible. Réessayez.');
        return false;
      case PurchaseOutcome.purchased:
        final activated = await _awaitProActivation();
        if (activated) {
          state = state.copyWith(busy: false, isPro: true, clearError: true);
          await push();
          return true;
        }
        state = state.copyWith(
          busy: false,
          notice: 'Achat validé — activation en cours, réessayez la sync dans un instant.',
        );
        return false;
    }
  }

  /// Restaure un achat existant (changement d'appareil, réinstallation).
  /// Renvoie vrai si le Pro est actif à l'issue de l'appel.
  Future<bool> restorePurchase() async {
    if (state.status != SyncStatus.signedIn) return false;
    state = state.copyWith(busy: true, clearError: true);
    final entitled = await _purchases.restore();
    if (!entitled) {
      state = state.copyWith(busy: false, notice: 'Aucun achat à restaurer.');
      return false;
    }
    final activated = await _awaitProActivation();
    if (activated) {
      state = state.copyWith(busy: false, isPro: true, clearError: true);
      await push();
      return true;
    }
    state = state.copyWith(busy: false, notice: 'Achat restauré — activation en cours…');
    return false;
  }

  /// Demande au serveur de vérifier l'achat auprès de RevenueCat (avec retries
  /// le temps que la transaction se propage côté RevenueCat).
  Future<bool> _awaitProActivation() async {
    for (var i = 0; i < 6; i++) {
      try {
        if (await _api.refreshPro()) return true;
      } catch (_) {
        // Réseau/serveur : on retente.
      }
      await Future<void>.delayed(const Duration(milliseconds: 1500));
    }
    return false;
  }

  /// Télécharge le blob distant et l'applique à la config locale.
  /// Renvoie faux sur échec (réseau, déchiffrement) — l'appelant décide s'il
  /// veut le signaler (la sync auto reste silencieuse).
  Future<bool> pull() async {
    if (state.status != SyncStatus.signedIn) return false;
    final password = await _password();
    if (password == null) return false;
    try {
      final remote = await _api.pull();
      if (remote.blob == null) return true; // rien encore côté serveur
      final payload = await SyncCrypto.decrypt(remote.blob!, password);
      applying = true;
      try {
        await _apply(payload);
      } finally {
        applying = false;
      }
      state = state.copyWith(lastSyncAt: DateTime.now(), clearError: true);
      return true;
    } on SyncBadPassword {
      // Config chiffrée avec un autre mot de passe (changé ailleurs).
      state = state.copyWith(error: 'Impossible de déchiffrer la config distante.');
      return false;
    } catch (_) {
      return false; // réseau : on retentera
    }
  }

  /// Chiffre la config locale et l'envoie. Réservé aux comptes Pro.
  /// Renvoie faux sur échec.
  Future<bool> push() async {
    if (state.status != SyncStatus.signedIn) return false;
    final password = await _password();
    if (password == null) return false;
    try {
      final payload = await _build();
      final blob = await SyncCrypto.encrypt(payload, password);
      await _api.push(blob, DateTime.now().millisecondsSinceEpoch);
      state = state.copyWith(lastSyncAt: DateTime.now(), clearError: true);
      return true;
    } on SyncProRequired {
      state = state.copyWith(isPro: false, error: 'Sync réservée à Glance Sync (Pro).');
      return false;
    } catch (_) {
      return false; // réseau : on retentera
    }
  }

  /// Synchronisation manuelle : récupère puis envoie l'état courant.
  /// Contrairement à la sync auto, un échec est signalé (pas de faux succès).
  Future<bool> syncNow() async {
    state = state.copyWith(busy: true, clearError: true);
    var ok = await pull();
    if (state.isPro) ok = await push() && ok;
    state = state.copyWith(busy: false);
    if (!ok && state.error == null) {
      state = state.copyWith(error: 'Serveur injoignable. Réessayez.');
    }
    return ok;
  }

  Future<TransferPayload> _build() async {
    final accounts = ref.read(accountsProvider);
    final repo = ref.read(accountsRepoProvider);
    final creds = <String, Map<String, String>>{};
    for (final a in accounts) {
      creds[a.id] = await repo.credentials(a.id);
    }
    return TransferPayload(
      accounts: accounts,
      credentials: creds,
      workspaces: ref.read(workspacesProvider),
    );
  }

  Future<void> _apply(TransferPayload p) async {
    await ref.read(accountsProvider.notifier).import(p.accounts, p.credentials);
    await ref.read(workspacesProvider.notifier).upsertAll(p.workspaces);
  }
}

final syncControllerProvider =
    NotifierProvider<SyncController, SyncState>(SyncController.new);
