import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'dev/seed.dart';
import 'state/providers.dart';
import 'state/updater.dart';
import 'state/widget_publisher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  await WidgetPublisher.init();
  // Mises à jour desktop (Sparkle) : no-op sur mobile.
  if (Updater.isSupported) await Updater.init();
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
  );
  await maybeSeed(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const GlanceApp(),
    ),
  );
}
