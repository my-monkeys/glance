import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/account.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/theme/theme.dart';
import 'package:glance/ui/add/site_picker.dart';

const _base = Account(id: 'a', kind: ProviderKind.umami, baseUrl: 'u.fr');

Site _site(String id) => Site(id: id, accountId: 'a', name: 'Site $id', domain: '$id.fr');

void main() {
  group('Account : sélection des sites', () {
    test('tous sauf les exclus, un nouveau site est inclus', () {
      final a = _base.copyWith(allSites: true, excluded: const ['x']);
      expect(a.followsNewSites, isTrue);
      expect(a.includesSite('x'), isFalse);
      expect(a.includesSite('nouveau'), isTrue);
    });

    test('liste explicite : un nouveau site est exclu, les exclusions oubliées', () {
      final a = _base
          .copyWith(allSites: true, excluded: const ['x'])
          .copyWith(sites: const ['s1']);
      expect(a.includesSite('s1'), isTrue);
      expect(a.includesSite('nouveau'), isFalse);
      expect(a.excludedSites, isEmpty);
    });

    test('changer le libellé garde la sélection', () {
      final a = _base.copyWith(allSites: true, excluded: const ['x']).copyWith(label: 'L');
      expect(a.sites, isNull);
      expect(a.excludedSites, ['x']);
    });

    test('JSON : aller-retour, clé absente quand rien n\'est exclu', () {
      final a = _base.copyWith(allSites: true, excluded: const ['x']);
      final back = Account.fromJson(a.toJson());
      expect(back.sites, isNull);
      expect(back.excludedSites, ['x']);
      expect(_base.toJson().containsKey('excludedSites'), isFalse);
      expect(Account.fromJson(_base.toJson()).excludedSites, isEmpty);
    });
  });

  group('écran de choix', () {
    final sites = [_site('1'), _site('2'), _site('3')];

    Future<SiteChoice?> pick(
      WidgetTester tester, {
      List<String>? initial,
      List<String> excluded = const [],
      required Future<void> Function() actions,
    }) async {
      // Ahem (glyphes carrés) élargit les libellés : 400 px déborderaient.
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SiteChoice? result;
      await tester.pumpWidget(ProviderScope(child: MaterialApp(
        theme: glanceTheme(Brightness.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<SiteChoice>(
                  MaterialPageRoute(
                    builder: (_) => SitePickerScreen(
                      providerName: 'Umami',
                      sites: sites,
                      initialSelection: initial,
                      initialExcluded: excluded,
                    ),
                  ),
                );
              },
              child: const Text('ouvrir'),
            ),
          ),
        ),
      )));
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      await actions();
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('décocher un site garde le suivi des nouveaux : exclusion',
        (tester) async {
      final r = await pick(tester, actions: () async {
        expect(find.text('Suivre tous les sites'), findsOneWidget);
        await tester.tap(find.text('Site 2'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Suivre 2 sites et les nouveaux'));
      });
      expect(r!.sites, isNull);
      expect(r.excluded, ['2']);
    });

    testWidgets('sans suivi des nouveaux : liste explicite', (tester) async {
      final r = await pick(tester, actions: () async {
        await tester.tap(find.text('Afficher les nouveaux sites'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Site 3'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Suivre 2 sites'));
      });
      expect(r!.sites, ['1', '2']);
      expect(r.excluded, isEmpty);
    });

    testWidgets('liste explicite existante : passer au suivi des nouveaux',
        (tester) async {
      final r = await pick(tester, initial: const ['1'], actions: () async {
        await tester.tap(find.text('Afficher les nouveaux sites'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Suivre 1 site et les nouveaux'));
      });
      expect(r!.sites, isNull);
      expect(r.excluded, ['2', '3']);
    });

    testWidgets('liste explicite de tous les sites : rouverte en « tous »',
        (tester) async {
      final r = await pick(tester, initial: const ['1', '2', '3'], actions: () async {
        await tester.tap(find.text('Suivre tous les sites'));
      });
      expect(r!.sites, isNull);
      expect(r.excluded, isEmpty);
    });

    testWidgets('exclusions existantes décochées, « Tout cocher » les rend',
        (tester) async {
      final r = await pick(tester, excluded: const ['3'], actions: () async {
        await tester.tap(find.text('Tout cocher'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Suivre tous les sites'));
      });
      expect(r!.sites, isNull);
      expect(r.excluded, isEmpty);
    });
  });
}
