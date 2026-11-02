import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';
import 'secret_vault.dart';

/// Persiste la liste des comptes (métadonnées non sensibles en SharedPreferences)
/// et leurs identifiants (chiffrés via le Keychain iOS).
class AccountsRepository {
  AccountsRepository(this._prefs, this._vault);

  final SharedPreferences _prefs;
  final SecretVault _vault;

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
    await _vault.write(_credPrefix + account.id, jsonEncode(creds));
  }

  Future<void> updateAccount(Account account) async {
    final list = loadAccounts()
      ..removeWhere((a) => a.id == account.id)
      ..add(account);
    await _saveList(list);
  }

  Future<Map<String, String>> credentials(String accountId) async {
    final raw = await _vault.read(_credPrefix + accountId);
    if (raw == null || raw.isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<void> removeAccount(String accountId) async {
    final list = loadAccounts().where((a) => a.id != accountId).toList();
    await _saveList(list);
    await _vault.delete(_credPrefix + accountId);
  }

  /// Génère un identifiant de compte simple et unique.
  static String newId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}
