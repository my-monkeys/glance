import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/account.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/l10n/app_localizations_fr.dart';
import 'package:glance/state/providers.dart';
import 'package:glance/theme/theme.dart';
import 'package:glance/ui/settings/account_menu.dart';
import 'helpers/l10n.dart';

final _fr = AppLocalizationsFr();

const _account = Account(
  id: 'a',
  kind: ProviderKind.umami,
  baseUrl: 'https://api.umami.is',
  sites: ['1'],
);

Site _site(String id) =>
    Site(id: id, accountId: 'a', name: 'Site $id', domain: '$id.fr');

class _Accounts extends AccountsNotifier {
  ({List<String>? sites, List<String> excluded})? saved;

  @override
  List<Account> build() => const [_account];

  @override
  Future<void> updateSites(
    String accountId,
    List<String>? sites, {
    List<String> excluded = const [],
  }) async {
    saved = (sites: sites, excluded: excluded);
  }
}

void main() {
  // Le menu se ferme avant d'ouvrir l'écran de choix : enregistrer passait par
  // le `ref` d'un widget démonté, qui lève une StateError, et rien n'était
  // enregistré (retour d'un testeur, 2026-11-06).
  testWidgets('« Choisir les sites » enregistre le choix une fois le menu fermé',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [
      accountsProvider.overrideWith(_Accounts.new),
      accountSitesProvider.overrideWith(
        (ref, id) async => [_site('1'), _site('2'), _site('3')],
      ),
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: testLocale,
        localizationsDelegates: glanceLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: glanceTheme(Brightness.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => openAccountMenu(context, _account),
              child: const Text('menu'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_fr.accountMenuChooseSites));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_fr.sitePickerFollowNew));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_fr.sitePickerCheckAll));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_fr.sitePickerFollowAll));
    await tester.pumpAndSettle();

    final saved = (container.read(accountsProvider.notifier) as _Accounts).saved;
    expect(saved, isNotNull);
    expect(saved!.sites, isNull);
    expect(saved.excluded, isEmpty);
    expect(find.text(_fr.accountMenuSelectionSaved), findsOneWidget);
    // Laisse le toast se retirer : sa minuterie survivrait au test.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    // Démonter l'arbre arme le cache des icônes (30 min) : le conteneur doit
    // être libéré dans le test, pas après.
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
}
