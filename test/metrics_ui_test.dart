import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/format.dart';
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
import 'package:glance/ui/dashboards/indicator_chart.dart';
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

  group('cartes : libellés et graphique', () {
    const ind = ExternalIndicator(
        id: 'e', name: 'J7', metricId: 'j7', label: 'Rétention J7', unit: MetricUnit.percent);

    Future<void> card(
      WidgetTester tester,
      IndicatorData data, {
      Indicator indicator = ind,
    }) async {
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
                site: _site, window: _window, indicator: indicator, menu: false),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    RatioData ratio(List<double?> values, {CohortSpan? cohorts}) => RatioData(
          points: [
            for (var i = 0; i < values.length; i++)
              RatioPoint(DateTime(2026, 10, 15 + i), values[i]),
          ],
          overall: 0.25,
          numeratorTotal: 10,
          denominatorTotal: 40,
          cohorts: cohorts,
        );

    testWidgets('plusieurs cohortes : libellé pluriel, graphique, pas de ligne '
        'qui répète le titre', (tester) async {
      await card(
        tester,
        ratio([0.2, 0.3, null],
            cohorts: CohortSpan(DateTime(2026, 10, 8), DateTime(2026, 10, 14))),
      );
      expect(find.text('Mesurée sur les cohortes du 8 au 14 oct.'), findsOneWidget);
      expect(find.byType(IndicatorChart), findsOneWidget);
      expect(find.text('Rétention J7'), findsNothing);
      expect(find.text('10 / 40'), findsOneWidget);
    });

    testWidgets('une seule cohorte : libellé singulier', (tester) async {
      await card(
        tester,
        ratio([0.2],
            cohorts: CohortSpan(DateTime(2026, 10, 19), DateTime(2026, 10, 19))),
      );
      expect(find.text('Mesurée sur la cohorte du 19 oct.'), findsOneWidget);
    });

    testWidgets('moins de 2 points non nuls : le chiffre, sans graphique',
        (tester) async {
      await card(tester, ratio([null, 0.25, null]));
      expect(find.byType(IndicatorChart), findsNothing);
      expect(find.text(fmtPct(25).replaceAll('\u202f', '\u00a0')), findsOneWidget);
      expect(find.text('10 / 40'), findsOneWidget);
    });

    testWidgets('cohortes en cours avec délai : le recul nécessaire est dit',
        (tester) async {
      await card(
        tester,
        RatioData(
          points: [RatioPoint(DateTime(2026, 10, 21), null)],
          overall: null,
          numeratorTotal: 0,
          denominatorTotal: 0,
          pending: true,
          delayDays: 7,
        ),
      );
      expect(find.text('Pas encore mesurable : il faut 7 jours de recul'),
          findsOneWidget);
    });

    testWidgets('cohortes en cours : « Pas encore mesurable », sans graphique',
        (tester) async {
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
      expect(find.byType(IndicatorChart), findsNothing);
    });

    testWidgets('compteur tout à zéro : 0 et « Aucun événement », sans courbe',
        (tester) async {
      await card(
        tester,
        CounterData([
          for (var i = 0; i < 3; i++) SeriesPoint(DateTime(2026, 7, 1 + i), 0, 0),
        ], 0),
        indicator: const CounterIndicator(
            id: 'c', name: 'Parties', query: EventQuery('partie')),
      );
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Aucun événement sur la période'), findsOneWidget);
      expect(find.byType(IndicatorChart), findsNothing);
    });

    testWidgets('ligne de requête : omise si elle répète le nom, sinon affichée',
        (tester) async {
      final data = CounterData([
        for (var i = 0; i < 3; i++) SeriesPoint(DateTime(2026, 7, 1 + i), 4, 0),
      ], 12);
      await card(tester, data,
          indicator: const CounterIndicator(
              id: 'c', name: 'partie', query: EventQuery('partie')));
      expect(find.text('partie'), findsOneWidget); // le titre seul
      expect(find.byType(IndicatorChart), findsOneWidget);

      await card(tester, data,
          indicator: const CounterIndicator(
              id: 'c', name: 'Parties jouées', query: EventQuery('partie')));
      expect(find.text('partie'), findsOneWidget); // la ligne de requête
      expect(find.text('Parties jouées'), findsOneWidget);
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

    test('le délai du catalogue : cohortes demandées −d, points à leur date de mesure',
        () async {
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
      final t = DateTime.now();
      final today = DateTime(t.year, t.month, t.day);
      final w = DateWindow(DateTime(t.year, t.month, t.day - 6),
          DateTime(t.year, t.month, t.day + 1), TimeUnit.day);
      final sub = c.listen(indicatorDataProvider((_site, w, indicator)), (_, _) {});
      final d = await c.read(indicatorDataProvider((_site, w, indicator)).future)
          as RatioData;
      sub.close();

      String iso(DateTime x) =>
          '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
      expect(api.lastRange!.de, iso(DateTime(today.year, today.month, today.day - 13)));
      expect(api.lastRange!.a, iso(DateTime(today.year, today.month, today.day - 7)));
      // L'axe reste celui de la période choisie.
      expect(d.points.first.t, DateTime(today.year, today.month, today.day - 6));
      expect(d.points.last.t, today);
    });

    test('famille : le membre suit la durée de la fenêtre', () async {
      MetricDef m(String id, int d) => MetricDef(
            id: id,
            libelle: id,
            description: '',
            unite: MetricUnit.percent,
            granularites: const ['jour'],
            delaiJours: d,
            famille: 'ret',
            libelleFamille: 'Rétention',
          );
      final api = FakeMetricsApi(defs: [m('j1', 1), m('j7', 7), m('j30', 30)]);
      final c = await container(api);
      const family = ExternalIndicator(
        id: 'f',
        name: 'Rétention',
        metricId: 'j30',
        label: 'Rétention',
        unit: MetricUnit.percent,
        familyId: 'ret',
      );
      final t = DateTime.now();
      Future<RatioData> read(DateWindow w) async {
        final sub = c.listen(indicatorDataProvider((_site, w, family)), (_, _) {});
        final d = await c.read(indicatorDataProvider((_site, w, family)).future)
            as RatioData;
        sub.close();
        return d;
      }

      final day = DateWindow(DateTime(t.year, t.month, t.day),
          DateTime(t.year, t.month, t.day + 1), TimeUnit.day);
      final week = DateWindow(DateTime(t.year, t.month, t.day - 6),
          DateTime(t.year, t.month, t.day + 1), TimeUnit.day);
      expect((await read(day)).member, 'J1');
      expect((await read(week)).member, 'J7');
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
