import 'package:flutter/material.dart';

import '../../../data/models/indicator.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/motion.dart';
import '../../../theme/palette.dart';
import '../../../theme/type.dart';

String _kindName(AppLocalizations l10n, IndicatorKind k) => switch (k) {
      IndicatorKind.counter => l10n.dashboardsKindCounter,
      IndicatorKind.ratio => l10n.dashboardsKindRatio,
      IndicatorKind.funnel => l10n.dashboardsKindFunnel,
      IndicatorKind.breakdown => l10n.dashboardsKindBreakdown,
      IndicatorKind.external => l10n.editorKindExternal,
      IndicatorKind.sites => l10n.dashboardsKindSites,
    };

String _kindHint(AppLocalizations l10n, IndicatorKind k) => switch (k) {
      IndicatorKind.counter => l10n.editorKindHintCounter,
      IndicatorKind.ratio => l10n.editorKindHintRatio,
      IndicatorKind.funnel => l10n.editorKindHintFunnel,
      IndicatorKind.breakdown => l10n.editorKindHintBreakdown,
      IndicatorKind.external => l10n.editorKindHintExternal,
      IndicatorKind.sites => l10n.editorKindHintSites,
    };

/// Les genres en grille de deux colonnes : empilés, ils remplissaient l'écran
/// et repoussaient le formulaire sous la ligne de flottaison. Toujours deux
/// colonnes, même étroit : on raccourcit les phrases plutôt que d'empiler.
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

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < kinds.length; i += 2)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : _gap),
            // Hauteur commune : deux tuiles d'une rangée restent alignées
            // même si l'une des phrases passe sur une ligne.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _tile(context, kinds[i])),
                  const SizedBox(width: _gap),
                  Expanded(
                    child: i + 1 < kinds.length
                        ? _tile(context, kinds[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _tile(BuildContext context, IndicatorKind k) {
    final p = context.glance;
    final on = k == selected;
    final l10n = context.l10n;
    return GestureDetector(
      onTap: () => onChanged(k),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: kMotionFast,
        curve: kCurveOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: on ? p.accentSoft : p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: on ? p.accent : p.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_kindName(l10n, k), style: GT.body(14, weight: 600, color: p.fg)),
            const SizedBox(height: 2),
            Text(
              _kindHint(l10n, k),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GT.body(11.5, color: p.fg2),
            ),
          ],
        ),
      ),
    );
  }
}
