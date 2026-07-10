import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';
import 'add/add_source_screen.dart';
import 'detail/detail_screen.dart';
import 'direct/direct_screen.dart';
import 'home/home_screen.dart';
import 'settings/settings_screen.dart';
import 'widgets/tab_bar.dart';

/// Pousse l'écran de détail d'un site.
void openSite(BuildContext context, Site site) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => DetailScreen(site: site)),
  );
}

/// Pousse l'écran d'ajout de source.
void openAddSource(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const AddSourceScreen()),
  );
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
