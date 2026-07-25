import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
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

    test('le détail exclut le live (jamais de « en direct » périmé)', () async {
      final c = await cache();
      final w = Period.d30.window();
      final detail = SiteDetail(
        summary: summary,
        series: series,
        unit: 'day',
        topPages: const [MetricRow(label: '/en', value: 300)],
        sources: const [MetricRow(label: 'google.com', value: 244)],
        countries: const [MetricRow(label: 'France', value: 8, code: 'FR')],
        live: 5,
        livePages: const [LivePage('/en', 3)],
      );
      c.writeDetail(site, w, detail);

      final back = c.readDetail(site, w)!;
      expect(back.live, 0);
      expect(back.livePages, isEmpty);
      expect(back.topPages.single.label, '/en');
      expect(back.countries.single.code, 'FR');
      expect(back.summary.visitors, 411);
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
        'glance.cache.stats.a1.s1.7j',
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
