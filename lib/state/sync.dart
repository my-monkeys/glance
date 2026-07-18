import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  final SyncStatus status;
  final String? email;
  final bool isPro;
  final DateTime? lastSyncAt;
  final bool busy;
  final String? error;

  SyncState copyWith({
    SyncStatus? status,
    String? email,
    bool? isPro,
    DateTime? lastSyncAt,
    bool? busy,
    String? error,
    bool clearError = false,
  }) =>
      SyncState(
        status: status ?? this.status,
        email: email ?? this.email,
        isPro: isPro ?? this.isPro,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        busy: busy ?? this.busy,
        error: clearError ? null : (error ?? this.error),
      );
}

final syncApiProvider = Provider<SyncApi>(
  (ref) => SyncApi(SecureTokenStore(ref.watch(secureStorageProvider))),
);

/// Pilote la synchronisation cloud : auth (Better Auth), chiffrement E2E de la
/// config avec le mot de passe du compte, pull/push du blob.
///
/// Le mot de passe est gardé dans le secure storage de l'appareil (il faut le
/// dériver à chaque opération, sel aléatoire par blob) — jamais côté serveur.
class SyncController extends Notifier<SyncState> {
  static const _kPassword = 'glance.sync.pw';

  SyncApi get _api => ref.read(syncApiProvider);

  /// Vrai pendant l'application d'un pull → évite qu'un push automatique se
  /// déclenche sur les changements qu'on vient d'importer (boucle).
  bool applying = false;

  @override
  SyncState build() {
    Future.microtask(_restore);
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
    await ref.read(secureStorageProvider).delete(key: _kPassword);
    state = const SyncState(status: SyncStatus.signedOut);
  }

  /// Télécharge le blob distant et l'applique à la config locale.
  Future<void> pull() async {
    if (state.status != SyncStatus.signedIn) return;
    final password = await _password();
    if (password == null) return;
    try {
      final remote = await _api.pull();
      if (remote.blob == null) return; // rien encore côté serveur
      final payload = await SyncCrypto.decrypt(remote.blob!, password);
      applying = true;
      try {
        await _apply(payload);
      } finally {
        applying = false;
      }
      state = state.copyWith(lastSyncAt: DateTime.now(), clearError: true);
    } on SyncBadPassword {
      // Config chiffrée avec un autre mot de passe (changé ailleurs).
      state = state.copyWith(error: 'Impossible de déchiffrer la config distante.');
    } catch (_) {
      // Réseau : silencieux, on retentera.
    }
  }

  /// Chiffre la config locale et l'envoie. Réservé aux comptes Pro.
  Future<void> push() async {
    if (state.status != SyncStatus.signedIn) return;
    final password = await _password();
    if (password == null) return;
    try {
      final payload = await _build();
      final blob = await SyncCrypto.encrypt(payload, password);
      await _api.push(blob, DateTime.now().millisecondsSinceEpoch);
      state = state.copyWith(lastSyncAt: DateTime.now(), clearError: true);
    } on SyncProRequired {
      state = state.copyWith(isPro: false, error: 'Sync réservée à Glance Sync (Pro).');
    } catch (_) {
      // Réseau : silencieux.
    }
  }

  /// Synchronisation manuelle : récupère puis envoie l'état courant.
  Future<void> syncNow() async {
    state = state.copyWith(busy: true, clearError: true);
    await pull();
    if (state.isPro) await push();
    state = state.copyWith(busy: false);
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
