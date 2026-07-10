import 'package:flutter/material.dart';

import '../../theme/palette.dart';
import '../../theme/type.dart';

/// Chip mono, état on = accent plein (segments périodes / providers / thème).
class GlanceChip extends StatelessWidget {
  const GlanceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? p.accent : p.chip,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: GT.mono(
            12,
            weight: selected ? 600 : 400,
            color: selected ? p.accentInk : p.fg2,
          ),
        ),
      ),
    );
  }
}

/// Rangée de chips scrollable horizontalement (masque la scrollbar).
class ChipRow extends StatelessWidget {
  const ChipRow({super.key, required this.children, this.center = false});
  final List<Widget> children;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment:
            center ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            children[i],
          ],
        ],
      ),
    );
  }
}
