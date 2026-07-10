import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';

/// Persiste la liste des comptes (métadonnées non sensibles en SharedPreferences)
/// et leurs identifiants (chiffrés via le Keychain iOS).
class AccountsRepository {
  AccountsRepository(this._prefs, this._secure);

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  static const _kAccounts = 'glance.accounts';
  static const _credPrefix = 'glance.creds.';

  List<Account> loadAccounts() =>
      Account.decodeList(_prefs.getString(_kAccounts)).toList();

  Future<void> _saveList(List<Account> list) =>
      _prefs.setString(_kAccounts, Account.encodeList(list));

  Future<void> addAccount(Account account, Map<String, String> creds) async {
    final list = loadAccounts()
      ..removeWhere((a) => a.id == account.id)
      ..add(account);
    await _saveList(list);
    await _secure.write(key: _credPrefix + account.id, value: jsonEncode(creds));
  }

  Future<void> updateAccount(Account account) async {
    final list = loadAccounts()
      ..removeWhere((a) => a.id == account.id)
      ..add(account);
    await _saveList(list);
  }

  Future<Map<String, String>> credentials(String accountId) async {
    final raw = await _secure.read(key: _credPrefix + accountId);
    if (raw == null || raw.isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<void> removeAccount(String accountId) async {
    final list = loadAccounts().where((a) => a.id != accountId).toList();
    await _saveList(list);
    await _secure.delete(key: _credPrefix + accountId);
  }

  Future<void> clear() async {
    for (final a in loadAccounts()) {
      await _secure.delete(key: _credPrefix + a.id);
    }
    await _prefs.remove(_kAccounts);
  }

  /// Génère un identifiant de compte simple et unique.
  static String newId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}
