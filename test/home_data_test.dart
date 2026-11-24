import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/predict.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/models/period.dart';
import 'package:glance/state/home_data.dart';

SiteCard _card(String id, int visitors, {int? prev, int? deltaBase}) =>
    _cardWithBase(id, visitors, prev: prev, deltaBase: deltaBase ?? prev);

SiteCard _cardWithBase(String id, int visitors,
        {int? prev, required int? deltaBase}) =>
    SiteCard(
      site: Site(id: id, accountId: 'a', name: id, domain: '$id.fr'),
      summary: StatsSummary(
        visitors: visitors,
        prevVisitors: prev,
        pageviews: 0,
        visits: 0,
        bounceRatePct: 0,
        avgVisitSec: 0,
      ),
      series: const [],
      live: 0,
      deltaBase: deltaBase,
    );

void main() {
  group('delta des visiteurs', () {
    test('par défaut, la période précédente d’Umami', () {
      final c = _card('a', 201, prev: 270);
      expect(c.deltaPct, closeTo(-25.56, 0.01));
    });

    test('face à 7 jours avant, le chiffre de la légende', () {
      // Vécu : 201 aujourd'hui, 270 hier, 183 il y a 7 jours → « ▼ 25,6 % »
      // à côté d'un « 183 · 7 jours avant ».
      final c = _card('a', 201, prev: 270, deltaBase: 183);
      expect(c.deltaPct, closeTo(9.84, 0.01));
    });

    test('le total ne compare que les cartes qui ont leur référence', () {
      // Pendant le chargement : la 2ᵉ carte n'a pas encore sa référence.
      final data = HomeData.fromCards([
        _card('a', 110, prev: 300, deltaBase: 100),
        _cardWithBase('b', 500, prev: 400, deltaBase: null),
      ]);
      expect(data.totalVisitors, 610);
      expect(data.totalDeltaPct, closeTo(10, 0.001));
    });

    test('sans aucune référence, pas de delta', () {
      final data = HomeData.fromCards([_cardWithBase('a', 10, deltaBase: null)]);
      expect(data.totalDeltaPct, isNull);
    });
  });

  group('deltaUsesPreviousSoFar', () {
    final now = DateTime(2026, 11, 24, 14, 30);
    final today = Period.today.window(now: now);
    final week = Period.d7.window(now: now);

    test('comparaison affichée → le chiffre de la légende', () {
      expect(
          deltaUsesPreviousSoFar(week,
              compare: true, base: CompareBase.dayBefore),
          isTrue);
    });

    test('journée face à 7 jours avant, même comparaison masquée', () {
      expect(
          deltaUsesPreviousSoFar(today,
              compare: false, base: CompareBase.weekBefore),
          isTrue);
    });

    test('semaine, mois, année : la période civile d’avant, même avancement',
        () {
      for (final period in [Period.thisWeek, Period.thisMonth, Period.thisYear]) {
        expect(
            deltaUsesPreviousSoFar(period.window(now: now),
                compare: false, base: CompareBase.dayBefore),
            isTrue,
            reason: period.name);
      }
      // Un mois passé aussi : octobre face à septembre, pas aux 31 jours d'avant.
      expect(
          deltaUsesPreviousSoFar(
              Period.thisMonth.window(now: now, monthOffset: -1),
              compare: false,
              base: CompareBase.dayBefore),
          isTrue);
    });

    test('sinon, la référence d’Umami suffit (aucune requête de plus)', () {
      expect(
          deltaUsesPreviousSoFar(today,
              compare: false, base: CompareBase.dayBefore),
          isFalse);
      expect(
          deltaUsesPreviousSoFar(week,
              compare: false, base: CompareBase.weekBefore),
          isFalse);
    });
  });
}
