import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/models/account.dart';
import 'data/models/workspace.dart';
import 'state/period_state.dart';
import 'state/providers.dart';
import 'state/settings.dart';
import 'state/sync.dart';
import 'state/widget_publisher.dart';
import 'state/workspaces.dart';
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
      home: const _SyncBridge(child: _WidgetSync(child: RootScaffold())),
    );
  }
}

/// Relie l'app à la synchronisation cloud : monté au sommet, il garde le
/// contrôleur vivant (→ pull au lancement) et **pousse** la config à chaque
/// changement de comptes/groupes, avec un léger debounce. Le push est ignoré
/// pendant l'application d'un pull (`applying`) pour éviter une boucle.
class _SyncBridge extends ConsumerStatefulWidget {
  const _SyncBridge({required this.child});
  final Widget child;

  @override
  ConsumerState<_SyncBridge> createState() => _SyncBridgeState();
}

class _SyncBridgeState extends ConsumerState<_SyncBridge> {
  Timer? _debounce;

  void _schedulePush() {
    final ctrl = ref.read(syncControllerProvider.notifier);
    final s = ref.read(syncControllerProvider);
    if (s.status != SyncStatus.signedIn || !s.isPro || ctrl.applying) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), ctrl.push);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur actif (déclenche _restore → pull au lancement).
    ref.watch(syncControllerProvider);
    // Un changement de config locale → push (debouncé).
    ref.listen<List<Account>>(accountsProvider, (_, _) => _schedulePush());
    ref.listen<List<Workspace>>(workspacesProvider, (_, _) => _schedulePush());
    return widget.child;
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
