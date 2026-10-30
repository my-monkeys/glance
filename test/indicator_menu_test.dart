import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/grid_layout.dart';
import 'package:glance/data/models/account.dart';
import 'package:glance/data/models/indicator.dart';
import 'package:glance/data/models/indicator_result.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/models/period.dart';
import 'package:glance/state/indicators.dart';
import 'package:glance/state/period_state.dart';
import 'package:glance/state/providers.dart';
import 'package:glance/theme/theme.dart';
import 'package:glance/ui/dashboards/indicator_card.dart';
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
    // Des valeurs : une carte sans donnée serait masquée par l'onglet.
    indicatorDataProvider.overrideWith((ref, key) => const CounterData([], 5)),
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

  testWidgets('le menu ne propose plus Monter ni Descendre', (tester) async {
    await _pump(tester, [_c('1'), _c('2')]);
    await _openMenu(tester, 0);
    expect(find.text('Monter'), findsNothing);
    expect(find.text('Descendre'), findsNothing);
    expect(find.text('Modifier'), findsOneWidget);
  });

  // 375 px de large moins les marges : une grille de 2 colonnes, où chaque
  // compteur fait 2 × 5 cellules (54 px par rangée).
  Map<String, GridSlot> layout() =>
      _container.read(siteLayoutsProvider(_site))[2]!;

  testWidgets('Organiser : un appui long puis un glissement échange deux cartes',
      (tester) async {
    await _pump(tester, [_c('1'), _c('2')]);
    await _tapText(tester, 'Organiser');
    expect(find.text('Terminé'), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);

    final g = await tester.startGesture(
      tester.getCenter(find.byType(IndicatorCard).first),
    );
    await tester.pump(const Duration(milliseconds: 300));
    for (var i = 0; i < 6; i++) {
      await g.moveBy(const Offset(0, 50));
      await tester.pump();
    }
    await g.up();
    await tester.pumpAndSettle();

    expect(_ids(), ['2', '1']);
    expect(layout()['2'], const GridSlot(0, 0, 2, 5));
    expect(layout()['1'], const GridSlot(0, 5, 2, 5));
  });

  testWidgets('Organiser : le coin redimensionne et pousse la carte suivante',
      (tester) async {
    await _pump(tester, [_c('1'), _c('2')]);
    await _tapText(tester, 'Organiser');

    final corner =
        tester.getBottomRight(find.byType(IndicatorCard).first) - const Offset(8, 8);
    final g = await tester.startGesture(corner);
    await g.moveBy(const Offset(-120, 0));
    await tester.pump();
    await g.moveBy(const Offset(0, 108));
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();

    expect(layout()['1'], const GridSlot(0, 0, 1, 7));
    expect(layout()['2'], const GridSlot(0, 7, 2, 5));
  });

  testWidgets('Terminé quitte le mode Organiser', (tester) async {
    await _pump(tester, [_c('1')]);
    await _tapText(tester, 'Organiser');
    await _tapText(tester, 'Terminé');
    expect(find.text('Organiser'), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
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
