import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state/settings.dart';
import 'theme/theme.dart';
import 'ui/root_scaffold.dart';

class GlanceApp extends ConsumerWidget {
  const GlanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(settingsProvider.select((s) => s.theme));
    return MaterialApp(
      title: 'Glance',
      debugShowCheckedModeBanner: false,
      theme: glanceTheme(Brightness.light),
      darkTheme: glanceTheme(Brightness.dark),
      themeMode: theme.mode,
      // On atterrit toujours sur l'app : l'ajout d'une source se fait depuis
      // l'état vide de l'accueil (flux fournisseur → sites).
      home: const RootScaffold(),
    );
  }
}
