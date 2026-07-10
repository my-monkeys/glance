import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/account.dart';
import 'package:glance/data/models/period.dart';

void main() {
  group('Period.window', () {
    final now = DateTime(2026, 7, 10, 14, 30);

    test('7 jours couvre la bonne fenêtre, granularité jour', () {
      final w = Period.d7.window(now: now);
      expect(w.unit, TimeUnit.day);
      expect(w.start, DateTime(2026, 7, 4));
      expect(w.end, now);
    });

    test("aujourd'hui commence à minuit, granularité heure", () {
      final w = Period.today.window(now: now);
      expect(w.unit, TimeUnit.hour);
      expect(w.start, DateTime(2026, 7, 10));
    });

    test('12 mois remonte 11 mois, granularité mois', () {
      final w = Period.m12.window(now: now);
      expect(w.unit, TimeUnit.month);
      expect(w.start, DateTime(2025, 8, 1));
    });
  });

  group('Account sérialisation', () {
    test('round-trip conserve la sélection de sites', () {
      const a = Account(
        id: 'a1',
        kind: ProviderKind.umami,
        baseUrl: 'https://x.fr',
        sites: ['s1', 's2'],
      );
      final back = Account.fromJson(a.toJson());
      expect(back.sites, ['s1', 's2']);
      expect(back.kind, ProviderKind.umami);
    });

    test('sites null = tous → includesSite toujours vrai', () {
      const a = Account(id: 'a', kind: ProviderKind.umami, baseUrl: 'x');
      expect(a.includesSite('nimporte'), isTrue);
    });

    test('copyWith allSites remet la sélection à tous', () {
      const a = Account(
        id: 'a',
        kind: ProviderKind.umami,
        baseUrl: 'x',
        sites: ['s1'],
      );
      expect(a.copyWith(allSites: true).sites, isNull);
    });
  });
}
