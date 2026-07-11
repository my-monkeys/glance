import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/palette.dart';
import '../../theme/type.dart';

enum GlanceTab { sites, direct, settings }

/// Barre d'onglets flottante et compacte, esprit iOS récent : pilule ajustée au
/// contenu (pas pleine largeur), l'onglet actif s'étend avec un fond d'accent
/// et révèle son libellé.
class GlanceTabBar extends StatelessWidget {
  const GlanceTabBar({super.key, required this.current, required this.onSelect});

  final GlanceTab current;
  final ValueChanged<GlanceTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: p.surface.withValues(alpha: isDark ? 0.58 : 0.72),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: p.line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _item(context, GlanceTab.sites, Icons.grid_view_rounded, 'Sites'),
                _item(context, GlanceTab.direct, Icons.show_chart_rounded, 'Direct'),
                _item(context, GlanceTab.settings, Icons.tune_rounded, 'Réglages'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    GlanceTab tab,
    IconData icon,
    String label,
  ) {
    final p = context.glance;
    final on = tab == current;
    final color = on ? p.accent : p.fg2;
    return GestureDetector(
      onTap: () => onSelect(tab),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: on ? 14 : 13, vertical: 9),
        decoration: BoxDecoration(
          color: on ? p.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 21, color: color),
            // Libellé révélé uniquement pour l'onglet actif (compacité).
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: on
                  ? Padding(
                      padding: const EdgeInsets.only(left: 7),
                      child: Text(
                        label,
                        style: GT.body(12.5, weight: 600, color: color),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
