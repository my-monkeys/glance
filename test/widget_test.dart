import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/account.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/models/period.dart';
import 'package:glance/data/models/workspace.dart';

void main() {
  group('Period.window', () {
    final now = DateTime(2026, 7, 10, 14, 30);

    test('7 jours = 7 jours pleins alignés sur la grille', () {
      final w = Period.d7.window(now: now);
      expect(w.unit, TimeUnit.day);
      expect(w.start, DateTime(2026, 7, 4));
      expect(w.end, DateTime(2026, 7, 11)); // plafonné au jour suivant
    });

    test("aujourd'hui : minuit → fin de l'heure courante, granularité heure", () {
      final w = Period.today.window(now: now);
      expect(w.unit, TimeUnit.hour);
      expect(w.start, DateTime(2026, 7, 10));
      expect(w.end, DateTime(2026, 7, 10, 15)); // 14h30 → 15h
    });

    test('fenêtre stable dans la même heure (clé identique)', () {
      final a = Period.today.window(now: DateTime(2026, 7, 10, 14, 5));
      final b = Period.today.window(now: DateTime(2026, 7, 10, 14, 55));
      expect(a, b); // même clé → pas de rechargement / flash
    });

    test('dayOffset = jour passé complet, granularité heure', () {
      final w = Period.today.window(now: now, dayOffset: -1);
      expect(w.unit, TimeUnit.hour);
      expect(w.start, DateTime(2026, 7, 9));
      expect(w.end, DateTime(2026, 7, 10)); // journée entière d'hier
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

    test('sites [] = aucun → includesSite toujours faux (et round-trip)', () {
      const a = Account(
        id: 'a',
        kind: ProviderKind.umami,
        baseUrl: 'x',
        sites: [],
      );
      expect(a.includesSite('nimporte'), isFalse);
      // La liste vide (aucun) ne doit pas se confondre avec null (tous).
      final back = Account.fromJson(a.toJson());
      expect(back.sites, isNotNull);
      expect(back.sites, isEmpty);
      expect(back.includesSite('nimporte'), isFalse);
    });

    test('copyWith(sites: []) = aucun (distinct de allSites)', () {
      const a = Account(
        id: 'a',
        kind: ProviderKind.umami,
        baseUrl: 'x',
        sites: ['s1'],
      );
      expect(a.copyWith(sites: const []).sites, isEmpty);
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

  group('Workspace', () {
    Site site(String id, String accountId) =>
        Site(id: id, accountId: accountId, name: id, domain: '$id.fr');

    test('contains identifie le site par (compte, id)', () {
      final w = Workspace(
        id: 'w',
        name: 'Jeux',
        sites: [SiteRef.of(site('s1', 'a1'))],
      );
      expect(w.contains(site('s1', 'a1')), isTrue);
      // Même id de site mais autre compte → site différent (cf. Site.==).
      expect(w.contains(site('s1', 'a2')), isFalse);
      expect(w.contains(site('s2', 'a1')), isFalse);
    });

    test('une référence orpheline est simplement ignorée au filtrage', () {
      final w = Workspace(
        id: 'w',
        name: 'Jeux',
        sites: [
          SiteRef.of(site('s1', 'a1')),
          const SiteRef('compte-supprimé', 's9'),
        ],
      );
      final connus = [site('s1', 'a1'), site('s2', 'a1')];
      // Pas de nettoyage nécessaire : le filtre intersecte avec les sites connus.
      expect(connus.where(w.contains).map((s) => s.id), ['s1']);
    });

    test('round-trip conserve nom, références, icône et couleur', () {
      final w = Workspace(
        id: 'w1',
        name: 'Clients',
        sites: [SiteRef.of(site('s1', 'a1')), SiteRef.of(site('s2', 'a2'))],
        icon: WorkspaceIcon.travail,
        color: WorkspaceColor.ardoise,
      );
      final back = Workspace.decodeList(Workspace.encodeList([w])).single;
      expect(back.id, 'w1');
      expect(back.name, 'Clients');
      expect(back.sites, w.sites);
      expect(back.icon, WorkspaceIcon.travail);
      expect(back.color, WorkspaceColor.ardoise);
    });

    test('groupe sans icône/couleur (créé avant) = valeurs par défaut', () {
      // JSON d'un groupe d'avant l'ajout de l'apparence : pas de migration,
      // les champs manquants retombent sur les valeurs par défaut.
      final back = Workspace.fromJson({
        'id': 'w',
        'name': 'Ancien',
        'sites': [
          {'a': 'a1', 's': 's1'},
        ],
      });
      expect(back.icon, WorkspaceIcon.dossier);
      expect(back.color, WorkspaceColor.forest);
      expect(back.contains(site('s1', 'a1')), isTrue);
    });

    test('groupe sans site = groupe vide (pas « tous »)', () {
      const w = Workspace(id: 'w', name: 'Vide');
      final back = Workspace.decodeList(Workspace.encodeList([w])).single;
      expect(back.sites, isEmpty);
      expect(back.contains(site('s1', 'a1')), isFalse);
    });

    test('la liste décodée est modifiable', () {
      final list = Workspace.decodeList(
        Workspace.encodeList([const Workspace(id: 'w', name: 'A')]),
      );
      // Cf. le piège d'Account.decodeList (growable:false → suppression KO).
      expect(() => list.removeWhere((e) => e.id == 'w'), returnsNormally);
    });
  });
}
