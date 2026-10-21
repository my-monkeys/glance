import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/account.dart';
import 'package:glance/data/models/indicator.dart';
import 'package:glance/data/models/indicator_result.dart';
import 'package:glance/data/models/metrics_source.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/models/period.dart';
import 'package:glance/data/models/workspace.dart';
import 'package:glance/data/providers/metrics_api.dart';
import 'package:glance/state/indicators.dart';
import 'package:glance/state/metrics_sources.dart';
import 'package:glance/state/period_state.dart';
import 'package:glance/state/providers.dart';
import 'package:glance/theme/theme.dart';
import 'package:glance/ui/dashboards/editor/indicator_editor.dart';
import 'package:glance/ui/dashboards/indicator_card.dart';
import 'package:glance/ui/dashboards/metrics_source_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _site = Site(id: 's', accountId: 'a', name: 'S', domain: 's.fr');
final _window = DateWindow(DateTime(2026, 7, 1), DateTime(2026, 7, 4), TimeUnit.day);

const _defs = [
  MetricDef(
    id: 'retention_j1_nouveaux',
    libelle: 'Rétention J1 · nouveaux joueurs',
    description: 'Nouveaux joueurs revenus le lendemain.',
    unite: MetricUnit.percent,
    granularites: ['jour'],
  ),
  MetricDef(
    id: 'comptes',
    libelle: 'Comptes créés',
    description: '',
    unite: MetricUnit.count,
    granularites: ['jour'],
  ),
];

/// Client sans réseau : catalogue et séries fixes, ou une erreur.
class FakeMetricsApi extends MetricsApi {
  FakeMetricsApi({this.error, this.points = const [], this.defs = _defs})
      : super(baseUrl: 'https://x.eu/', token: 't', dio: Dio());
  final MetricsApiException? error;
  final List<MetricPoint> points;
  final List<MetricDef> defs;
  MetricsRange? lastRange;

  @override
  Future<List<MetricDef>> catalogue() async {
    if (error != null) throw error!;
    return defs;
  }

  @override
  Future<Map<String, List<MetricPoint>>> series({
    required List<String> ids,
    required MetricsRange range,
    required String tz,
  }) async {
    lastRange = range;
    if (error != null) throw error!;
    return {for (final id in ids) id: points};
  }
}

