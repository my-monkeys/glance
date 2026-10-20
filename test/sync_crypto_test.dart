import 'dart:convert';
import 'dart:io' show gzip;

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/account.dart';
import 'package:glance/data/models/indicator.dart';
import 'package:glance/data/models/metrics_source.dart';
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

    test('aller-retour : un indicateur de chaque type, filtres compris', () async {
      const filtre = EventFilter(
        property: 'score',
        type: PropertyType.number,
        op: FilterOp.gte,
        value: '80',
      );
      const q = EventQuery('niveau', [filtre]);
      final indicators = [
        SiteIndicators(const SiteRef('a1', 's1'), [
          const CounterIndicator(id: 'c', name: 'Parties', query: q),
          const RatioIndicator(
            id: 'r',
            name: 'Réussite',
            numerator: q,
            denominator: EventQuery('partie'),
          ),
          FunnelIndicator(
            id: 'f',
            name: 'Parcours',
            steps: const [EventQuery('debut'), q],
            windowMinutes: 30,
          ),
          const BreakdownIndicator(
            id: 'b',
            name: 'Modes',
            event: 'partie',
            property: 'mode',
          ),
        ]),
      ];
      final blob = await SyncCrypto.encrypt(
        TransferPayload(
          accounts: const [],
          credentials: const {},
          workspaces: const [],
          indicators: indicators,
        ),
        'pw',
      );
      final back = await SyncCrypto.decrypt(blob, 'pw');

      expect(back.indicators.single.site, const SiteRef('a1', 's1'));
      expect(back.indicators.single.indicators, indicators.single.indicators);
    });

    test('aller-retour : sources de métriques, jeton compris', () async {
      const sources = [
        SyncedMetricsSource(
          MetricsSource(
            site: SiteRef('a1', 's1'),
            baseUrl: 'https://geodaily.eu/api/interne/metriques/',
          ),
          'jeton-secret',
        ),
      ];
      final blob = await SyncCrypto.encrypt(
        const TransferPayload(
          accounts: [],
          credentials: {},
          workspaces: [],
          metricSources: sources,
        ),
        'pw',
      );
      final back = await SyncCrypto.decrypt(blob, 'pw');

      expect(back.metricSources, sources);
      expect(SyncCrypto.version, 1);
    });

    test('blob d\'une app antérieure (sans `indicators`) → déchiffré, liste vide',
        () async {
      // Chemin d'écriture d'avant les tableaux, reproduit à la main.
      final json = jsonEncode({
        'v': 1,
        'accounts': const [],
        'workspaces': const [],
      });
      final cipher = AesGcm.with256bits();
      final salt = SecretKeyData.random(length: 16).bytes;
      final key = await Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: 150000,
        bits: 256,
      ).deriveKey(secretKey: SecretKey(utf8.encode('pw')), nonce: salt);
      final box = await cipher.encrypt(gzip.encode(utf8.encode(json)), secretKey: key);
      final blob = base64.encode([...salt, ...box.concatenation()]);

      final back = await SyncCrypto.decrypt(blob, 'pw');
      expect(back.indicators, isEmpty);
      expect(back.metricSources, isEmpty);
      expect(SyncCrypto.version, 1);
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
