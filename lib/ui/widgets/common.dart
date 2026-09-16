import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../data/models/dimension.dart';
import '../../theme/motion.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import 'metric_icon.dart';

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
      duration: kMotionFast,
      curve: kCurveOut,
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
      duration: kMotionBase,
      curve: kCurveOut,
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

/// Hauteur d'une ligne de métrique (libellé + barre + marges). Sert à réserver
/// la place des lignes manquantes pour que des cartes côte à côte gardent la
/// même hauteur quand on change de sous-dimension.
const double kMetricRowHeight = 46;

/// Liste « libellé · valeur + barre » (pages, sources, pays…).
class MetricBars extends StatelessWidget {
  const MetricBars({
    super.key,
    required this.rows,
    this.mono = false,
    this.total,
    this.accountId,
    this.reserveRows = 0,
    this.valueLabel,
  });

  final List<MetricBarRow> rows;

  /// Libellé en police à chasse fixe (chemins, requêtes, résolutions).
  final bool mono;

  /// Univers auquel rapporter chaque valeur pour afficher un pourcentage.
  /// Null = une seule colonne, comme avant.
  ///
  /// C'est un total du résumé (visiteurs), jamais la somme des lignes reçues :
  /// celle-ci dépend du nombre de lignes demandées, si bien qu'afficher une
  /// ligne de plus changerait tous les pourcentages déjà lus.
  final int? total;

  /// Compte auquel appartiennent ces lignes — nécessaire dès qu'une ligne porte
  /// une icône, dont la source dépend de l'instance.
  final String? accountId;

  /// Complète avec du vide jusqu'à ce nombre de lignes (hauteur stable).
  final int reserveRows;

  final String Function(MetricBarRow row)? valueLabel;

  /// Largeur du plus large des textes, mesurée sur les chaînes réellement
  /// rendues : les nombres français sont groupés par une espace fine insécable
  /// dont l'avance ne se déduit pas du nombre de caractères.
  static double _widest(Iterable<String> texts, TextStyle style) {
    final painter = TextPainter(textDirection: TextDirection.ltr);
    var w = 0.0;
    for (final t in texts) {
      painter.text = TextSpan(text: t, style: style);
      painter.layout();
      w = math.max(w, painter.width);
    }
    painter.dispose();
    // Arrondi au pixel supérieur : une largeur au demi-pixel près ferait
    // retourner à la ligne le texte qu'on vient justement de mesurer.
    return w.ceilToDouble() + 1;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    if (rows.isEmpty) {
      return SizedBox(
        // Quelques lignes seulement : réserver la hauteur pleine laisserait
        // 300 px de blanc sous un « Aucune donnée ».
        height: reserveRows > 0 ? math.min(reserveRows, 3) * kMetricRowHeight : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text('Aucune donnée', style: GT.body(13, color: p.fg3)),
        ),
      );
    }
    final maxV = rows.map((r) => r.value).fold<int>(1, (a, b) => b > a ? b : a);

    final numStyle = GT.mono(12, color: p.fg2);
    final pctStyle = GT.mono(11, color: p.fg3);
    final values = [
      for (final r in rows) valueLabel?.call(r) ?? fmtInt(r.value),
    ];
    // Au-delà de 100 %, c'est un artefact de comptage (un visiteur peut
    // apparaître dans plusieurs valeurs d'une même dimension) : on borne
    // plutôt que d'afficher « 134 % ».
    final pcts = total == null || total == 0
        ? const <String>[]
        : [
            for (final r in rows)
              fmtPct((r.value / total! * 100).clamp(0, 100), decimals: 0),
          ];
    final numWidth = _widest(values, numStyle);
    final pctWidth = pcts.isEmpty ? 0.0 : _widest(pcts, pctStyle);

    final missing = reserveRows - rows.length;
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (rows[i].icon != MetricIconKind.none) ...[
                      MetricIcon(
                        kind: rows[i].icon,
                        code: rows[i].code,
                        accountId: accountId ?? '',
                      ),
                      const SizedBox(width: 9),
                    ],
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              rows[i].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: mono
                                  ? GT.mono(12, color: p.fg)
                                  : GT.body(13, color: p.fg),
                            ),
                          ),
                          if (rows[i].badge != null) ...[
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: p.accentSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                rows[i].badge!,
                                style: GT.mono(
                                  8.5,
                                  weight: 600,
                                  color: p.accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Colonnes de largeur fixe : sans ça les bords gauches des
                    // nombres partent en dents de scie d'une ligne à l'autre.
                    SizedBox(
                      width: numWidth,
                      child: Text(
                        values[i],
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        softWrap: false,
                        style: numStyle,
                      ),
                    ),
                    if (pctWidth > 0) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: Container(width: 1, height: 11, color: p.line),
                      ),
                      SizedBox(
                        width: pctWidth,
                        child: Text(
                          pcts[i],
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          softWrap: false,
                          style: pctStyle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                _Bar(
                  fraction: (rows[i].value / maxV).clamp(0.02, 1.0),
                  color: rows[i].color,
                ),
              ],
            ),
          ),
        if (missing > 0) SizedBox(height: missing * kMetricRowHeight),
      ],
    );
  }
}

/// Coche ronde de sélection (cercle accent quand cochée).
class GlanceCheck extends StatelessWidget {
  const GlanceCheck({super.key, required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return AnimatedContainer(
      duration: kMotionFast,
      curve: kCurveOut,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: on ? p.accent : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: on ? p.accent : p.fg3, width: 2),
      ),
      child:
          on ? Icon(Icons.check_rounded, size: 15, color: p.accentInk) : null,
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
        duration: kMotionBase,
        curve: kCurveOut,
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
              duration: kMotionBase,
              curve: kCurveOut,
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
    this.color,
    this.badge,
    this.icon = MetricIconKind.none,
    this.code,
  });
  final String label;
  final int value;
  final Color? color; // couleur de barre (ex. par événement)
  final String? badge; // pastille après le libellé (ex. « INTERNE »)

  /// Famille d'icône à poser devant le libellé.
  final MetricIconKind icon;

  /// Valeur brute du fournisseur, dont dérive l'icône (domaine, slug de
  /// navigateur, code pays). Le libellé, lui, est mis en forme pour la lecture.
  final String? code;
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, this.color});
  final double fraction;
  final Color? color;

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
              color: (color ?? p.accent).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }
}
