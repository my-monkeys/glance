import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage du token de session. Abstrait pour être remplaçable en test (le
/// secure storage exige une plateforme).
abstract class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// Implémentation par défaut : Keychain via flutter_secure_storage.
class SecureTokenStore implements TokenStore {
  SecureTokenStore(this._s);
  final FlutterSecureStorage _s;
  static const _k = 'glance.sync.token';
  @override
  Future<String?> read() => _s.read(key: _k);
  @override
  Future<void> write(String token) => _s.write(key: _k, value: token);
  @override
  Future<void> clear() => _s.delete(key: _k);
}

/// Utilisateur de sync (compte Glance Sync).
class SyncUser {
  const SyncUser({required this.id, required this.email, required this.isPro});
  final String id;
  final String email;
  final bool isPro;
}

/// Blob de config stocké côté serveur (chiffré, opaque).
class RemoteConfig {
  const RemoteConfig({required this.blob, required this.updatedAt});
  final String? blob;
  final int updatedAt;
}

class SyncAuthError implements Exception {
  SyncAuthError(this.message);
  final String message;
}

/// Le compte n'est pas Pro : la sync (écriture) est réservée aux comptes payants.
class SyncProRequired implements Exception {}

class SyncNetworkError implements Exception {}

/// Client HTTP du backend **glance-sync** (Better Auth + coffre de config).
///
/// Auth par **bearer** : le token, reçu dans l'en-tête `set-auth-token` à la
/// connexion, est rangé dans le secure storage et renvoyé en `Authorization`.
class SyncApi {
  SyncApi(this._store, {Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl ?? _defaultBase,
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 12),
              // On gère les codes d'erreur nous-mêmes (402, 401…).
              validateStatus: (_) => true,
            ));

  static const _defaultBase = String.fromEnvironment(
    'SYNC_BASE_URL',
    defaultValue: 'https://sync.glance-analytics.com',
  );

  final TokenStore _store;
  final Dio _dio;
  String? _token;

  Future<String?> _loadToken() async => _token ??= await _store.read();

  Future<void> _saveToken(String token) async {
    _token = token;
    await _store.write(token);
  }

  Future<Options> _auth() async {
    final t = await _loadToken();
    return Options(headers: t != null ? {'authorization': 'Bearer $t'} : null);
  }

  Future<bool> get hasSession async => (await _loadToken()) != null;

  Future<SyncUser> signUp(String email, String password) =>
      _authenticate('/api/auth/sign-up/email', {
        'email': email,
        'password': password,
        'name': email.split('@').first,
      });

  Future<SyncUser> signIn(String email, String password) =>
      _authenticate('/api/auth/sign-in/email', {'email': email, 'password': password});

  Future<SyncUser> _authenticate(String path, Map<String, Object> body) async {
    final Response r;
    try {
      r = await _dio.post(path, data: body);
    } on DioException {
      throw SyncNetworkError();
    }
    if (r.statusCode != 200) {
      final msg = (r.data is Map ? r.data['message'] : null)?.toString();
      throw SyncAuthError(msg ?? 'Identifiants refusés');
    }
    final token = r.headers.value('set-auth-token');
    if (token != null) await _saveToken(token);
    final user = (r.data as Map)['user'] as Map;
    return SyncUser(
      id: user['id'].toString(),
      email: user['email'].toString(),
      isPro: user['isPro'] == true,
    );
  }

  /// Session courante (`null` si déconnecté ou token expiré).
  Future<SyncUser?> session() async {
    if (!await hasSession) return null;
    final Response r;
    try {
      r = await _dio.get('/api/auth/get-session', options: await _auth());
    } on DioException {
      throw SyncNetworkError();
    }
    if (r.statusCode != 200 || r.data == null || r.data is! Map) return null;
    final user = (r.data as Map)['user'];
    if (user is! Map) return null;
    return SyncUser(
      id: user['id'].toString(),
      email: user['email'].toString(),
      isPro: user['isPro'] == true,
    );
  }

  Future<void> signOut() async {
    try {
      await _dio.post('/api/auth/sign-out', options: await _auth());
    } catch (_) {
      // Peu importe la réponse : on efface la session locale de toute façon.
    }
    _token = null;
    await _store.clear();
  }

  /// Récupère le blob chiffré (pull).
  Future<RemoteConfig> pull() async {
    final Response r;
    try {
      r = await _dio.get('/api/config', options: await _auth());
    } on DioException {
      throw SyncNetworkError();
    }
    if (r.statusCode == 401) throw SyncAuthError('Session expirée');
    if (r.statusCode != 200) throw SyncNetworkError();
    final data = r.data as Map;
    return RemoteConfig(
      blob: data['blob'] as String?,
      updatedAt: (data['updatedAt'] as num?)?.toInt() ?? 0,
    );
  }

  /// Envoie le blob chiffré (push). [updatedAt] = horodatage local (ms).
  Future<void> push(String blob, int updatedAt) async {
    final Response r;
    try {
      r = await _dio.put('/api/config',
          data: {'blob': blob, 'updatedAt': updatedAt}, options: await _auth());
    } on DioException {
      throw SyncNetworkError();
    }
    if (r.statusCode == 401) throw SyncAuthError('Session expirée');
    if (r.statusCode == 402) throw SyncProRequired();
    if (r.statusCode != 200) throw SyncNetworkError();
  }
}
