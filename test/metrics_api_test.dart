import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/metrics_source.dart';
import 'package:glance/data/models/period.dart';
import 'package:glance/data/providers/metrics_api.dart';

/// Répond avec un statut et un corps fixes, et garde la dernière requête.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.status, this.body);
  final int status;
  final Object body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream,
      Future<void>? cancel) async {
    last = options;
    return ResponseBody.fromString(
      body is String ? body as String : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

MetricsApi _api(FakeAdapter a, {String url = 'https://x.eu/api/m/'}) =>
    MetricsApi(baseUrl: url, token: 'tok', dio: Dio()..httpClientAdapter = a);

const _catalogue = {
  'version': 1,
  'indicateurs': [
    {
      'id': 'retention_j1_nouveaux',
      'libelle': 'Rétention J1 · nouveaux joueurs',
      'description': 'Part des nouveaux joueurs revenus le lendemain.',
      'unite': 'pourcentage',
      'granularites': ['jour', 'semaine', 'mois'],
    },
    {
      'id': 'comptes',
      'libelle': 'Comptes',
      'description': '',
      'unite': 'nombre',
      'granularites': ['jour'],
    },
  ],
};

void main() {
  group('MetricsApi', () {
    test('catalogue : lecture, jeton et User-Agent envoyés', () async {
      final fake = FakeAdapter(200, _catalogue);
      final defs = await _api(fake).catalogue();

      expect(defs, hasLength(2));
      expect(defs.first.id, 'retention_j1_nouveaux');
      expect(defs.first.unite, MetricUnit.percent);
      expect(defs.first.granularites, ['jour', 'semaine', 'mois']);
      expect(defs.last.unite, MetricUnit.count);
      expect(fake.last!.uri.toString(), 'https://x.eu/api/m/catalogue');
      expect(fake.last!.headers['authorization'], 'Bearer tok');
      expect(fake.last!.headers['user-agent'], contains('Mozilla'));
    });

    test('l\'URL est acceptée sans slash final ni schéma', () async {
      final fake = FakeAdapter(200, _catalogue);
      await _api(fake, url: ' x.eu/api/m ').catalogue();
      expect(fake.last!.uri.toString(), 'https://x.eu/api/m/catalogue');
    });

    test('series : null conservé, dates locales, paramètres', () async {
      final fake = FakeAdapter(200, {
        'version': 1,
        'series': [
          {
            'id': 'a',
            'points': [
              {'t': '2026-10-05', 'valeur': 15.03, 'numerateur': 26, 'denominateur': 173},
              {'t': '2026-10-19', 'valeur': null, 'numerateur': 0, 'denominateur': 0},
            ],
          },
        ],
      });
      final out = await _api(fake).series(
        ids: ['a', 'b'],
        range: (de: '2026-10-01', a: '2026-10-20', granularite: 'jour'),
        tz: 'Europe/Paris',
      );

      final pts = out['a']!;
      expect(pts[0].t, DateTime(2026, 10, 5));
      expect(pts[0].valeur, 15.03);
      expect(pts[0].numerateur, 26);
      expect(pts[0].denominateur, 173);
      expect(pts[1].valeur, isNull);
      expect(fake.last!.queryParameters, {
        'ids': 'a,b',
        'de': '2026-10-01',
        'a': '2026-10-20',
        'granularite': 'jour',
        'tz': 'Europe/Paris',
      });
    });

    Future<Object?> failure(int status, Object body) async {
      try {
        await _api(FakeAdapter(status, body)).catalogue();
      } catch (e) {
        return e;
      }
      return null;
    }

    test('401, 404, 400 et version inconnue → exceptions typées', () async {
      expect(await failure(401, {}), isA<MetricsBadToken>());
      expect(await failure(404, {}), isA<MetricsNotConfigured>());
      final bad = await failure(400, {'error': {'code': 'plage_trop_longue'}});
      expect(bad, isA<MetricsBadRequest>());
      expect((bad as MetricsBadRequest).code, 'plage_trop_longue');
      final v = await failure(200, {'version': 2, 'indicateurs': []});
      expect(v, isA<MetricsUnsupportedVersion>());
      expect(v.toString(), 'Version d\'API non prise en charge');
      expect(await failure(500, {}), isA<MetricsUnexpectedResponse>());
      expect(await failure(200, 'pas du json'), isA<MetricsUnexpectedResponse>());
    });
  });

  group('metricsRangeFor', () {
    test('jours : `a` est le jour du dernier instant, fin exclusive', () {
      final r = metricsRangeFor(
          DateWindow(DateTime(2026, 10, 1), DateTime(2026, 10, 8), TimeUnit.day));
      expect(r, (de: '2026-10-01', a: '2026-10-07', granularite: 'jour'));
    });

    test('mois : granularité mois', () {
      final r = metricsRangeFor(
          DateWindow(DateTime(2026, 8, 1), DateTime(2026, 11, 1), TimeUnit.month));
      expect(r, (de: '2026-08-01', a: '2026-10-31', granularite: 'mois'));
    });

    test('heures → jour (l\'API n\'a pas d\'heures)', () {
      final r = metricsRangeFor(DateWindow(
          DateTime(2026, 10, 20, 0), DateTime(2026, 10, 20, 15), TimeUnit.hour));
      expect(r, (de: '2026-10-20', a: '2026-10-20', granularite: 'jour'));
    });

    test('plus de 400 jours : `de` est ramené à `a` − 399 jours', () {
      final r = metricsRangeFor(DateWindow(
          DateTime(2024, 1, 1), DateTime(2026, 10, 21), TimeUnit.month));
      expect(r.a, '2026-10-20');
      expect(r.de, '2025-09-16');
      // 400 jours inclusifs, pas un de plus.
      expect(DateTime.parse(r.a).difference(DateTime.parse(r.de)).inDays, 399);
    });

    test('exactement 400 jours : inchangé', () {
      final r = metricsRangeFor(DateWindow(
          DateTime(2025, 9, 16), DateTime(2026, 10, 21), TimeUnit.day));
      expect(r.de, '2025-09-16');
    });

    test('fenêtre horaire qui se termine pile à minuit → la veille', () {
      final r = metricsRangeFor(DateWindow(
          DateTime(2026, 10, 19, 12), DateTime(2026, 10, 20), TimeUnit.hour));
      expect(r.a, '2026-10-19');
    });
  });
}
