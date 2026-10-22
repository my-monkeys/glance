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

  testWidgets('la comparaison ne touche plus au bouton ni à la barre',
      (tester) async {
    final container = await _pump(tester, _wide);
    final before = tester.getSize(find.byType(PeriodControls)).height;
    container.read(periodProvider.notifier).toggleCompare();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.compare_arrows_rounded), findsNothing);
    expect(find.text('vs période précédente'), findsNothing);
    expect(tester.getSize(find.byType(PeriodControls)).height, before);
  });

  testWidgets('téléphone : le bouton reste sur une seconde ligne', (tester) async {
    await _pump(tester, 375);
    expect(_dy(tester, button), greaterThan(_dy(tester, periods)));
  });

  testWidgets('« Affichage » ouvre un menu déroulant, qui reste ouvert au réglage',
      (tester) async {
    final container = await _pump(tester, _wide);
    expect(find.text('GRAPHIQUE'), findsNothing);

    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('GRAPHIQUE'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    // Ancré sous le bouton, pas en bas de l'écran.
    expect(_dy(tester, find.text('GRAPHIQUE')), greaterThan(_dy(tester, button)));
    expect(tester.getTopLeft(find.text('GRAPHIQUE')).dy, lessThan(300));

    final other = ChartStyle.values
        .firstWhere((s) => s != container.read(settingsProvider).chartStyle);
    await tester.tap(find.text(other.label));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).chartStyle, other);
    expect(find.text('GRAPHIQUE'), findsOneWidget);

    await tester.tapAt(const Offset(10, 590));
    await tester.pumpAndSettle();
    expect(find.text('GRAPHIQUE'), findsNothing);
  });

  testWidgets('le découpage n\'apparaît que s\'il y a un choix', (tester) async {
    final container = await _pump(tester, _wide);
    container.read(periodProvider.notifier).set(Period.d30);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('DÉCOUPAGE'), findsOneWidget);
    // Une seule rangée par réglage : les puces ne passent pas à la ligne.
    expect(_dy(tester, find.text('Courbe')), _dy(tester, find.text('Barres')));
  });
}
