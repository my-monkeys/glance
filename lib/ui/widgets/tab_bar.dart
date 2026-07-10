import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/palette.dart';
import '../../theme/type.dart';

enum GlanceTab { sites, direct, settings }

class GlanceTabBar extends StatelessWidget {
  const GlanceTabBar({super.key, required this.current, required this.onSelect});

  final GlanceTab current;
  final ValueChanged<GlanceTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
            decoration: BoxDecoration(
              color: p.surface.withValues(alpha: isDark ? 0.62 : 0.72),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: p.line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.09),
                  blurRadius: 26,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
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

  Widget _item(BuildContext context, GlanceTab tab, IconData icon, String label) {
    final p = context.glance;
    final on = tab == current;
    final color = on ? p.accent : p.fg2;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(tab),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(label, style: GT.body(11, weight: 500, color: color)),
          ],
        ),
      ),
    );
  }
}
