import 'dart:convert';
import 'dart:io' show gzip;

import 'package:cryptography/cryptography.dart';

import '../models/account.dart';
import '../models/workspace.dart';
import '../transfer/config_transfer.dart' show TransferPayload;

/// Chiffrement de la config pour la **synchronisation cloud**.
///
/// Même famille cryptographique que le transfert QR ([ConfigTransfer]), mais :
/// - la clé vient du **mot de passe du compte** (pas d'un code éphémère) ;
/// - **pas de péremption** (un blob de sync persiste) ;
/// - le chiffrement se fait **sur l'appareil** → le serveur ne stocke qu'un
///   blob illisible (chiffrement de bout en bout, cf. `glance-sync`).
///
/// Format v1, base64 : `salt(16) | nonce(12) | ciphertext | mac(16)`. Le clair
/// est du JSON gzippé (comptes + identifiants + groupes).
class SyncCrypto {
  static const version = 1;

  /// Coût du dérivage (aligné sur le transfert). Une attaque hors-ligne sur le
  /// blob doit rester chère ; on reste sous ~1 s à l'ouverture.
  static const _iterations = 150000;

  static final _cipher = AesGcm.with256bits();

  static Future<SecretKey> _key(String password, List<int> salt) {
    final kdf = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: _iterations, bits: 256);
    return kdf.deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
  }

  /// Chiffre la config avec le mot de passe → blob base64 (à envoyer au serveur).
  static Future<String> encrypt(TransferPayload payload, String password) async {
    final json = jsonEncode({
      'v': version,
      'accounts': [
        for (final a in payload.accounts)
          {...a.toJson(), 'creds': payload.credentials[a.id] ?? const {}},
      ],
      'workspaces': [for (final w in payload.workspaces) w.toJson()],
    });

    final salt = SecretKeyData.random(length: 16).bytes;
    final box = await _cipher.encrypt(
      gzip.encode(utf8.encode(json)),
      secretKey: await _key(password, salt),
    );
    return base64.encode([...salt, ...box.concatenation()]);
  }

  /// Déchiffre un blob avec le mot de passe. Lève [SyncBadPassword] si la clé
  /// ne correspond pas (ou blob corrompu).
  static Future<TransferPayload> decrypt(String blob, String password) async {
    late final Map<String, dynamic> j;
    try {
      final bytes = base64.decode(blob.trim());
      final salt = bytes.sublist(0, 16);
      final box = SecretBox.fromConcatenation(
        bytes.sublist(16),
        nonceLength: 12,
        macLength: 16,
      );
      final clear = await _cipher.decrypt(box, secretKey: await _key(password, salt));
      j = jsonDecode(utf8.decode(gzip.decode(clear))) as Map<String, dynamic>;
    } catch (_) {
      throw SyncBadPassword();
    }
    if (j['v'] != version) throw SyncBadPassword();

    final accounts = <Account>[];
    final creds = <String, Map<String, String>>{};
    for (final raw in (j['accounts'] as List).cast<Map<String, dynamic>>()) {
      final a = Account.fromJson(raw);
      accounts.add(a);
      creds[a.id] = ((raw['creds'] as Map?) ?? const {})
          .map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return TransferPayload(
      accounts: accounts,
      credentials: creds,
      workspaces: [
        for (final raw in (j['workspaces'] as List).cast<Map<String, dynamic>>())
          Workspace.fromJson(raw),
      ],
    );
  }
}

/// Le blob ne se déchiffre pas avec ce mot de passe (mauvais mot de passe, ou
/// données corrompues — indistinguables par construction, AES-GCM échoue pareil).
class SyncBadPassword implements Exception {}
