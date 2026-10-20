import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/period.dart';
import 'package:glance/state/period_state.dart';
import 'package:glance/state/providers.dart';
import 'package:glance/state/settings.dart';
import 'package:glance/theme/theme.dart';
import 'package:glance/ui/widgets/period_controls.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(WidgetTester tester, double width,
    {bool withToggle = false}) async {
  tester.view.physicalSize = Size(width, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      theme: glanceTheme(Brightness.light),
      home: Scaffold(
        body: PeriodControls(
          onPickCustom: () {},
          viewMode: withToggle ? HomeViewMode.list : null,
          onViewMode: withToggle ? (_) {} : null,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

// Les tests rendent en Ahem (glyphes carrés de 12 px) : les périodes y mesurent
// ~980 px, contre ~450 avec JetBrains Mono. D'où une « grande » largeur plus
// grande que celle d'un vrai bureau.
const _wide = 1500.0;

double _dy(WidgetTester tester, Finder f) => tester.getCenter(f).dy;

void main() {
  final periods = find.text(Period.d7.label);
  final button = find.text('Affichage');

  testWidgets('large : périodes et bouton partagent la même ligne', (tester) async {
    await _pump(tester, _wide);
    expect(_dy(tester, button), _dy(tester, periods));
    expect(tester.getTopLeft(button).dx, greaterThan(tester.getTopLeft(periods).dx));
  });

  testWidgets('large avec bascule liste/grille : une seule ligne aussi',
      (tester) async {
    await _pump(tester, _wide, withToggle: true);
    expect(_dy(tester, button), _dy(tester, periods));
    expect(_dy(tester, find.byIcon(Icons.view_agenda_outlined)),
        _dy(tester, periods));
  });

  testWidgets('large : la comparaison s\'annonce dans le bouton, sans nouvelle ligne',
      (tester) async {
    final container = await _pump(tester, _wide);
    final before = tester.getSize(find.byType(PeriodControls)).height;
    container.read(periodProvider.notifier).toggleCompare();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.compare_arrows_rounded), findsOneWidget);
    expect(find.byTooltip('Comparé à la période précédente'), findsOneWidget);
    expect(tester.getSize(find.byType(PeriodControls)).height, before);
    expect(_dy(tester, button), _dy(tester, periods));
  });

  testWidgets('téléphone : le bouton reste sur une seconde ligne', (tester) async {
    await _pump(tester, 375);
    expect(_dy(tester, button), greaterThan(_dy(tester, periods)));
  });
}
