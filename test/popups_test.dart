import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/account.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/providers/analytics_provider.dart';
import 'package:glance/data/repository/accounts_repository.dart';
import 'package:glance/state/period_state.dart';
import 'package:glance/state/providers.dart';
import 'package:glance/theme/theme.dart';
import 'package:glance/ui/settings/settings_screen.dart';
import 'package:glance/ui/widgets/adaptive_sheet.dart';
import 'package:glance/ui/widgets/custom_range_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _account =
    Account(id: 'a', kind: ProviderKind.umami, baseUrl: 'https://u.fr', label: 'Mon Umami');

class _Accounts extends AccountsNotifier {
  @override
  List<Account> build() => const [_account];
}

class _Repo extends Fake implements AccountsRepository {
  @override
  Future<Map<String, String>> credentials(String accountId) async => {};
}

/// Fournisseur dont `verify` réussit ou échoue sur commande.
class _FakeProvider extends Fake implements AnalyticsProvider {
  _FakeProvider(this.verifyResult);

  final Future<int> Function() verifyResult;

  @override
  Future<int> verify() => verifyResult();

  @override
  Future<AccountHealth> health() async => AccountHealth.ok;

  @override
  Future<List<Site>> listSites() async => const [];
}

const _phone = 375.0;
const _desktop = 1200.0;

