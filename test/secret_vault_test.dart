import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/repository/secret_vault.dart';

/// Trousseau en mémoire qui compte ses lectures et peut échouer à la demande.
class _FakeStorage extends FlutterSecureStorage {
  _FakeStorage([Map<String, String>? initial]) : data = {...?initial};

  final Map<String, String> data;
  int reads = 0;
  int readAlls = 0;
  int failReads = 0;
  bool failVaultWrite = false;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    reads++;
    await Future<void>.delayed(Duration.zero);
    if (failReads > 0) {
      failReads--;
      throw Exception('invite annulée');
    }
    return data[key];
  }

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    readAlls++;
    return {...data};
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    await Future<void>.delayed(Duration.zero);
    if (failVaultWrite && key == SecretVault.vaultKey) {
      throw Exception('écriture refusée');
    }
    data[key] = value!;
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    data.remove(key);
  }
}

Map<String, dynamic> _vaultOf(_FakeStorage s) =>
    jsonDecode(s.data[SecretVault.vaultKey]!) as Map<String, dynamic>;

void main() {
  const legacy = {
    'glance.creds.a1': '{"token":"t"}',
    'glance.metricsToken.a1.s1': 'tok',
    'glance.sync.token': 'session',
    'glance.sync.pw': 'pw',
  };

  test('migration : anciens éléments dans le coffre, puis supprimés', () async {
    final s = _FakeStorage(legacy);
    final v = SecretVault(s);

    expect(await v.read('glance.creds.a1'), '{"token":"t"}');
    expect(await v.read('glance.sync.pw'), 'pw');
    expect(_vaultOf(s), legacy);
    expect(s.data.keys, [SecretVault.vaultKey]);
  });

  test('migration ratée : rien n\'est supprimé, et on réessaie', () async {
    final s = _FakeStorage(legacy)..failVaultWrite = true;
    final v = SecretVault(s);

    await expectLater(v.read('glance.sync.pw'), throwsException);
    expect(s.data, legacy);

    s.failVaultWrite = false;
    expect(await v.read('glance.sync.pw'), 'pw');
    expect(s.data.keys, [SecretVault.vaultKey]);
  });

  test('coffre existant : pas de migration', () async {
    final s = _FakeStorage({
      SecretVault.vaultKey: jsonEncode({'glance.sync.pw': 'neuf'}),
      'glance.sync.token': 'orphelin',
    });
    final v = SecretVault(s);

    expect(await v.read('glance.sync.pw'), 'neuf');
    expect(s.readAlls, 0);
    expect(s.data['glance.sync.token'], 'orphelin');
  });

  test('lectures concurrentes : une seule lecture du trousseau', () async {
    final s = _FakeStorage({SecretVault.vaultKey: jsonEncode({'a': '1', 'b': '2'})});
    final v = SecretVault(s);

    final r = await Future.wait([v.read('a'), v.read('b'), v.read('c')]);
    expect(r, ['1', '2', null]);
    expect(await v.read('a'), '1');
    expect(s.reads, 1);
  });

  test('échec de chargement non mémorisé', () async {
    final s = _FakeStorage({SecretVault.vaultKey: jsonEncode({'a': '1'})})
      ..failReads = 1;
    final v = SecretVault(s);

    await expectLater(v.read('a'), throwsException);
    expect(await v.read('a'), '1');
    expect(s.reads, 2);
  });

  test('écritures concurrentes sans perte', () async {
    final s = _FakeStorage();
    final v = SecretVault(s);

    await Future.wait([
      for (var i = 0; i < 10; i++) v.write('k$i', 'v$i'),
      v.delete('k3'),
    ]);

    final expected = {
      for (var i = 0; i < 10; i++)
        if (i != 3) 'k$i': 'v$i',
    };
    expect(_vaultOf(s), expected);
    expect(await v.read('k9'), 'v9');
    expect(await v.read('k3'), isNull);
  });
}
