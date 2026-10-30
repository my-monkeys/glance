import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/account.dart';
import 'package:glance/data/models/indicator.dart';
import 'package:glance/data/models/indicator_result.dart';
import 'package:glance/data/models/metrics_source.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/models/period.dart';
import 'package:glance/state/indicators.dart';
import 'package:glance/state/period_state.dart';
import 'package:glance/state/providers.dart';
import 'package:glance/theme/theme.dart';
import 'package:glance/ui/dashboards/indicators_tab.dart';
import 'package:glance/ui/widgets/events_chart.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _site = Site(id: 's', accountId: 'a', name: 'S', domain: 's.fr');
final _window =
    DateWindow(DateTime(2026, 10, 28), DateTime(2026, 10, 31), TimeUnit.day);
final _days = [for (var d = 28; d < 31; d++) DateTime(2026, 10, d)];

class _Accounts extends AccountsNotifier {
  @override
  List<Account> build() =>
      const [Account(id: 'a', kind: ProviderKind.umami, baseUrl: 'https://u.fr')];
}

/// Joueurs actifs : découpés à partir du 30 octobre seulement.
CounterData _data({required bool split}) => CounterData(
      [for (final (i, t) in _days.indexed) SeriesPoint(t, [122.0, 98.0, 40.0][i], 0)],
      260,
      segments: [
        CounterSegment(
          label: 'Site',
          values: [null, null, split ? 25 : 0],
          periodTotal: split ? 25 : 0,
        ),
        CounterSegment(
          label: 'Appli',
          values: [null, null, split ? 10 : 0],
          periodTotal: split ? 10 : 0,
        ),
        CounterSegment(
          label: 'Alldle',
          estimated: true,
          values: [null, null, split ? 5 : 0],
          periodTotal: split ? 5 : 0,
        ),
      ],
    );

Future<void> _pump(WidgetTester tester, CounterData data) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      accountsProvider.overrideWith(_Accounts.new),
      windowProvider.overrideWithValue(_window),
      indicatorDataProvider.overrideWith((ref, key) async => data),
    ],
    child: MaterialApp(
      theme: glanceTheme(Brightness.light),
      home: Scaffold(
        body: SingleChildScrollView(
          child: IndicatorsTab(site: _site, window: _window),
        ),
      ),
    ),
  ));
  final c = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await c.read(indicatorsProvider.notifier).add(
        _site,
        ExternalIndicator(
          id: 'j',
          name: 'Joueurs actifs',
          metricId: 'joueurs_actifs',
          label: 'Joueurs actifs',
          unit: MetricUnit.count,
        ),
      );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  testWidgets('une courbe par plateforme et leurs parts sur la période',
      (tester) async {
    await _pump(tester, _data(split: true));

    expect(find.byType(EventsChart), findsOneWidget);
    for (final label in ['Total', 'Site', 'Appli', 'Alldle · estimé']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    // Parts sur la somme des totaux de période : 25 / 40 = 62,5 %.
    expect(find.textContaining(RegExp(r'^63\s%$')), findsOneWidget);
  });

  testWidgets('Total masqué : un jour connu reste visible en pastille',
      (tester) async {
    await _pump(tester, _data(split: true));
    await tester.tap(find.text('Total'));
    await tester.pumpAndSettle();

    final bars = tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData;
    expect(bars, hasLength(3)); // Site, Appli, Alldle
    for (final bar in bars) {
      final shown = [
        for (final spot in bar.spots)
          if (!spot.isNull() && bar.dotData.checkToShowDot(spot, bar)) spot.x,
      ];
      expect(shown, [2.0]);
    }
  });

  testWidgets('une plateforme sans total n\'a pas de barre à 0 %', (tester) async {
    final d = _data(split: true);
    await _pump(
      tester,
      CounterData(d.points, d.total, segments: [
        d.segments[0],
        d.segments[1],
        const CounterSegment(label: 'Alldle', estimated: true, values: [null, null, null]),
      ]),
    );
    expect(find.textContaining(RegExp(r'^0\s%$')), findsNothing);
    expect(find.textContaining(RegExp(r'^71\s%$')), findsOneWidget); // 25 / 35
  });

  test('isolatedPoint : connu, sans voisin connu', () {
    final s = EventSeries(
      name: 'x',
      points: [for (var i = 0; i < 5; i++) SeriesPoint(DateTime(2026, 10, i + 1), 1, 0)],
      total: 5,
      gaps: {1, 3},
    );
    expect([for (var i = 0; i < 5; i++) isolatedPoint(s, i)],
        [true, false, true, false, true]);
  });

  testWidgets('tant qu\'aucune plateforme n\'est connue, compteur simple',
      (tester) async {
    await _pump(tester, _data(split: false));

    expect(find.byType(EventsChart), findsNothing);
    expect(find.text('Site'), findsNothing);
  });
}