Future<void> _pumpSettings(
  WidgetTester tester,
  double width, {
  Future<int> Function()? verify,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final fake = _FakeProvider(verify ?? () async => 3);
  final overrides = <Override>[
    sharedPrefsProvider.overrideWithValue(prefs),
    accountsProvider.overrideWith(_Accounts.new),
    providerRegistryProvider.overrideWithValue(
      ProviderRegistry(_Repo(), const [_account], build: (_, _) => fake),
    ),
  ];
  await tester.pumpWidget(ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: glanceTheme(Brightness.light),
      home: const Scaffold(body: SettingsScreen()),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _tapRefreshRow(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Actualisation auto'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.text('Actualisation auto'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Actualisation auto'));
  await tester.pumpAndSettle();
}

Future<void> _openAccount(WidgetTester tester) async {
  await tester.tap(find.text('Mon Umami'));
  await tester.pumpAndSettle();
}

/// Le `DateRangePickerDialog` occupe toute la route : c'est son conteneur
/// interne qui porte la taille visible.
Size _dialogSize(WidgetTester tester) => tester.getSize(find
    .descendant(
      of: find.byType(DateRangePickerDialog),
      matching: find.byType(AnimatedContainer),
    )
    .first);

void main() {
  group('feuille ou pop-up selon la largeur', () {
    testWidgets('bureau : le menu du compte est un pop-up centré', (tester) async {
      await _pumpSettings(tester, _desktop);
      await _openAccount(tester);
      expect(find.byType(BottomSheet), findsNothing);
      final menu = find.text('Tester la connexion');
      expect(menu, findsOneWidget);
      final popup = find.ancestor(of: menu, matching: find.byType(ClipRRect)).first;
      final rect = tester.getRect(popup);
      expect(rect.width, lessThanOrEqualTo(kPopupWidth));
      expect(rect.center.dx, closeTo(_desktop / 2, 1));
      expect(rect.bottom, lessThan(900)); // pas collé au bas de l'écran
    });

    testWidgets('bureau : le choix de rafraîchissement est un pop-up',
        (tester) async {
      await _pumpSettings(tester, _desktop);
      await _tapRefreshRow(tester);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('5 min'), findsOneWidget);
      await tester.tap(find.text('5 min'));
      await tester.pumpAndSettle();
      expect(find.text('10 s'), findsNothing); // refermé
    });

    testWidgets('téléphone : toujours des feuilles', (tester) async {
      await _pumpSettings(tester, _phone);
      await _openAccount(tester);
      expect(find.byType(BottomSheet), findsOneWidget);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      await _tapRefreshRow(tester);
      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });

  group('Tester la connexion', () {
    testWidgets('succès : le résultat reste dans le menu, ouvert',
        (tester) async {
      await _pumpSettings(tester, _desktop, verify: () async => 3);
      await _openAccount(tester);
      await tester.tap(find.text('Tester la connexion'));
      await tester.pumpAndSettle();
      expect(find.text('Connexion réussie · 3 sites'), findsOneWidget);
      expect(find.text('Modifier la source'), findsOneWidget);
    });

    testWidgets('échec : le message d\'erreur s\'affiche dans le menu',
        (tester) async {
      await _pumpSettings(tester, _phone, verify: () async => throw Exception('boom'));
      await _openAccount(tester);
      await tester.tap(find.text('Tester la connexion'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Connexion réussie'), findsNothing);
      expect(find.text('Modifier la source'), findsOneWidget);
      // Libellé + message d'erreur dans la même ligne.
      expect(
        find.descendant(
          of: find.byType(ListTile).first,
          matching: find.byType(Text),
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('une relance après échec repart de zéro et réussit',
        (tester) async {
      var calls = 0;
      await _pumpSettings(tester, _desktop, verify: () async {
        if (calls++ == 0) throw Exception('réseau coupé');
        return 1;
      });
      await _openAccount(tester);
      await tester.tap(find.text('Tester la connexion'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Connexion réussie'), findsNothing);
      await tester.tap(find.text('Tester la connexion'));
      await tester.pumpAndSettle();
      expect(find.text('Connexion réussie · 1 site'), findsOneWidget);
    });
  });

  group('ProviderRegistry', () {
    test('ne garde pas un fournisseur en échec', () async {
      var builds = 0;
      final reg = ProviderRegistry(
        _Repo(),
        const [_account],
        build: (_, _) {
          if (builds++ == 0) throw StateError('Keychain refusé');
          return _FakeProvider(() async => 1);
        },
      );
      await expectLater(reg.forAccount('a'), throwsStateError);
      await pumpEventQueue();
      await reg.forAccount('a'); // reconstruit, ne rejoue pas l'échec
      expect(builds, 2);
    });

    test('garde un succès, et fresh() en reconstruit un', () async {
      var builds = 0;
      final reg = ProviderRegistry(
        _Repo(),
        const [_account],
        build: (_, _) {
          builds++;
          return _FakeProvider(() async => 1);
        },
      );
      final first = await reg.forAccount('a');
      expect(await reg.forAccount('a'), same(first));
      expect(builds, 1);
      expect(await reg.fresh('a'), isNot(same(first)));
      expect(builds, 2);
    });
  });

  group('période Perso', () {
    Future<ProviderContainer> pumpPicker(WidgetTester tester, double width) async {
      await initializeDateFormatting('fr_FR');
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: glanceTheme(Brightness.light),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => pickCustomPeriod(context, ref),
                child: const Text('Perso'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Perso'));
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    }

    testWidgets('bureau : un pop-up de taille bornée, pas un plein écran',
        (tester) async {
      await pumpPicker(tester, _desktop);
      final size = _dialogSize(tester);
      expect(size.width, lessThanOrEqualTo(kRangePickerSize.width));
      expect(size.height, lessThanOrEqualTo(kRangePickerSize.height));
    });

    testWidgets('téléphone : le pop-up garde une marge autour', (tester) async {
      await pumpPicker(tester, _phone);
      final size = _dialogSize(tester);
      expect(size.width, lessThanOrEqualTo(_phone - 2 * kRangePickerMargin));
      expect(size.width, lessThan(_phone));
    });

    testWidgets('choisir une plage la pose sur la période, fin à 23:59',
        (tester) async {
      final container = await pumpPicker(tester, _desktop);
      final today = DateTime.now().day;
      await tester.tap(find.text('$today').last);
      await tester.pump();
      await tester.tap(find.text('$today').last);
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final end = container.read(periodProvider).customEnd;
      expect(end?.hour, 23);
      expect(end?.minute, 59);
    });
  });
}