class _Accounts extends AccountsNotifier {
  @override
  List<Account> build() =>
      const [Account(id: 'a', kind: ProviderKind.umami, baseUrl: 'https://u.fr')];
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget Function(BuildContext) open, {
  FakeMetricsApi? api,
  bool withSource = false,
}) async {
  tester.view.physicalSize = const Size(375, 667);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    if (withSource)
      'glance.metricsSources': MetricsSource.encodeList(const [
        MetricsSource(site: SiteRef('a', 's'), baseUrl: 'https://x.eu/'),
      ]),
  });
  FlutterSecureStorage.setMockInitialValues(
      {if (withSource) 'glance.metricsToken.a.s': 'tok'});
  final prefs = await SharedPreferences.getInstance();
  final fake = api ?? FakeMetricsApi();
  final overrides = <Override>[
    sharedPrefsProvider.overrideWithValue(prefs),
    accountsProvider.overrideWith(_Accounts.new),
    windowProvider.overrideWithValue(_window),
    metricsApiFactoryProvider.overrideWithValue((_, _) => fake),
    eventNamesProvider.overrideWith((ref, site) async => ['partie']),
    indicatorDataProvider.overrideWith((ref, key) => const CounterData([], 0)),
  ];
  await tester.pumpWidget(ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: glanceTheme(Brightness.light),
      home: Builder(
        builder: (context) => Scaffold(body: open(context)),
      ),
    ),
  ));
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('écran de la source', () {
    Widget screen(BuildContext _) => const MetricsSourceScreen(site: _site);

    testWidgets('Tester annonce le nombre d\'indicateurs', (tester) async {
      await _pump(tester, screen);
      await tester.enterText(find.byType(TextField).at(0), 'https://x.eu/api/');
      await tester.enterText(find.byType(TextField).at(1), 'tok');
      await tester.pump();
      await tester.tap(find.text('Tester'));
      await tester.pumpAndSettle();

      expect(find.text('2 indicateurs disponibles'), findsOneWidget);
    });

    testWidgets('Tester affiche l\'erreur typée', (tester) async {
      await _pump(tester, screen,
          api: FakeMetricsApi(error: const MetricsBadToken()));
      await tester.enterText(find.byType(TextField).at(0), 'https://x.eu/api/');
      await tester.enterText(find.byType(TextField).at(1), 'faux');
      await tester.pump();
      await tester.tap(find.text('Tester'));
      await tester.pumpAndSettle();

      expect(find.text('Jeton refusé'), findsOneWidget);
    });

    testWidgets('Enregistrer garde l\'URL et le jeton', (tester) async {
      final c = await _pump(tester, (context) => TextButton(
            onPressed: () => openMetricsSource(context, _site),
            child: const Text('ouvrir'),
          ));
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'https://x.eu/api/');
      await tester.enterText(find.byType(TextField).at(1), 'tok');
      await tester.pump();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      final n = c.read(metricsSourcesProvider.notifier);
      expect(n.sourceFor(_site)!.baseUrl, 'https://x.eu/api/');
      expect(await n.tokenFor(const SiteRef('a', 's')), 'tok');
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('retrait de la source', () {
    const ext = ExternalIndicator(
        id: 'e1', name: 'A', metricId: 'm', label: 'A', unit: MetricUnit.count);
    const ext2 = ExternalIndicator(
        id: 'e2', name: 'B', metricId: 'm', label: 'B', unit: MetricUnit.count);
    const counter = CounterIndicator(
        id: 'c1', name: 'C', query: EventQuery('partie'));

    testWidgets('emporte les cartes « Métrique » et l\'annonce', (tester) async {
      final c = await _pump(
        tester,
        (_) => const MetricsSourceScreen(site: _site),
        withSource: true,
      );
      for (final i in [ext, counter, ext2]) {
        await c.read(indicatorsProvider.notifier).add(_site, i);
      }
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retirer la source'));
      await tester.pumpAndSettle();
      expect(find.text('Retirer la source et 2 tableaux'), findsOneWidget);
      await tester.tap(find.text('Retirer la source et 2 tableaux'));
      await tester.pumpAndSettle();

      expect(c.read(siteIndicatorsProvider(_site)), [counter]);
      expect(c.read(siteHasMetricsSourceProvider(_site)), isFalse);
      expect(
          await c
              .read(metricsSourcesProvider.notifier)
              .tokenFor(const SiteRef('a', 's')),
          isNull);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('sans carte : simple confirmation', (tester) async {
      await _pump(
        tester,
        (_) => const MetricsSourceScreen(site: _site),
        withSource: true,
      );
      await tester.tap(find.text('Retirer la source'));
      await tester.pumpAndSettle();
      expect(find.text('Retirer la source'), findsOneWidget);
      expect(find.textContaining('tableau'), findsNothing);
    });
  });

  group('éditeur', () {
    Widget editor(BuildContext c) => TextButton(
          onPressed: () => openIndicatorEditor(c, _site),
          child: const Text('ouvrir'),
        );

    testWidgets('pas de tuile « Métrique du site » sans source', (tester) async {
      await _pump(tester, editor);
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('Compteur'), findsOneWidget);
      expect(find.text('Métrique du site'), findsNothing);
    });

    testWidgets('avec une source : 5e tuile, choix dans le catalogue, création',
        (tester) async {
      final c = await _pump(tester, editor, withSource: true);
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('Un indicateur fourni par votre API'), findsOneWidget);
      await tester.tap(find.text('Métrique du site'));
      await tester.pumpAndSettle();
      expect(find.text('Choisissez une métrique'), findsOneWidget);

      await tester.tap(find.text('Choisir une métrique'));
      await tester.pumpAndSettle();
      expect(find.text('Nouveaux joueurs revenus le lendemain.'), findsOneWidget);
      await tester.tap(find.text('Rétention J1 · nouveaux joueurs'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      final created = c.read(siteIndicatorsProvider(_site)).single as ExternalIndicator;
      expect(created.metricId, 'retention_j1_nouveaux');
      expect(created.unit, MetricUnit.percent);
      expect(created.name, 'Rétention J1 · nouveaux joueurs');
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('carte « Métrique »', () {
    const ind = ExternalIndicator(
        id: 'e', name: 'J7', metricId: 'j7', label: 'Rétention J7', unit: MetricUnit.percent);

    Future<void> card(WidgetTester tester, RatioData data) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(await SharedPreferences.getInstance()),
          indicatorDataProvider.overrideWith((ref, key) => data),
        ],
        child: MaterialApp(
          theme: glanceTheme(Brightness.light),
          home: Scaffold(
            body: IndicatorCard(
                site: _site, window: _window, indicator: ind, menu: false),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('fenêtre décalée : mention des cohortes sous le chiffre',
        (tester) async {
      await card(
        tester,
        RatioData(
          points: [RatioPoint(DateTime(2026, 10, 7), 0.25)],
          overall: 0.25,
          numeratorTotal: 10,
          denominatorTotal: 40,
          cohorts: CohortSpan(DateTime(2026, 10, 7), DateTime(2026, 10, 13)),
        ),
      );
      expect(find.text('Cohortes du 7 au 13 oct.'), findsOneWidget);
    });

    testWidgets('cohortes en cours : « Pas encore mesurable »', (tester) async {
      await card(
        tester,
        RatioData(
          points: [RatioPoint(DateTime(2026, 10, 7), null)],
          overall: null,
          numeratorTotal: 0,
          denominatorTotal: 0,
          pending: true,
        ),
      );
      expect(find.text('Pas encore mesurable sur cette période'), findsOneWidget);
      expect(find.text('Aucune donnée sur la période'), findsNothing);
    });
  });

  group('indicatorDataProvider', () {
    const indicator = ExternalIndicator(
      id: 'e',
      name: 'Rétention',
      metricId: 'retention_j1_nouveaux',
      label: 'Rétention',
      unit: MetricUnit.percent,
    );

    Future<ProviderContainer> container(FakeMetricsApi api) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final c = ProviderContainer(overrides: [
        sharedPrefsProvider.overrideWithValue(await SharedPreferences.getInstance()),
        metricsApiFactoryProvider.overrideWithValue((_, _) => api),
      ]);
      addTearDown(c.dispose);
      await c.read(metricsSourcesProvider.notifier).set(_site, 'https://x.eu/', 't');
      return c;
    }

    test('série de la source → RatioData, plage demandée alignée', () async {
      final api = FakeMetricsApi(points: [
        MetricPoint(
            t: DateTime(2026, 7, 1), valeur: 20, numerateur: 10, denominateur: 50),
      ]);
      final c = await container(api);
      final sub = c.listen(
          indicatorDataProvider((_site, _window, indicator)), (_, _) {});
      final d = await c.read(
          indicatorDataProvider((_site, _window, indicator)).future) as RatioData;
      sub.close();

      expect(d.overall, closeTo(0.2, 1e-9));
      expect(d.points.map((p) => p.value), [closeTo(0.2, 1e-9), null, null]);
      expect(api.lastRange, (de: '2026-07-01', a: '2026-07-03', granularite: 'jour'));
    });

    test('le délai du catalogue décale la plage demandée', () async {
      const defs = [
        MetricDef(
          id: 'retention_j1_nouveaux',
          libelle: 'J7',
          description: '',
          unite: MetricUnit.percent,
          granularites: ['jour'],
          delaiJours: 7,
        ),
      ];
      final api = FakeMetricsApi(defs: defs);
      final c = await container(api);
      final w = DateWindow(DateTime.now().subtract(const Duration(days: 7)),
          DateTime.now().add(const Duration(days: 1)), TimeUnit.day);
      final sub = c.listen(indicatorDataProvider((_site, w, indicator)), (_, _) {});
      final d = await c.read(indicatorDataProvider((_site, w, indicator)).future)
          as RatioData;
      sub.close();

      expect(d.cohorts, isNotNull);
      final t = DateTime.now();
      final lastCohort = DateTime(t.year, t.month, t.day - 8);
      expect(d.cohorts!.last, lastCohort);
      expect(api.lastRange!.a,
          '${lastCohort.year}-${lastCohort.month.toString().padLeft(2, '0')}-${lastCohort.day.toString().padLeft(2, '0')}');
    });

    test('l\'erreur typée de l\'API remonte telle quelle', () async {
      final c = await container(
          FakeMetricsApi(error: const MetricsNotConfigured()));
      final sub = c.listen(
          indicatorDataProvider((_site, _window, indicator)), (_, _) {});
      await expectLater(
        c.read(indicatorDataProvider((_site, _window, indicator)).future),
        throwsA(isA<MetricsNotConfigured>()),
      );
      sub.close();
    });
  });
}
