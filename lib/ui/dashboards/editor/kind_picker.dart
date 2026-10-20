import 'package:flutter/material.dart';

import '../../../data/models/indicator.dart';
import '../../../theme/motion.dart';
import '../../../theme/palette.dart';
import '../../../theme/type.dart';

const kindNames = {
  IndicatorKind.counter: 'Compteur',
  IndicatorKind.ratio: 'Taux',
  IndicatorKind.funnel: 'Entonnoir',
  IndicatorKind.breakdown: 'Répartition',
};

const _kindHints = {
  IndicatorKind.counter: 'Combien de fois un événement se produit.',
  IndicatorKind.ratio: 'Un événement rapporté à un autre, en %.',
  IndicatorKind.funnel:
      'Combien de visiteurs franchissent chaque étape, dans l\'ordre.',
  IndicatorKind.breakdown:
      'Les valeurs d\'une propriété, des plus fréquentes aux plus rares.',
};

/// Un genre par ligne : un nom et une phrase, comme les réglages de la feuille
/// « Affichage ».
class KindPicker extends StatelessWidget {
  const KindPicker({
    super.key,
    required this.kinds,
    required this.selected,
    required this.onChanged,
  });

  final List<IndicatorKind> kinds;
  final IndicatorKind selected;
  final ValueChanged<IndicatorKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Column(
      children: [
        for (final k in kinds)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => onChanged(k),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: kMotionFast,
                curve: kCurveOut,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  color: k == selected ? p.accentSoft : p.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: k == selected ? p.accent : p.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kindNames[k]!, style: GT.body(15, weight: 600, color: p.fg)),
                    const SizedBox(height: 2),
                    Text(_kindHints[k]!, style: GT.body(12.5, color: p.fg2)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
