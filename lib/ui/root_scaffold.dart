import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import 'add/add_source_screen.dart';
import 'desktop/desktop_shell.dart';
import 'detail/detail_screen.dart';
import 'direct/direct_screen.dart';
import 'home/home_screen.dart';
import 'settings/settings_screen.dart';
import 'widgets/motion.dart';
import 'widgets/tab_bar.dart';

/// Ouvre un site. Sur desktop (master-détail), sélectionne le site dans le
/// panneau central via [DesktopShellScope] ; sur mobile, pousse une page détail.
void openSite(BuildContext context, Site site) {
  final scope = DesktopShellScope.maybeOf(context);
  if (scope != null) {
    scope.onOpenSite(site);
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => DetailScreen(site: site)),
  );
}

/// Présente un écran de flux (ajout de source, choix des sites…) : sur desktop,
/// en **modale centrée** (taille type téléphone) avec un backdrop assombri ;
/// sur mobile, en page plein écran poussée sur la pile — présentation modale
/// (slide-up iOS) par défaut, `fullscreenDialog: false` pour l'étape suivante
/// d'un flux déjà ouvert (slide horizontal de continuation). Renvoie la valeur
/// que l'écran passe à `Navigator.pop`.
Future<T?> showGlanceModal<T>(
  BuildContext context,
  Widget child, {
  bool fullscreenDialog = true,
}) {
  final desktop = MediaQuery.of(context).size.width >= kDesktopBreakpoint;
  if (!desktop) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(fullscreenDialog: fullscreenDialog, builder: (_) => child),
    );
  }
  final p = context.glance;
  // Modale-dans-modale (éditeur de groupe → ajout de source…) : le premier
  // barrier assombrit déjà, on n'empile pas un second plein.
  final nested = ModalRoute.of(context) is RawDialogRoute;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer',
    barrierColor: Colors.black.withValues(alpha: nested ? 0.15 : 0.62),
    transitionDuration: kMotionSlow,
    transitionBuilder: (_, anim, _, child) {
      final t = CurvedAnimation(parent: anim, curve: kCurveOutCubic);
      return FadeTransition(
        opacity: t,
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(t),
          child: child,
        ),
      );
    },
    pageBuilder: (_, _, _) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 680),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Material(
            color: p.bg,
            child: SizedBox(width: 420, height: 680, child: child),
          ),
        ),
      ),
    ),
  );
}

/// Ouvre l'écran d'ajout de source (modale sur desktop, page sur mobile).
void openAddSource(BuildContext context) {
  showGlanceModal<void>(context, const AddSourceScreen());
}

class RootScaffold extends ConsumerStatefulWidget {
  const RootScaffold({super.key});

  @override
  ConsumerState<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends ConsumerState<RootScaffold> {
  GlanceTab _tab = GlanceTab.sites;

  void _go(GlanceTab t) {
    if (t != _tab) HapticFeedback.selectionClick();
    setState(() => _tab = t);
  }

  @override
  Widget build(BuildContext context) {
    // Grand écran (desktop / fenêtre large) → shell master-détail.
    if (MediaQuery.of(context).size.width >= kDesktopBreakpoint) {
      return const DesktopShell();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            GlanceFadeIndexedStack(
              index: _tab.index,
              children: [
                HomeScreen(onGoSettings: () => _go(GlanceTab.settings)),
                const DirectScreen(),
                const SettingsScreen(),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomInset + 8,
              child: GlanceTabBar(current: _tab, onSelect: _go),
            ),
          ],
        ),
      ),
    );
  }
}
