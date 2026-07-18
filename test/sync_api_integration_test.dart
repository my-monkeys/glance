@Tags(['integration'])
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/sync/sync_api.dart';

/// Test d'intégration du client [SyncApi] contre le **vrai backend glance-sync**
/// tournant en local (`http://localhost:3999`, secret webhook `devsecret`).
/// Ignoré automatiquement si le backend n'est pas joignable.
///
///   cd glance-sync && pnpm dev   # (ou node --import tsx src/server.ts)
///   flutter test test/sync_api_integration_test.dart
const base = 'http://localhost:3999';
const webhookSecret = 'devsecret';

class MemStore implements TokenStore {
  String? _t;
  @override
  Future<String?> read() async => _t;
  @override
  Future<void> write(String token) async => _t = token;
  @override
  Future<void> clear() async => _t = null;
}

Future<bool> _backendUp() async {
  try {
    final r = await Dio().get('$base/health',
        options: Options(validateStatus: (_) => true));
    return r.statusCode == 200;
  } catch (_) {
    return false;
  }
}

void main() {
  test('flux complet client ↔ serveur (inscription → Pro → push/pull)', () async {
    if (!await _backendUp()) {
      markTestSkipped('backend glance-sync non joignable sur $base');
      return;
    }

    final api = SyncApi(MemStore(), baseUrl: base);
    final email = 'itest${DateTime.now().microsecondsSinceEpoch}@glance.test';

    // 1. Inscription → token capturé, pas encore Pro.
    final user = await api.signUp(email, 'hunter2secret');
    expect(user.email, email);
    expect(user.isPro, isFalse);
    expect(await api.hasSession, isTrue);

    // 2. Rien côté serveur au départ.
    expect((await api.pull()).blob, isNull);

    // 3. Push refusé sans Pro.
    await expectLater(api.push('CIPHER_v1', 1000), throwsA(isA<SyncProRequired>()));

    // 4. Webhook RevenueCat → active Pro.
    await Dio().post(
      '$base/api/webhooks/revenuecat',
      data: {
        'event': {'type': 'INITIAL_PURCHASE', 'app_user_id': user.id},
      },
      options: Options(headers: {'authorization': webhookSecret}),
    );
    expect((await api.session())!.isPro, isTrue);

    // 5. Push OK, puis pull renvoie le blob.
    await api.push('CIPHER_v1_abc', 1737000000000);
    final remote = await api.pull();
    expect(remote.blob, 'CIPHER_v1_abc');
    expect(remote.updatedAt, 1737000000000);

    // 6. Déconnexion → plus de session.
    await api.signOut();
    expect(await api.hasSession, isFalse);
  });
}
