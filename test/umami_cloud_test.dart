import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/account.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/models/period.dart';
import 'package:glance/data/providers/analytics_provider.dart';
import 'package:glance/data/providers/umami_provider.dart';
import 'package:glance/l10n/app_localizations_fr.dart';

/// Répond par chemin (sans la query) et garde chaque requête reçue.
class _FakeUmami implements HttpClientAdapter {
  _FakeUmami(this.routes);
  final Map<String, (int, Object)> routes;
  final seen = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancel) async {
    seen.add(options);
    final (status, body) = routes[options.uri.path] ?? (404, {'error': 'x'});
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _sites = {
  'data': [
    {'id': 'w1', 'name': 'Blog', 'domain': 'blog.example.com'},
  ],
};

(UmamiProvider, _FakeUmami) _provider(
  String baseUrl,
  Map<String, String> creds,
  Map<String, (int, Object)> routes,
) {
  final p = UmamiProvider(
    Account(id: 'a', kind: ProviderKind.umami, baseUrl: baseUrl),
    creds,
  );
  final fake = _FakeUmami(routes);
  p.dio.httpClientAdapter = fake;
  return (p, fake);
}

void main() {
  group('Umami Cloud', () {
    test('liste les sites avec la clé API, sans login, sous /v1', () async {
      final (p, fake) = _provider(
        UmamiProvider.cloudBase,
        {'apiKey': 'k-123'},
        {'/v1/websites': (200, _sites)},
      );
      final sites = await p.listSites();

      expect(sites.single.id, 'w1');
      expect(fake.seen, hasLength(1));
      final req = fake.seen.single;
      expect(req.uri.host, 'api.umami.is');
      expect(req.uri.queryParameters['includeTeams'], 'true');
      expect(req.headers[UmamiProvider.cloudKeyHeader], 'k-123');
      expect(req.headers.containsKey('Authorization'), isFalse);
    });

    test('les statistiques passent aussi par /v1', () async {
      final (p, fake) = _provider(
        UmamiProvider.cloudBase,
        {'apiKey': 'k'},
        {
          '/v1/websites/w1/stats': (
            200,
            {
              'visitors': 12,
              'pageviews': 30,
              'visits': 15,
              'bounces': 3,
              'comparison': {'visitors': 10, 'pageviews': 25},
            },
          ),
        },
      );
      final now = DateTime(2026, 11, 3, 12);
      final w = DateWindow(now.subtract(const Duration(days: 1)), now,
          TimeUnit.hour);
      final s = await p.summary(
        const Site(id: 'w1', accountId: 'a', name: 'Blog', domain: 'b'),
        w,
      );

      expect(s.visitors, 12);
      expect(fake.seen.single.uri.path, '/v1/websites/w1/stats');
    });

    test('une clé refusée remonte le 401, sans tentative de login', () async {
      final (p, fake) = _provider(
        UmamiProvider.cloudBase,
        {'apiKey': 'mauvaise'},
        {'/v1/websites': (401, {'error': 'Unauthorized'})},
      );

      await expectLater(
        p.listSites(),
        throwsA(isA<DioException>()
            .having((e) => e.response?.statusCode, 'status', 401)),
      );
      expect(fake.seen, hasLength(1));
      expect(await p.health(), AccountHealth.badAuth);
    });
  });

  test('auto-hébergé : login puis Bearer, sous /api', () async {
    final (p, fake) = _provider(
      'uuu.example.com',
      {'username': 'u', 'password': 'p'},
      {
        '/api/auth/login': (200, {'token': 't-1', 'user': {'isAdmin': false}}),
        '/api/websites': (200, _sites),
      },
    );
    await p.listSites();

    expect([for (final r in fake.seen) r.uri.path],
        ['/api/auth/login', '/api/websites']);
    final list = fake.seen.last;
    expect(list.headers['Authorization'], 'Bearer t-1');
    expect(list.headers.containsKey(UmamiProvider.cloudKeyHeader), isFalse);
    expect(list.uri.queryParameters.containsKey('includeTeams'), isFalse);
  });

  group('reconnaissance de l’adresse', () {
    test('isCloud ne vise que l’API d’Umami Cloud', () {
      expect(UmamiProvider.isCloud('https://api.umami.is'), isTrue);
      expect(UmamiProvider.isCloud('api.umami.is/'), isTrue);
      expect(UmamiProvider.isCloud('cloud.umami.is'), isFalse);
      expect(UmamiProvider.isCloud('uuu.my-monkey.fr'), isFalse);
    });

    test('looksLikeCloud repère une adresse d’Umami Cloud saisie à la main',
        () {
      expect(UmamiProvider.looksLikeCloud('cloud.umami.is'), isTrue);
      expect(UmamiProvider.looksLikeCloud('https://cloud.umami.is/login'),
          isTrue);
      expect(UmamiProvider.looksLikeCloud('umami.is'), isTrue);
      expect(UmamiProvider.looksLikeCloud('umami.example.com'), isFalse);
      expect(UmamiProvider.looksLikeCloud('notumami.is'), isFalse);
      expect(UmamiProvider.looksLikeCloud(''), isFalse);
    });

    test('un compte Cloud s’intitule « Umami Cloud »', () {
      const a = Account(
          id: 'a', kind: ProviderKind.umami, baseUrl: UmamiProvider.cloudBase);
      expect(a.title, 'Umami Cloud');
    });
  });

  test('Umami Cloud ne demande que la clé API', () {
    final l10n = AppLocalizationsFr();
    final cloud =
        credentialFieldsFor(l10n, ProviderKind.umami, umamiCloud: true);
    expect([for (final f in cloud) f.key], ['apiKey']);
    expect(cloud.single.secret, isTrue);

    final selfHosted = credentialFieldsFor(l10n, ProviderKind.umami);
    expect([for (final f in selfHosted) f.key],
        ['baseUrl', 'username', 'password']);
  });
}
