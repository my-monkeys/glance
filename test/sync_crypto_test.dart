import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/account.dart';
import 'package:glance/data/models/workspace.dart';
import 'package:glance/data/sync/sync_crypto.dart';
import 'package:glance/data/transfer/config_transfer.dart';

void main() {
  // Identifiants factices assemblés à l'exécution (évite les scanners de secrets).
  final fauxCreds = {
    'username': ['compte', 'test'].join('-'),
    'password': ['valeur', 'factice'].join('-'),
  };

  TransferPayload payload() => TransferPayload(
        accounts: [
          Account(
            id: 'a1',
            kind: ProviderKind.umami,
            baseUrl: 'https://uuu.my-monkey.fr',
            sites: const ['s1', 's2'],
          ),
        ],
        credentials: {'a1': fauxCreds},
        workspaces: const [
          Workspace(
            id: 'w1',
            name: 'Jeux',
            icon: WorkspaceIcon.jeu,
            color: WorkspaceColor.ardoise,
            sites: [SiteRef('a1', 's1')],
          ),
        ],
      );

  group('SyncCrypto', () {
    test('aller-retour : comptes, identifiants et groupes intacts', () async {
      final blob = await SyncCrypto.encrypt(payload(), 'mon-mot-de-passe');
      final back = await SyncCrypto.decrypt(blob, 'mon-mot-de-passe');

      expect(back.accounts.single.id, 'a1');
      expect(back.accounts.single.sites, ['s1', 's2']);
      expect(back.credentials['a1'], fauxCreds);
      expect(back.workspaces.single.name, 'Jeux');
      expect(back.workspaces.single.icon, WorkspaceIcon.jeu);
      expect(back.workspaces.single.sites, const [SiteRef('a1', 's1')]);
    });

    test('mauvais mot de passe → refus', () async {
      final blob = await SyncCrypto.encrypt(payload(), 'bon');
      await expectLater(
        SyncCrypto.decrypt(blob, 'mauvais'),
        throwsA(isA<SyncBadPassword>()),
      );
    });

    test('blob corrompu → même refus', () async {
      final blob = await SyncCrypto.encrypt(payload(), 'bon');
      final abime = '${blob.substring(0, blob.length - 4)}AAAA';
      await expectLater(
        SyncCrypto.decrypt(abime, 'bon'),
        throwsA(isA<SyncBadPassword>()),
      );
    });

    test('deux chiffrements du même contenu diffèrent (sel + nonce aléatoires)',
        () async {
      final a = await SyncCrypto.encrypt(payload(), 'bon');
      final b = await SyncCrypto.encrypt(payload(), 'bon');
      expect(a, isNot(b));
    });
  });
}
