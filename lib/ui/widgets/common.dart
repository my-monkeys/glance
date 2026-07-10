import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';

/// Carte surface standard (bordure fine + rayon + ombre douce).
class GlanceCard extends StatelessWidget {
  const GlanceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: padding,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: selected ? p.accent : p.line),
        boxShadow: p.shadow,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

/// Pastille initiale (carré arrondi ou rond).
class Mark extends StatelessWidget {
  const Mark(this.text, {super.key, this.size = 38, this.circle = false});
  final String text;
  final double size;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.chip,
        borderRadius: BorderRadius.circular(circle ? size : 10),
      ),
      child: Text(text, style: GT.mono(size * 0.4, weight: 600, color: p.fg)),
    );
  }
}

/// Fine barre de progression indéterminée, à poser en haut d'un écran pendant
/// un rechargement en fond (la donnée précédente reste affichée).
class RefreshBar extends StatelessWidget {
  const RefreshBar({super.key, this.visible = true});
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: visible ? 1 : 0,
      child: SizedBox(
        height: 2.5,
        child: LinearProgressIndicator(
          minHeight: 2.5,
          backgroundColor: p.accent.withValues(alpha: 0.12),
          color: p.accent,
        ),
      ),
    );
  }
}

/// Bouton icône rond (chip bg + bordure).
class GlanceIconButton extends StatelessWidget {
  const GlanceIconButton({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.chip,
          shape: BoxShape.circle,
          border: Border.all(color: p.line),
        ),
        child: Icon(icon, size: 18, color: p.fg),
      ),
    );
  }
}

/// Label de section : mono, majuscules, très espacé.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GT.label(color: color ?? context.glance.fg2),
    );
  }
}

/// Delta ▲/▼ + valeur, coloré selon le signe.
class DeltaText extends StatelessWidget {
  const DeltaText(this.pct, {super.key, this.fontSize = 12});
  final double? pct;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    if (pct == null) {
      return Text('—', style: GT.mono(fontSize, weight: 600, color: p.fg3));
    }
    final up = pct! >= 0;
    // Au-delà de +400 %, un pourcentage devient illisible (période préc. ≈ 0) :
    // on bascule sur un multiplicateur « ×N ».
    final label = pct! >= 400
        ? '▲ ×${(1 + pct! / 100).round()}'
        : '${up ? '▲' : '▼'} ${fmtPct(pct!.abs())}';
    return Text(
      label,
      style: GT.mono(fontSize, weight: 600, color: up ? p.accent : p.neg),
    );
  }
}

/// Liste « label · valeur + barre » (pages, sources, pays).
class MetricBars extends StatelessWidget {
  const MetricBars({
    super.key,
    required this.rows,
    this.mono = false,
    this.leadingFlag = false,
    this.valueLabel,
  });

  final List<MetricBarRow> rows;
  final bool mono; // libellé en police mono (chemins de pages)
  final bool leadingFlag; // préfixe drapeau (pays)
  final String Function(MetricBarRow row)? valueLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text('Aucune donnée', style: GT.body(13, color: p.fg3)),
      );
    }
    final maxV = rows.map((r) => r.value).fold<int>(1, (a, b) => b > a ? b : a);
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (leadingFlag && r.flag != null) ...[
                      Text(r.flag!, style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        r.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: mono
                            ? GT.mono(12, color: p.fg)
                            : GT.body(13, color: p.fg),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      valueLabel?.call(r) ?? fmtInt(r.value),
                      style: GT.mono(12, color: p.fg2),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _Bar(fraction: (r.value / maxV).clamp(0.02, 1.0)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Interrupteur façon iOS (44×27, pastille coulissante).
class GlanceToggle extends StatelessWidget {
  const GlanceToggle({super.key, required this.value, required this.onTap});
  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 44,
        height: 27,
        decoration: BoxDecoration(
          color: value ? p.accent : p.chip,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: value ? Colors.transparent : p.line),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  width: 21,
                  height: 21,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MetricBarRow {
  const MetricBarRow({
    required this.label,
    required this.value,
    this.flag,
    this.pctText,
  });
  final String label;
  final int value;
  final String? flag;
  final String? pctText;
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction});
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: 6,
        color: p.chip,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: fraction,
          child: Container(
            decoration: BoxDecoration(
              color: p.accent.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }
}
