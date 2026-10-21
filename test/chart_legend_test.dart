import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/models/period.dart';
import 'package:glance/state/period_state.dart';
import 'package:glance/state/providers.dart';
import 'package:glance/theme/theme.dart';
import 'package:glance/ui/widgets/glance_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _series = [
  for (var i = 0; i < 5; i++) SeriesPoint(DateTime(2026, 10, 1 + i), 10.0 + i, 40.0 + i),
];

Future<ProviderContainer> _pump(WidgetTester tester,
    {bool comparable = true}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      theme: glanceTheme(Brightness.light),
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) => GlanceChart(
            series: _series,
            unit: TimeUnit.day,
            showPageviews: true,
            visitorsTotal: 60,
            pageviewsTotal: 220,
            compareOn: ref.watch(periodProvider.select((s) => s.compare)),
            onToggleCompare: comparable
                ? ref.read(periodProvider.notifier).toggleCompare
                : null,
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  final item = find.text('Période précédente');

  testWidgets('présent et décoché par défaut ; un tap le coche', (tester) async {
    final container = await _pump(tester);
    expect(item, findsOneWidget);
    expect(container.read(periodProvider).compare, isFalse);
    expect(
      tester.widget<AnimatedOpacity>(
          find.ancestor(of: item, matching: find.byType(AnimatedOpacity))).opacity,
      lessThan(1),
    );

    await tester.tap(item);
    await tester.pumpAndSettle();
    expect(container.read(periodProvider).compare, isTrue);
    expect(
      tester.widget<AnimatedOpacity>(
          find.ancestor(of: item, matching: find.byType(AnimatedOpacity))).opacity,
      1,
    );

    await tester.tap(item);
    await tester.pumpAndSettle();
    expect(container.read(periodProvider).compare, isFalse);
  });

  testWidgets('absent quand la fenêtre n\'a pas d\'« avant » comparable',
      (tester) async {
    await _pump(tester, comparable: false);
    expect(item, findsNothing);
  });
}
