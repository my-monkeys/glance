import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';
import '../theme/palette.dart';
import 'add/add_source_screen.dart';
import 'desktop/desktop_shell.dart';
import 'detail/detail_screen.dart';
import 'direct/direct_screen.dart';
import 'home/home_screen.dart';
import 'settings/settings_screen.dart';
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
/// sur mobile, en page plein écran poussée sur la pile. Renvoie la valeur que
/// l'écran passe à `Navigator.pop`.
Future<T?> showGlanceModal<T>(BuildContext context, Widget child) {
  final desktop = MediaQuery.of(context).size.width >= kDesktopBreakpoint;
  if (!desktop) {
    return Navigator.of(context)
        .push<T>(MaterialPageRoute(builder: (_) => child));
  }
  final p = context.glance;
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    barrierDismissible: true,
    builder: (_) => Center(
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

  void _go(GlanceTab t) => setState(() => _tab = t);

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
            IndexedStack(
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
