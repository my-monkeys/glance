import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tous les secrets de l'app dans UN seul élément du trousseau.
///
/// Sur macOS, chaque élément du trousseau legacy a sa propre ACL, donc sa
/// propre invite de mot de passe, et les lectures concurrentes du démarrage les
/// empilaient. Un seul élément = une seule invite par lancement.
class SecretVault {
  SecretVault(this._storage);

  final FlutterSecureStorage _storage;

  static const vaultKey = 'glance.vault';

  /// Tout ce que l'app rangeait avant le coffre portait ce préfixe.
  static const _legacyPrefix = 'glance.';

  Future<Map<String, String>>? _loading;
  Future<void> _writes = Future.value();

  Future<String?> read(String key) async => (await _load())[key];

  Future<void> write(String key, String value) =>
      _update((m) => m[key] = value);

  Future<void> delete(String key) => _update((m) => m.remove(key));

  /// Un seul `Future` partagé : N lectures concurrentes = une lecture du
  /// trousseau. Un échec (invite annulée) n'est pas gardé, le suivant réessaie.
  Future<Map<String, String>> _load() {
    return _loading ??= _loadOrMigrate().catchError((Object e) {
      _loading = null;
      throw e;
    });
  }

  Future<Map<String, String>> _loadOrMigrate() async {
    final raw = await _storage.read(key: vaultKey);
    if (raw != null) {
      return (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v.toString()));
    }
    return _migrate();
  }

  /// Rapatrie les anciens éléments dans le coffre, et ne les supprime qu'une
  /// fois le coffre écrit : si l'écriture échoue, rien n'est perdu.
  Future<Map<String, String>> _migrate() async {
    final legacy = {
      for (final e in (await _storage.readAll()).entries)
        if (e.key.startsWith(_legacyPrefix) && e.key != vaultKey)
          e.key: e.value,
    };
    await _storage.write(key: vaultKey, value: jsonEncode(legacy));
    for (final key in legacy.keys) {
      // Un reste non supprimé est inoffensif : le coffre existe désormais et
      // l'ancien élément n'est plus lu.
      try {
        await _storage.delete(key: key);
      } catch (_) {}
    }
    return legacy;
  }

  /// Écritures en file : chacune part de l'état laissé par la précédente et
  /// persiste le JSON complet, donc aucune mise à jour concurrente n'est perdue.
  Future<void> _update(void Function(Map<String, String>) change) {
    final run = _writes.then((_) async {
      final next = {...await _load()};
      change(next);
      await _storage.write(key: vaultKey, value: jsonEncode(next));
      _loading = Future.value(next);
    });
    _writes = run.catchError((Object _) {});
    return run;
  }
}
