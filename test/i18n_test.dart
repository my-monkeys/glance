import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/format.dart';
import 'package:glance/l10n/app_localizations_en.dart';
import 'package:glance/l10n/app_localizations_fr.dart';
import 'package:glance/state/providers.dart';
import 'package:glance/theme/theme.dart';
import 'package:glance/ui/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/l10n.dart';

Widget _app(Locale? locale, Widget home) => MaterialApp(
  locale: locale,
  localizationsDelegates: glanceLocalizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  localeListResolutionCallback: resolveGlanceLocale,
  theme: glanceTheme(Brightness.light),
  home: home,
);

void main() {
  testWidgets('les réglages se rendent en anglais', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: _app(const Locale('en'), const Scaffold(body: SettingsScreen())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Réglages'), findsNothing);
  });

  test('pluriels ICU : 0, 1 et plusieurs, dans les deux langues', () {
    final en = AppLocalizationsEn();
    final fr = AppLocalizationsFr();
    expect(en.workspaceSiteCount(0), 'No sites');
    expect(en.workspaceSiteCount(1), '1 site');
    expect(en.workspaceSiteCount(3), '3 sites');
    expect(fr.workspaceSiteCount(1), '1 site');
    expect(fr.workspaceSiteCount(3), '3 sites');
  });

  for (final (locale, expected) in [
    (const Locale('en'), 'Oct 13'),
    (const Locale('fr'), '13 oct.'),
  ]) {
    testWidgets('fmtDay suit la langue active : ${locale.languageCode}',
        (tester) async {
      late String out;
      await tester.pumpWidget(_app(
        locale,
        Builder(builder: (context) {
          out = fmtDay(DateTime(2026, 10, 13));
          return const SizedBox();
        }),
      ));
      expect(out, expected);
    });
  }

  testWidgets('langue non prise en charge (it) : repli sur l\'anglais',
      (tester) async {
    late Locale active;
    await tester.pumpWidget(_app(
      const Locale('it'),
      Builder(builder: (context) {
        active = Localizations.localeOf(context);
        return Text(context.l10n.settingsLanguageAuto);
      }),
    ));
    expect(active.languageCode, 'en');
    expect(find.text('Automatic'), findsOneWidget);
  });

  test('résolution : première langue du système prise en charge, sinon en', () {
    const supported = [Locale('fr'), Locale('en')];
    expect(
      resolveGlanceLocale([const Locale('de'), const Locale('fr', 'BE')], supported),
      const Locale('fr'),
    );
    expect(resolveGlanceLocale([const Locale('ja')], supported), const Locale('en'));
    expect(resolveGlanceLocale(null, supported), const Locale('en'));
  });

  test('chaque langue de l\'app a son nom dans sa propre langue', () {
    expect(
      {
        for (final l in AppLocalizations.supportedLocales)
          l.languageCode: nativeLanguageName(l),
      },
      {
        'de': 'Deutsch',
        'en': 'English',
        'es': 'Español',
        'fr': 'Français',
        'pt': 'Português',
        'zh': '中文',
      },
    );
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('réglages sans débordement sur téléphone : $locale',
        (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: _app(locale, const Scaffold(body: SettingsScreen())),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
