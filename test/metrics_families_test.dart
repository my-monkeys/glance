import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/external_metrics.dart';
import 'package:glance/core/indicator_math.dart';
import 'package:glance/data/models/account.dart';
import 'package:glance/data/models/indicator.dart';
import 'package:glance/data/models/indicator_result.dart';
import 'package:glance/data/models/metrics_source.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/models/period.dart';
import 'package:glance/state/indicators.dart';
import 'package:glance/state/providers.dart';
import 'package:glance/theme/theme.dart';
import 'package:glance/ui/dashboards/indicators_tab.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

MetricDef _def(String id, int delay, {String? famille, String? libFamille}) =>
    MetricDef(
      id: id,
      libelle: 'Rétention $id',
      description: '',
      unite: MetricUnit.percent,
      granularites: const ['jour'],
      delaiJours: delay,
      famille: famille,
      libelleFamille: libFamille,
    );

final _catalogue = [
  _def('j30', 30, famille: 'ret', libFamille: 'Rétention · nouveaux joueurs'),
  _def('j1', 1, famille: 'ret', libFamille: 'Rétention · nouveaux joueurs'),
  _def('seul', 0),
  _def('j7', 7, famille: 'ret', libFamille: 'Rétention · nouveaux joueurs'),
];

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('familles du catalogue', () {
    test('lues du JSON, absentes → null', () {
      final d = MetricDef.fromJson({
        'id': 'a',
        'libelle': 'A',
        'unite': 'pourcentage',
        'famille': 'ret',
        'libelle_famille': 'Rétention',
        'delai_jours': 7,
      });
      expect(d.famille, 'ret');
      expect(d.libelleFamille, 'Rétention');
      final old = MetricDef.fromJson({'id': 'a', 'libelle': 'A', 'unite': 'nombre'});
      expect(old.famille, isNull);
      expect(old.libelleFamille, isNull);
    });

    test('metricFamiliesOf : membres triés par délai, métriques seules écartées', () {
      final f = metricFamiliesOf(_catalogue);
      expect(f, hasLength(1));
      expect(f.single.id, 'ret');
      expect(f.single.libelle, 'Rétention · nouveaux joueurs');
      expect(f.single.membres.map((m) => m.id), ['j1', 'j7', 'j30']);
      expect(metricFamiliesOf([_def('seul', 0)]), isEmpty);
    });
  });

  group('membre retenu', () {
    final membres = metricFamiliesOf(_catalogue).single.membres;
    String pick(int days) => chooseFamilyMember(membres, days).id;

    test('le plus grand délai qui tient dans la durée', () {
      expect(pick(1), 'j1'); // Aujourd'hui, 24 h
      expect(pick(7), 'j7'); // 7 jours
      expect(pick(21), 'j7'); // ce mois-ci le 21
      expect(pick(30), 'j30');
      expect(pick(365), 'j30'); // 12 m
    });

    test('aucun membre ne tient : le plus court', () {
      expect(chooseFamilyMember([membres[1], membres[2]], 3).id, 'j7');
    });

    test('durée d\'une fenêtre en jours, arrondie au-dessus', () {
      int days(DateTime a, DateTime b, TimeUnit u) => windowDays(DateWindow(a, b, u));
      expect(days(DateTime(2026, 10, 21), DateTime(2026, 10, 21, 15), TimeUnit.hour), 1);
      expect(days(DateTime(2026, 10, 20, 15), DateTime(2026, 10, 21, 15), TimeUnit.hour), 1);
      expect(days(DateTime(2026, 10, 15), DateTime(2026, 10, 22), TimeUnit.day), 7);
      expect(days(DateTime(2026, 10, 1), DateTime(2026, 10, 22), TimeUnit.day), 21);
    });
  });

  group('indicateur famille : JSON', () {
    const family = ExternalIndicator(
      id: 'f',
      name: 'Rétention',
      metricId: 'j30',
      label: 'Rétention · nouveaux joueurs',
      unit: MetricUnit.percent,
      familyId: 'ret',
    );
    const single = ExternalIndicator(
      id: 's',
      name: 'Seul',
      metricId: 'seul',
      label: 'Seul',
      unit: MetricUnit.count,
    );

    test('aller-retour des deux formes', () {
      expect(Indicator.fromJson(family.toJson()), family);
      expect(Indicator.fromJson(single.toJson()), single);
      expect(single.toJson().containsKey('family'), isFalse);
    });

    test('une app sans familles trouve ce qu\'elle exige : metric, label, unit',
        () {
      final j = family.toJson();
      expect(j['family'], 'ret');
      // `fromJson` d'avant les familles lit ces trois clés sans condition.
      expect(j['metric'], isA<String>());
      expect(j['metric'], 'j30');
      expect(j['label'], isA<String>());
      expect(j['unit'], isA<String>());
    });
  });

  group('hasDisplayableData', () {
    test('compteur', () {
      expect(hasDisplayableData(const CounterData([], 0)), isFalse);
      expect(
        hasDisplayableData(CounterData([SeriesPoint(DateTime(2026), 0, 0)], 0)),
        isFalse,
      );
      expect(hasDisplayableData(const CounterData([], 3)), isTrue);
    });

    test('taux : seul le dénominateur mesuré compte', () {
      RatioData r(int den) => RatioData(
            points: const [],
            overall: null,
            numeratorTotal: 0,
            denominatorTotal: den,
          );
      expect(hasDisplayableData(r(0)), isFalse);
      expect(hasDisplayableData(r(4)), isTrue);
    });

    test('entonnoir et répartition', () {
      expect(hasDisplayableData(const FunnelData([])), isFalse);
      expect(
        hasDisplayableData(const FunnelData([
          FunnelStepResult(event: 'a', filters: [], visitors: 0, remaining: 0),
        ])),
        isFalse,
      );
      expect(
        hasDisplayableData(const FunnelData([
          FunnelStepResult(event: 'a', filters: [], visitors: 2, remaining: 1),
        ])),
        isTrue,
      );
      expect(hasDisplayableData(const BreakdownData([], 0)), isFalse);
      expect(
        hasDisplayableData(const BreakdownData([MetricRow(label: 'x', value: 1)], 1)),
        isTrue,
      );
    });
  });

  group('onglet : cartes sans données', () {
    const site = Site(id: 's', accountId: 'a', name: 'S', domain: 's.fr');
    final window = DateWindow(DateTime(2026, 7, 1), DateTime(2026, 7, 5), TimeUnit.day);
    CounterIndicator c(String id) =>
        CounterIndicator(id: id, name: 'Tableau $id', query: EventQuery('e$id'));

    late ProviderContainer container;

    Future<void> pump(
      WidgetTester tester,
      List<Indicator> indicators,
      Set<String> withData,
    ) async {
      tester.view.physicalSize = const Size(375, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final overrides = <Override>[
        sharedPrefsProvider.overrideWithValue(prefs),
        accountsProvider.overrideWith(_Accounts.new),
        indicatorDataProvider.overrideWith((ref, key) =>
            CounterData([], withData.contains(key.$3.id) ? 5 : 0)),
      ];
      await tester.pumpWidget(ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: glanceTheme(Brightness.light),
          home: Scaffold(
            body: SingleChildScrollView(
              child: IndicatorsTab(site: site, window: window),
            ),
          ),
        ),
      ));
      container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      for (final i in indicators) {
        await container.read(indicatorsProvider.notifier).add(site, i);
      }
      await tester.pumpAndSettle();
    }

    testWidgets('3 cartes vides masquées, ligne « 3 tableaux », tap → affichées',
        (tester) async {
      await pump(tester, [c('1'), c('2'), c('3'), c('4')], {'1'});

      expect(find.text('Tableau 1'), findsOneWidget);
      expect(find.text('Tableau 2'), findsNothing);
      expect(find.textContaining('3 tableaux sans données sur cette période'),
          findsOneWidget);

      await tester.tap(find.textContaining('Afficher'));
      await tester.pumpAndSettle();
      for (final n in ['1', '2', '3', '4']) {
        expect(find.text('Tableau $n'), findsOneWidget);
      }
      expect(find.textContaining('sans données'), findsNothing);
    });

    testWidgets('singulier', (tester) async {
      await pump(tester, [c('1'), c('2')], {'1'});
      expect(find.textContaining('1 tableau sans données sur cette période'),
          findsOneWidget);
    });

    testWidgets('tout masqué : message et même lien', (tester) async {
      await pump(tester, [c('1'), c('2')], {});
      expect(find.text('Aucun tableau n\'a de données sur cette période'),
          findsOneWidget);
      expect(find.textContaining('2 tableaux sans données'), findsOneWidget);

      await tester.tap(find.textContaining('Afficher'));
      await tester.pumpAndSettle();
      expect(find.text('Tableau 1'), findsOneWidget);
      expect(find.text('Aucun tableau n\'a de données sur cette période'),
          findsNothing);
    });

    testWidgets('rien n\'est masqué quand tout a des données', (tester) async {
      await pump(tester, [c('1'), c('2')], {'1', '2'});
      expect(find.textContaining('sans données'), findsNothing);
      expect(find.text('Tableau 2'), findsOneWidget);
    });
  });
}

class _Accounts extends AccountsNotifier {
  @override
  List<Account> build() =>
      const [Account(id: 'a', kind: ProviderKind.umami, baseUrl: 'https://u.fr')];
}
