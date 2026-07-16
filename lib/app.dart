import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state/period_state.dart';
import 'state/providers.dart';
import 'state/settings.dart';
import 'state/widget_publisher.dart';
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
      home: const _WidgetSync(child: RootScaffold()),
    );
  }
}

/// Publie l'agrégat de l'accueil vers les widgets d'écran d'accueil dès qu'il
/// est chargé (et à chaque refresh). Monté en haut de l'app → toujours actif.
///
/// L'agrégat suit le **groupe actif** : le widget montre donc le périmètre
/// qu'on regarde dans l'app. Le choix étant persisté, il reste stable entre
/// deux lancements. (Un widget configurable par groupe demanderait des App
/// Intents iOS/macOS et une activité de config Android — pas fait.)
class _WidgetSync extends ConsumerWidget {
  const _WidgetSync({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodState = ref.watch(periodProvider);
    final window = periodState.window();
    ref.listen(homeTotalsProvider(window), (prev, next) {
      if (next.data.cards.isNotEmpty && !next.loading) {
        WidgetPublisher.publish(next.data, periodState.period.label);
      }
    });
    return child;
  }
}
