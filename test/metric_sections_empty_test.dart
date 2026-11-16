import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/models/period.dart';
import 'package:glance/state/internal_traffic.dart';
import 'package:glance/state/providers.dart';
import 'package:glance/theme/theme.dart';
import 'package:glance/ui/detail/metric_sections.dart';
import 'package:glance/ui/widgets/common.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/l10n.dart';

const _site = Site(id: 's', accountId: 'a', name: 'S', domain: 's.fr');
final _window = DateWindow(DateTime(2026, 7, 1), DateTime(2026, 7, 5), TimeUnit.day);

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  testWidgets('téléphone : une section sans données garde toute la largeur',
      (tester) async {
    tester.view.physicalSize = const Size(780, 4000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        siteMetricProvider.overrideWith((ref, key) async => const <MetricRow>[]),
        knownDomainsProvider.overrideWith((ref) => const <String>{}),
      ],
      child: MaterialApp(
        locale: testLocale,
        localizationsDelegates: glanceLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: glanceTheme(Brightness.light),
        home: Scaffold(
          body: SingleChildScrollView(
            child: MetricSectionGrid(site: _site, window: _window, visitors: 0),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Aucune donnée'), findsNWidgets(4));
    final width = tester.getSize(find.byType(MetricSectionGrid)).width;
    for (final card in tester.widgetList(find.byType(GlanceCard))) {
      expect(tester.getSize(find.byWidget(card)).width, width);
    }
    expect(tester.takeException(), isNull);
  });
}
