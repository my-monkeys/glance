import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/format.dart';
import 'package:glance/data/models/indicator.dart';
import 'package:glance/data/models/indicator_result.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/models/period.dart';
import 'package:glance/state/indicators.dart';
import 'package:glance/state/providers.dart';
import 'package:glance/theme/theme.dart';
import 'package:glance/ui/widgets/events_chart.dart';
import 'package:glance/ui/dashboards/indicator_card.dart';
import 'package:glance/ui/dashboards/indicators_tab.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _site = Site(id: 's', accountId: 'a', name: 'S', domain: 's.fr');
final _window = DateWindow(DateTime(2026, 7, 1), DateTime(2026, 7, 5), TimeUnit.day);
final _days = [for (var d = 0; d < 4; d++) DateTime(2026, 7, 1 + d)];

Widget _host(List<Override> overrides, Widget child) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: glanceTheme(Brightness.light),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

Future<void> _pumpCard(
  WidgetTester tester,
  Indicator indicator,
  IndicatorData data,
) async {
  tester.view.physicalSize = const Size(640, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_host(
    [indicatorDataProvider.overrideWith((ref, key) => data)],
    IndicatorCard(site: _site, window: _window, indicator: indicator),
  ));
  await tester.pumpAndSettle();
}

/// Le grand chiffre remplace U+202F par une espace insécable ordinaire.
String _big(String s) => s.replaceAll('\u202f', '\u00a0');

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  testWidgets('compteur : total et courbe', (tester) async {
    await _pumpCard(
      tester,
      const CounterIndicator(id: '1', name: 'Parties', query: EventQuery('partie_demarree')),
      CounterData([
        for (var i = 0; i < 4; i++) SeriesPoint(_days[i], i * 10.0, 0),
      ], 1234),
    );
    expect(find.text(_big(fmtInt(1234))), findsOneWidget);
    expect(find.text('Parties'), findsOneWidget);
    expect(find.text('COMPTEUR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('taux : pourcentage global, trous conservés', (tester) async {
    await _pumpCard(
      tester,
      const RatioIndicator(
        id: '2',
        name: "Taux d'achèvement",
        numerator: EventQuery('partie_terminee'),
        denominator: EventQuery('partie_demarree'),
      ),
      RatioData(
        points: [
          RatioPoint(_days[0], 0.5),
          RatioPoint(_days[1], null),
          RatioPoint(_days[2], 0.75),
          RatioPoint(_days[3], null),
        ],
        overall: 0.625,
        numeratorTotal: 5,
        denominatorTotal: 8,
      ),
    );
    expect(find.text(_big(fmtPct(62.5))), findsOneWidget);
    expect(find.text('5 / 8'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('taux sans dénominateur : pas de donnée', (tester) async {
    await _pumpCard(
      tester,
      const RatioIndicator(
        id: '2',
        name: 'T',
        numerator: EventQuery('a'),
        denominator: EventQuery('b'),
      ),
      const RatioData(
          points: [], overall: null, numeratorTotal: 0, denominatorTotal: 0),
    );
    expect(find.text('Aucune donnée sur la période'), findsOneWidget);
  });

  testWidgets('entonnoir : part finale, une barre par étape, pertes', (tester) async {
    await _pumpCard(
      tester,
      FunnelIndicator(id: '3', name: 'Parcours', steps: const [
        EventQuery('jeu_choisi'),
        EventQuery('partie_demarree'),
      ]),
      const FunnelData([
        FunnelStepResult(event: 'jeu_choisi', filters: [], visitors: 100, remaining: 1),
        FunnelStepResult(
          event: 'partie_jalon',
          filters: [
            EventFilter(
                property: 'part',
                type: PropertyType.number,
                op: FilterOp.eq,
                value: '25'),
          ],
          visitors: 73,
          remaining: 0.73,
          dropoff: 0.27,
        ),
      ]),
    );
    expect(find.text(_big(fmtPct(73))), findsOneWidget);
    expect(find.text('partie_jalon'), findsOneWidget);
    expect(find.text('part = 25'), findsOneWidget);
    expect(find.text('−${fmtPct(27, decimals: 0)}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('répartition : total et part du total', (tester) async {
    await _pumpCard(
      tester,
      const BreakdownIndicator(
          id: '4', name: 'Par jeu', event: 'partie_demarree', property: 'jeu'),
      const BreakdownData(
        [MetricRow(label: 'france', value: 30), MetricRow(label: 'flags', value: 10)],
        40,
      ),
    );
    expect(find.text('40'), findsOneWidget);
    expect(find.text(fmtPct(75, decimals: 0)), findsOneWidget);
    expect(find.text(fmtPct(25, decimals: 0)), findsOneWidget);
  });

  testWidgets('répartition vide : pas de donnée', (tester) async {
    await _pumpCard(
      tester,
      const BreakdownIndicator(
          id: '4', name: 'Par jeu', event: 'e', property: 'p'),
      const BreakdownData([], 0),
    );
    expect(find.text('Aucune donnée sur la période'), findsOneWidget);
  });

  testWidgets('répartition dans le temps : courbes, puces et barres', (tester) async {
    EventSeries serie(String n, List<double> v) => EventSeries(
          name: n,
          points: [for (var i = 0; i < v.length; i++) SeriesPoint(_days[i], v[i], 0)],
          total: v.fold<double>(0, (a, b) => a + b).round(),
        );
    await _pumpCard(
      tester,
      const BreakdownIndicator(
          id: '4', name: 'Par jeu', event: 'partie', property: 'jeu', overTime: true),
      BreakdownData(
        const [MetricRow(label: 'france', value: 30), MetricRow(label: 'flags', value: 10)],
        40,
        [serie('france', [5, 10, 15, 0]), serie('flags', [1, 2, 3, 4])],
      ),
    );
    expect(find.byType(EventsChart), findsOneWidget);
    expect(find.byType(EventChip), findsNWidgets(2));
    expect(find.text(fmtPct(75, decimals: 0)), findsOneWidget);

    await tester.tap(find.byType(EventChip).first);
    await tester.pumpAndSettle();
    expect(tester.widget<EventsChart>(find.byType(EventsChart)).series.map((s) => s.name),
        ['flags']);
  });

  testWidgets('répartition dans le temps sans point : barres seules', (tester) async {
    await _pumpCard(
      tester,
      const BreakdownIndicator(
          id: '4', name: 'Par jeu', event: 'partie', property: 'jeu', overTime: true),
      BreakdownData(
        const [MetricRow(label: 'france', value: 1)],
        1,
        [EventSeries(name: 'france', points: [SeriesPoint(_days[0], 1, 0)], total: 1)],
      ),
    );
    expect(find.byType(EventsChart), findsNothing);
    expect(find.text(fmtPct(100, decimals: 0)), findsOneWidget);
  });

  testWidgets('onglet : une carte large prend toute la largeur, les autres 2 colonnes',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    CounterIndicator c(String id) =>
        CounterIndicator(id: id, name: id, query: EventQuery(id));
    final all = [
      c('a'),
      c('b'),
      const BreakdownIndicator(
          id: 'large', name: 'large', event: 'e', property: 'p', overTime: true),
      c('d'),
      c('e'),
    ];
    await tester.pumpWidget(_host(
      [
        sharedPrefsProvider.overrideWithValue(prefs),
        indicatorDataProvider.overrideWith((ref, key) => const CounterData([], 5)),
        siteIndicatorsProvider.overrideWith((ref, site) => all),
      ],
      IndicatorsTab(site: _site, window: _window),
    ));
    await tester.pump();

    Rect at(String id) =>
        tester.getRect(find.byKey(ValueKey(id)));
    final full = at('large').width;
    expect(at('a').width, lessThan(full / 1.9));
    expect(at('b').width, closeTo(at('a').width, 0.5));
    expect(at('a').left, lessThan(at('b').left));
    expect(at('a').top, closeTo(at('b').top, 0.5));
    // Large : sur toute la largeur, sous la première rangée, avant la suivante.
    expect(at('large').left, closeTo(at('a').left, 0.5));
    expect(at('large').right, closeTo(at('b').right, 0.5));
    expect(at('large').top, greaterThan(at('a').bottom));
    expect(at('d').top, greaterThan(at('large').bottom));
    expect(at('d').top, closeTo(at('e').top, 0.5));
  });

  testWidgets("onglet sans indicateur : explique ce qu'est un tableau", (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_host(
      [sharedPrefsProvider.overrideWithValue(prefs)],
      IndicatorsTab(site: _site, window: _window),
    ));
    expect(find.text('Aucun tableau'), findsOneWidget);
    expect(find.textContaining('entonnoir'), findsOneWidget);
  });
}
