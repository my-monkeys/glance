import 'package:flutter/material.dart';

import '../../theme/motion.dart';
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

  static const double _hPad = 12;

  static TextStyle _style(bool selected, {Color? color}) =>
      GT.mono(12, weight: selected ? 600 : 400, color: color);

  /// Largeur d'un chip, mesurée avec le style sélectionné (le plus large) : la
  /// barre de périodes s'en sert pour savoir si elle tient sur une ligne.
  static double widthOf(BuildContext context, String label) {
    final tp = TextPainter(
      text: TextSpan(text: label, style: _style(true)),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return tp.width + 2 * _hPad;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: kMotionFast,
        curve: kCurveOut,
        padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? p.accent : p.chip,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: _style(selected, color: selected ? p.accentInk : p.fg2),
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
