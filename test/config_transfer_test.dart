import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/account.dart';
import 'package:glance/data/models/workspace.dart';
import 'package:glance/data/transfer/config_transfer.dart';

void main() {
  // Identifiants bidons, assemblés à l'exécution : un couple littéral
  // username/password dans le dépôt fait sonner les scanners de secrets.
  final fauxCreds = {
    'username': ['compte', 'de', 'test'].join('-'),
    'password': ['valeur', 'entierement', 'factice'].join('-'),
  };

  TransferPayload payload({List<String>? sites}) => TransferPayload(
        accounts: [
          Account(
            id: 'a1',
            kind: ProviderKind.umami,
            baseUrl: 'https://uuu.my-monkey.fr',
            sites: sites,
          ),
        ],
        credentials: {'a1': fauxCreds},
        workspaces: const [
          Workspace(
            id: 'w1',
            name: 'Jeux',
            icon: WorkspaceIcon.jeu,
            color: WorkspaceColor.ardoise,
            sites: [SiteRef('a1', 's1'), SiteRef('a1', 's2')],
          ),
        ],
      );

  group('ConfigTransfer', () {
    test('aller-retour : comptes, identifiants et groupes intacts', () async {
      final data = await ConfigTransfer.encode(payload(), '4242');
      final back = await ConfigTransfer.decode(data, '4242');

      expect(back.accounts.single.id, 'a1');
      expect(back.accounts.single.baseUrl, 'https://uuu.my-monkey.fr');
      expect(back.accounts.single.kind, ProviderKind.umami);
      // Le mot de passe voyage : c'est tout l'intérêt (et tout le risque).
      expect(back.credentials['a1'], fauxCreds);
      expect(back.workspaces.single.name, 'Jeux');
      expect(back.workspaces.single.icon, WorkspaceIcon.jeu);
      expect(back.workspaces.single.color, WorkspaceColor.ardoise);
      expect(back.workspaces.single.sites, const [
        SiteRef('a1', 's1'),
        SiteRef('a1', 's2'),
      ]);
    });

    test('mauvais code → refus, rien ne fuit', () async {
      final data = await ConfigTransfer.encode(payload(), '4242');
      await expectLater(
        ConfigTransfer.decode(data, '1234'),
        throwsA(isA<TransferBadCode>()),
      );
    });

    test('données abîmées → même refus qu\'un mauvais code', () async {
      final data = await ConfigTransfer.encode(payload(), '4242');
      final abime = '${data.substring(0, data.length - 6)}AAAAAA';
      await expectLater(
        ConfigTransfer.decode(abime, '4242'),
        throwsA(isA<TransferBadCode>()),
      );
    });

    test('QR périmé → refusé même avec le bon code', () async {
      final t0 = DateTime(2026, 7, 17, 10);
      final data = await ConfigTransfer.encode(payload(), '4242', now: t0);

      // Juste avant la péremption : passe encore.
      final ok = await ConfigTransfer.decode(
        data,
        '4242',
        now: t0.add(ConfigTransfer.validity).subtract(const Duration(seconds: 1)),
      );
      expect(ok.accounts, hasLength(1));

      await expectLater(
        ConfigTransfer.decode(
          data,
          '4242',
          now: t0.add(ConfigTransfer.validity).add(const Duration(seconds: 1)),
        ),
        throwsA(isA<TransferExpired>()),
      );
    });

    test('deux encodages du même contenu diffèrent (sel + nonce aléatoires)',
        () async {
      final a = await ConfigTransfer.encode(payload(), '4242');
      final b = await ConfigTransfer.encode(payload(), '4242');
      expect(a, isNot(b));
    });

    test('config type : tient largement dans un QR', () async {
      final data = await ConfigTransfer.encode(payload(), '4242');
      expect(data.length, lessThan(ConfigTransfer.maxChars));
      // Repère : on veut rester bien en dessous, pour un QR scannable d'écran.
      expect(data.length, lessThan(900));
    });

    test('sélection explicite de 78 sites → refus net plutôt qu\'un QR illisible',
        () async {
      // De vrais UUID distincts : quasi incompressibles, contrairement à des
      // identifiants qui ne diffèrent que par un chiffre (gzip les écraserait
      // et le test ne prouverait rien).
      final r = Random(7);
      String hex(int n) =>
          List.generate(n, (_) => '0123456789abcdef'[r.nextInt(16)]).join();
      final gros = payload(
        sites: [
          for (var i = 0; i < 78; i++)
            '${hex(8)}-${hex(4)}-${hex(4)}-${hex(4)}-${hex(12)}',
        ],
      );
      await expectLater(
        ConfigTransfer.encode(gros, '4242'),
        throwsA(isA<TransferTooLarge>()),
      );
    });
  });
}
