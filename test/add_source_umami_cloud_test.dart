import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/l10n/app_localizations_fr.dart';
import 'package:glance/theme/theme.dart';
import 'package:glance/ui/add/add_source_screen.dart';

import 'helpers/l10n.dart';

final _fr = AppLocalizationsFr();

Future<void> _open(WidgetTester tester) => tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        locale: testLocale,
        localizationsDelegates: glanceLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: glanceTheme(Brightness.light),
        home: const AddSourceScreen(),
      ),
    ));

void main() {
  testWidgets('« Umami Cloud » ne demande que la clé API', (tester) async {
    await _open(tester);
    expect(find.text(_fr.credInstanceUrl.toUpperCase()), findsOneWidget);

    await tester.tap(find.text('Umami Cloud'));
    await tester.pumpAndSettle();

    expect(find.text(_fr.credApiKey.toUpperCase()), findsOneWidget);
    expect(find.text(_fr.credUmamiCloudKeyHint), findsOneWidget);
    expect(find.text(_fr.credInstanceUrl.toUpperCase()), findsNothing);
    expect(find.text(_fr.credUsername.toUpperCase()), findsNothing);

    await tester.tap(find.text(_fr.addSourceUmamiSelfHosted));
    await tester.pumpAndSettle();
    expect(find.text(_fr.credInstanceUrl.toUpperCase()), findsOneWidget);
  });

  testWidgets('une adresse d’Umami Cloud en auto-hébergé renvoie vers le choix '
      'Cloud', (tester) async {
    // La liste ne construit pas les champs hors de l'écran (800 × 600).
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _open(tester);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'cloud.umami.is');
    await tester.enterText(fields.at(2), 'moi');
    await tester.enterText(fields.at(3), 'secret');

    await tester.tap(find.text(_fr.addSourceTest));
    await tester.pumpAndSettle();

    expect(find.text(_fr.addSourceUmamiCloudUseKey), findsOneWidget);
  });
}
