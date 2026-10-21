import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../data/models/indicator_result.dart';
import '../../theme/motion.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import 'labels.dart';

/// Une barre par étape (largeur ∝ part restante), la perte depuis l'étape
/// précédente glissée entre deux. Mêmes barres, mêmes colonnes de chiffres que
/// `MetricBars` ; refaites ici parce que celle-ci ne sait pas intercaler une
/// ligne entre deux entrées.
class FunnelBars extends StatelessWidget {
  const FunnelBars({super.key, required this.steps});
  final List<FunnelStepResult> steps;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Column(
      children: [
        for (final s in steps) ...[
          if (s.dropoff != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '−${fmtPct(s.dropoff! * 100, decimals: 0)}',
                  style: GT.mono(10.5, color: p.fg3),
                ),
              ),
            ),
          _StepRow(step: s),
        ],
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});
  final FunnelStepResult step;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Le résumé des filtres passe à la ligne plutôt que d'être coupé :
              // c'est lui (25 / 50 / 75) qui distingue des étapes du même
              // événement.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.event, style: GT.mono(12, color: p.fg)),
                    if (step.filters.isNotEmpty)
                      Text(filtersSummary(step.filters),
                          style: GT.mono(10.5, color: p.fg3)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _Cell(
                width: 56,
                text: fmtInt(step.visitors),
                style: GT.mono(12, color: p.fg2),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Container(width: 1, height: 11, color: p.line),
              ),
              _Cell(
                width: 44,
                text: fmtPct(step.remaining * 100, decimals: 0),
                style: GT.mono(11, color: p.fg3),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Container(
              height: 6,
              color: p.chip,
              child: AnimatedFractionallySizedBox(
                duration: kMotionBase,
                curve: kCurveOutCubic,
                alignment: Alignment.centerLeft,
                widthFactor: step.remaining.clamp(0.02, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Colonne de largeur fixe (les bords des nombres restent alignés d'une étape
/// à l'autre) ; `scaleDown` plutôt qu'un débordement à grande échelle de texte.
class _Cell extends StatelessWidget {
  const _Cell({required this.width, required this.text, required this.style});
  final double width;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(text, maxLines: 1, softWrap: false, style: style),
        ),
      );
}
