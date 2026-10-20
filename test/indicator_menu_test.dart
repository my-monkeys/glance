import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/account.dart';
import 'package:glance/data/models/indicator.dart';
import 'package:glance/data/models/indicator_result.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/models/period.dart';
import 'package:glance/state/indicators.dart';
import 'package:glance/state/period_state.dart';
import 'package:glance/state/providers.dart';
import 'package:glance/theme/theme.dart';
import 'package:glance/ui/dashboards/indicators_tab.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _site = Site(id: 's', accountId: 'a', name: 'S', domain: 's.fr');
final _window = DateWindow(DateTime(2026, 7, 1), DateTime(2026, 7, 5), TimeUnit.day);

class _Accounts extends AccountsNotifier {
  @override
  List<Account> build() =>
      const [Account(id: 'a', kind: ProviderKind.umami, baseUrl: 'https://u.fr')];
}

CounterIndicator _c(String id) =>
    CounterIndicator(id: id, name: 'Tableau $id', query: EventQuery('e$id'));

late ProviderContainer _container;

Future<void> _pump(WidgetTester tester, List<Indicator> initial) async {
  tester.view.physicalSize = const Size(375, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final overrides = <Override>[
    sharedPrefsProvider.overrideWithValue(prefs),
    accountsProvider.overrideWith(_Accounts.new),
    windowProvider.overrideWithValue(_window),
    eventNamesProvider.overrideWith((ref, site) async => ['e1']),
    indicatorDataProvider.overrideWith((ref, key) => const CounterData([], 0)),
  ];
  await tester.pumpWidget(ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: glanceTheme(Brightness.light),
      home: Scaffold(
        body: SingleChildScrollView(
          child: IndicatorsTab(site: _site, window: _window),
        ),
      ),
    ),
  ));
  _container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  for (final i in initial) {
    await _container.read(indicatorsProvider.notifier).add(_site, i);
  }
  await tester.pumpAndSettle();
}

List<String> _ids() =>
    _container.read(siteIndicatorsProvider(_site)).map((i) => i.id).toList();

Future<void> _openMenu(WidgetTester tester, int card) async {
  await tester.tap(find.byIcon(Icons.more_horiz_rounded).at(card));
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  testWidgets('état vide : « Créer un tableau » ouvre l\'éditeur', (tester) async {
    await _pump(tester, []);
    await _tapText(tester, 'Créer un tableau');
    expect(find.text('Nouveau tableau'), findsOneWidget);
  });

  testWidgets('« Nouveau tableau » suit les cartes', (tester) async {
    await _pump(tester, [_c('1')]);
    await _tapText(tester, 'Nouveau tableau');
    expect(find.text('Nouveau tableau'), findsOneWidget);
    expect(find.text('Créer'), findsOneWidget);
  });

  testWidgets('le menu cache Monter en tête et Descendre en queue', (tester) async {
    await _pump(tester, [_c('1'), _c('2'), _c('3')]);

    await _openMenu(tester, 0);
    expect(find.text('Monter'), findsNothing);
    expect(find.text('Descendre'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await _openMenu(tester, 2);
    expect(find.text('Monter'), findsOneWidget);
    expect(find.text('Descendre'), findsNothing);
  });

  testWidgets('Monter et Descendre réordonnent', (tester) async {
    await _pump(tester, [_c('1'), _c('2'), _c('3')]);

    await _openMenu(tester, 1);
    await _tapText(tester, 'Monter');
    expect(_ids(), ['2', '1', '3']);

    await _openMenu(tester, 0);
    await _tapText(tester, 'Descendre');
    expect(_ids(), ['1', '2', '3']);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Supprimer demande une seconde confirmation', (tester) async {
    await _pump(tester, [_c('1'), _c('2')]);

    await _openMenu(tester, 0);
    await _tapText(tester, 'Supprimer');
    expect(_ids(), ['1', '2']);
    await _tapText(tester, 'Confirmer la suppression');
    expect(_ids(), ['2']);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Modifier ouvre l\'éditeur sur le tableau', (tester) async {
    await _pump(tester, [_c('1')]);
    await _openMenu(tester, 0);
    await _tapText(tester, 'Modifier');
    expect(find.text('Modifier le tableau'), findsOneWidget);
  });
}
