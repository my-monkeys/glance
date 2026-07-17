import 'dart:convert';
import 'dart:io' show gzip;

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../models/workspace.dart';

/// Ce qu'un transfert emporte : les comptes **avec leurs identifiants**, et les
/// groupes. C'est tout ce qu'il faut pour retrouver sa config sur un autre
/// appareil sans rien retaper.
@immutable
class TransferPayload {
  const TransferPayload({
    required this.accounts,
    required this.credentials,
    required this.workspaces,
  });

  final List<Account> accounts;

  /// Identifiants par `accountId` (mêmes clés que le secure storage).
  final Map<String, Map<String, String>> credentials;

  final List<Workspace> workspaces;
}

/// Le QR a expiré (ou l'horloge est trop décalée).
class TransferExpired implements Exception {}

/// Code faux, QR d'une autre app, ou données abîmées — indistinguables par
/// construction : AES-GCM échoue pareil dans les trois cas.
class TransferBadCode implements Exception {}

/// La config ne rentre pas dans un QR.
class TransferTooLarge implements Exception {
  const TransferTooLarge(this.size, this.max);
  final int size;
  final int max;
}

/// Encode/décode une config pour un transfert par QR code.
///
/// Format v1, en base64url : `salt(16) | nonce(12) | ciphertext | mac(16)`.
/// Le clair est du JSON gzippé ; la clé vient du code à 4 chiffres via PBKDF2.
///
/// **Le code à 4 chiffres est faible par nature** (10 000 possibilités) : il ne
/// protège que parce que le QR est éphémère et qu'il faut l'avoir. D'où
/// PBKDF2 à [_iterations] (une attaque hors-ligne coûte alors 10⁴ × ça) et une
/// péremption dans le clair chiffré — c'est un **transfert**, pas une
/// sauvegarde.
class ConfigTransfer {
  static const version = 1;

  /// Durée de validité d'un QR. Assez pour scanner, trop court pour qu'une
  /// capture d'écran oubliée reste utilisable.
  static const validity = Duration(minutes: 10);

  /// Coût du dérivage. Assez haut pour peser sur une attaque hors-ligne, assez
  /// bas pour rester sous ~1 s à l'import.
  static const _iterations = 150000;

  /// Capacité pratique d'un QR (version 40, correction M). Au-delà, il n'est
  /// plus ni encodable ni scannable depuis un écran.
  static const maxChars = 2300;

  static final _cipher = AesGcm.with256bits();

  static Future<SecretKey> _key(String code, List<int> salt) {
    final kdf = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: 256,
    );
    return kdf.deriveKey(secretKey: SecretKey(utf8.encode(code)), nonce: salt);
  }

  /// Chiffre la config. [now] est injectable pour les tests.
  static Future<String> encode(
    TransferPayload payload,
    String code, {
    DateTime? now,
  }) async {
    final json = jsonEncode({
      'v': version,
      'exp': (now ?? DateTime.now()).add(validity).millisecondsSinceEpoch,
      'accounts': [
        for (final a in payload.accounts)
          {...a.toJson(), 'creds': payload.credentials[a.id] ?? const {}},
      ],
      'workspaces': [for (final w in payload.workspaces) w.toJson()],
    });

    final salt = SecretKeyData.random(length: 16).bytes;
    final box = await _cipher.encrypt(
      gzip.encode(utf8.encode(json)),
      secretKey: await _key(code, salt),
    );

    final out = base64Url.encode([...salt, ...box.concatenation()]);
    if (out.length > maxChars) throw TransferTooLarge(out.length, maxChars);
    return out;
  }

  /// Déchiffre. Lève [TransferBadCode] si le code est faux, [TransferExpired]
  /// si le QR est périmé.
  static Future<TransferPayload> decode(
    String data,
    String code, {
    DateTime? now,
  }) async {
    late final Map<String, dynamic> j;
    try {
      final bytes = base64Url.decode(data.trim());
      final salt = bytes.sublist(0, 16);
      final box = SecretBox.fromConcatenation(
        bytes.sublist(16),
        nonceLength: 12,
        macLength: 16,
      );
      final clear = await _cipher.decrypt(box, secretKey: await _key(code, salt));
      j = jsonDecode(utf8.decode(gzip.decode(Uint8List.fromList(clear))))
          as Map<String, dynamic>;
    } catch (_) {
      // Toute erreur avant d'avoir du JSON valide = on n'a pas la bonne clé.
      throw TransferBadCode();
    }

    if (j['v'] != version) throw TransferBadCode();
    final exp = DateTime.fromMillisecondsSinceEpoch(j['exp'] as int);
    if ((now ?? DateTime.now()).isAfter(exp)) throw TransferExpired();

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
