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
import 'package:glance/ui/dashboards/editor/indicator_editor.dart';
import 'package:glance/ui/dashboards/indicator_card.dart';
import 'package:glance/ui/widgets/field.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _site = Site(id: 's', accountId: 'a', name: 'S', domain: 's.fr');
final _window = DateWindow(DateTime(2026, 7, 1), DateTime(2026, 7, 5), TimeUnit.day);

class _Accounts extends AccountsNotifier {
  @override
  List<Account> build() =>
      const [Account(id: 'a', kind: ProviderKind.umami, baseUrl: 'https://u.fr')];
}

const _issue = EventFilter(
  property: 'issue',
  type: PropertyType.string,
  op: FilterOp.eq,
  value: 'complet',
);

late ProviderContainer _container;

Future<void> _pump(WidgetTester tester, {Indicator? initial}) async {
  tester.view.physicalSize = const Size(375, 667);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final overrides = <Override>[
    sharedPrefsProvider.overrideWithValue(prefs),
    accountsProvider.overrideWith(_Accounts.new),
    windowProvider.overrideWithValue(_window),
    eventNamesProvider.overrideWith(
      (ref, site) async => ['partie_demarree', 'partie_terminee'],
    ),
    eventPropertiesProvider.overrideWith(
      (ref, key) async => [
        const EventProperty('issue', PropertyType.string),
        const EventProperty('score', PropertyType.number),
      ],
    ),
    propertyValuesProvider.overrideWith(
      (ref, key) async => [
        const MetricRow(label: 'complet', value: 8),
        const MetricRow(label: 'abandon', value: 2),
      ],
    ),
    indicatorDataProvider.overrideWith((ref, key) => const CounterData([], 0)),
  ];
  await tester.pumpWidget(ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: glanceTheme(Brightness.light),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => openIndicatorEditor(context, _site, initial: initial),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    ),
  ));
  _container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  if (initial != null) {
    await _container.read(indicatorsProvider.notifier).add(_site, initial);
  }
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
}

/// Fait défiler la liste de l'éditeur jusqu'à la cible (une liste paresseuse ne
/// construit pas ce qui est loin sous le pli), puis tape.
Future<void> _tap(WidgetTester tester, Finder f) async {
  if (f.evaluate().isEmpty) {
    await tester.scrollUntilVisible(f, 200,
        scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

List<Indicator> _stored() => _container.read(siteIndicatorsProvider(_site));

GlanceButton _primary(WidgetTester tester) =>
    tester.widget<GlanceButton>(find.byType(GlanceButton).last);

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  testWidgets('crée un taux : événements, filtre par suggestion', (tester) async {
    await _pump(tester);
    expect(find.text('Nouveau tableau'), findsOneWidget);

    await _tap(tester, find.text('Taux'));
    await _tap(tester, find.text('Choisir un événement').first);
    await _tap(tester, find.text('partie_terminee'));

    await _tap(tester, find.text('Ajouter un filtre').first);
    await _tap(tester, find.text('Choisir une propriété'));
    await _tap(tester, find.text('issue'));
    await _tap(tester, find.text('complet'));
    await _tap(tester, find.text('Ajouter'));
    expect(find.text('issue = complet'), findsOneWidget);

    await _tap(tester, find.text('Choisir un événement'));
    await _tap(tester, find.text('partie_demarree'));

    await _tap(tester, find.text('Créer'));
    final created = _stored().single as RatioIndicator;
    expect(created.numerator, const EventQuery('partie_terminee', [_issue]));
    expect(created.denominator, const EventQuery('partie_demarree'));
    expect(created.name, 'partie_terminee · issue = complet / partie_demarree');
    expect(find.text('Nouveau tableau'), findsNothing);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('modifie un compteur : renommer, enregistrer', (tester) async {
    const old = CounterIndicator(
        id: 'c1', name: 'Parties', query: EventQuery('partie_demarree'));
    await _pump(tester, initial: old);
    expect(find.text('Modifier le tableau'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Parties lancées');
    await tester.pumpAndSettle();
    // L'aperçu est la vraie carte, sans son menu.
    await tester.scrollUntilVisible(find.byType(IndicatorCard), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.byType(IndicatorCard), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
    await _tap(tester, find.text('Enregistrer'));

    expect(
      _stored().single,
      const CounterIndicator(
        id: 'c1',
        name: 'Parties lancées',
        query: EventQuery('partie_demarree'),
      ),
    );
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('entonnoir : ajouter et retirer une étape, opérateurs', (tester) async {
    await _pump(tester);
    await _tap(tester, find.text('Entonnoir'));
    expect(find.text('ÉTAPE 2'), findsOneWidget);

    await _tap(tester, find.text('Ajouter une étape'));
    expect(find.text('ÉTAPE 3'), findsOneWidget);
    await _tap(tester, find.byTooltip('Retirer l\'étape').first);
    expect(find.text('ÉTAPE 3'), findsNothing);

    await _tap(tester, find.text('Choisir un événement').first);
    await _tap(tester, find.text('partie_demarree'));
    await _tap(tester, find.text('Ajouter un filtre').first);
    await _tap(tester, find.text('Choisir une propriété'));
    await _tap(tester, find.text('score'));
    // Nombre : seuls = et ≠ survivent à la limite d'Umami.
    expect(find.text('='), findsOneWidget);
    expect(find.text('≠'), findsOneWidget);
    for (final op in ['>', '≥', '<', '≤']) {
      expect(find.text(op), findsNothing, reason: op);
    }
  });

  testWidgets('supprime avec confirmation en ligne', (tester) async {
    const old = CounterIndicator(
        id: 'c1', name: 'Parties', query: EventQuery('partie_demarree'));
    await _pump(tester, initial: old);

    await _tap(tester, find.text('Supprimer ce tableau'));
    expect(_stored(), hasLength(1));
    expect(find.text('Confirmer la suppression'), findsOneWidget);

    await _tap(tester, find.text('Confirmer la suppression'));
    expect(_stored(), isEmpty);
    expect(find.text('Modifier le tableau'), findsNothing);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('« Créer » reste inactif tant que le brouillon est invalide',
      (tester) async {
    await _pump(tester);
    expect(_primary(tester).onTap, isNull);
    expect(find.text('Choisissez un événement'), findsOneWidget);

    await _tap(tester, find.text('Choisir un événement'));
    await _tap(tester, find.text('partie_demarree'));
    expect(_primary(tester).onTap, isNotNull);
    expect(find.text('Choisissez un événement'), findsNothing);
  });
}
