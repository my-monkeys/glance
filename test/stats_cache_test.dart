import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/dimension.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/models/period.dart';
import 'package:glance/data/stats_cache.dart';
import 'package:glance/state/home_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const site = Site(id: 's1', accountId: 'a1', name: 'Demo', domain: 'demo.fr');

  final summary = StatsSummary(
    visitors: 411,
    pageviews: 6866,
    visits: 474,
    bounceRatePct: 12.5,
    avgVisitSec: 251,
    prevVisitors: 332,
    prevPageviews: 5000,
  );
  final series = [
    SeriesPoint(DateTime(2026, 7, 20), 40, 500),
    SeriesPoint(DateTime(2026, 7, 21), 55, 620),
  ];

  Future<StatsCache> cache() async {
    SharedPreferences.setMockInitialValues({});
    return StatsCache(await SharedPreferences.getInstance());
  }

  group('StatsCache', () {
    test('aller-retour stats sur une fenêtre de période standard', () async {
      final c = await cache();
      final w = Period.d7.window();
      c.writeStats(site, w, SiteStats(summary: summary, series: series));

      final back = c.readStats(site, w)!;
      expect(back.summary.visitors, 411);
      expect(back.summary.pageviews, 6866);
      expect(back.summary.bounceRatePct, 12.5);
      expect(back.summary.prevVisitors, 332);
      expect(back.series, hasLength(2));
      expect(back.series[1].visitors, 55);
      expect(back.series[1].pageviews, 620);
    });

    test('aller-retour des lignes d\'une dimension, valeur brute comprise',
        () async {
      final c = await cache();
      final w = Period.d30.window();
      c.writeMetric(site, w, MetricType.browsers, const [
        MetricRow(label: 'Chrome', value: 289, code: 'chrome'),
        MetricRow(label: 'Safari (iOS)', value: 58, code: 'ios'),
      ]);

      final back = c.readMetric(site, w, MetricType.browsers)!;
      expect(back, hasLength(2));
      expect(back.first.label, 'Chrome');
      // Le code brut est ce dont dérive l'icône : il doit survivre au cache.
      expect(back.first.code, 'chrome');
      expect(back.last.value, 58);
      // Une dimension jamais écrite ne renvoie rien (pas la précédente).
      expect(c.readMetric(site, w, MetricType.countries), isNull);
    });

    test('écrire une dimension ne rajeunit pas les autres', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = StatsCache(prefs);
      final w = Period.d30.window(); // unit=day → péremption 3 jours

      // Une dimension écrite il y a dix jours, l'autre à l'instant.
      final old = DateTime.now()
          .subtract(const Duration(days: 10))
          .millisecondsSinceEpoch;
      prefs.setString(
        'glance.cache2.m.a1.s1.30j@day',
        jsonEncode({
          'at': DateTime.now().millisecondsSinceEpoch,
          'd': {
            'path': {
              'at': old,
              'r': [
                {'l': '/vieux', 'v': 3},
              ],
            },
          },
        }),
      );
      c.writeMetric(site, w, MetricType.browsers, const [
        MetricRow(label: 'Chrome', value: 1, code: 'chrome'),
      ]);

      expect(c.readMetric(site, w, MetricType.browsers), hasLength(1));
      expect(c.readMetric(site, w, MetricType.pages), isNull);
    });

    test('la granularité fait partie de la clé', () async {
      final c = await cache();
      final day = Period.d30.window();
      final hour = Period.d30.window(unit: TimeUnit.hour);
      c.writeStats(site, day, SiteStats(summary: summary, series: series));

      expect(c.readStats(site, day), isNotNull);
      // Même période, autre découpage : ce sont deux séries différentes.
      expect(c.readStats(site, hour), isNull);
    });

    test('une fenêtre non standard (jour passé) n\'est pas persistée', () async {
      final c = await cache();
      final w = Period.today.window(dayOffset: -1); // jour complet passé
      c.writeStats(site, w, SiteStats(summary: summary, series: series));
      expect(c.readStats(site, w), isNull);
    });

    test('une entrée trop ancienne est ignorée', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = StatsCache(prefs);
      final w = Period.d7.window(); // unit=day → péremption 3 jours

      // Écrit une enveloppe périmée directement (10 jours).
      final old = DateTime.now()
          .subtract(const Duration(days: 10))
          .millisecondsSinceEpoch;
      prefs.setString(
        'glance.cache2.stats.a1.s1.7j@day',
        jsonEncode({
          'at': old,
          'd': {
            's': {'v': 1, 'p': 1, 'vi': 1, 'b': 0, 'a': 0},
            'se': [],
          },
        }),
      );
      expect(c.readStats(site, w), isNull);
    });
  });
}
