import 'package:flutter/material.dart';

import '../../../data/models/indicator.dart';
import '../../../data/models/models.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/palette.dart';
import '../../../theme/type.dart';
import '../../widgets/field.dart';
import 'draft.dart';
import 'query_editor.dart';

/// Les étapes d'un entonnoir : numérotées, réordonnables, de 2 à 8, puis le
/// délai maximum entre deux d'entre elles.
class FunnelStepsEditor extends StatelessWidget {
  const FunnelStepsEditor({
    super.key,
    required this.site,
    required this.steps,
    required this.window,
    required this.onSteps,
    required this.onWindow,
  });

  final Site site;
  final List<EventQuery> steps;
  final TextEditingController window;
  final ValueChanged<List<EventQuery>> onSteps;
  final ValueChanged<String> onWindow;

  void _replace(int i, EventQuery q) =>
      onSteps([for (var j = 0; j < steps.length; j++) j == i ? q : steps[j]]);

  void _move(int i, int delta) {
    final next = [...steps];
    next.insert(i + delta, next.removeAt(i));
    onSteps(next);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _StepCard(
            index: i,
            canMoveUp: i > 0,
            canMoveDown: i < steps.length - 1,
            canRemove: steps.length > kFunnelMinSteps,
            onMove: (d) => _move(i, d),
            onRemove: () => onSteps([
              for (var j = 0; j < steps.length; j++)
                if (j != i) steps[j],
            ]),
            child: QueryEditor(
              site: site,
              query: steps[i],
              // Umami ne compare pas les nombres dans un entonnoir.
              allowedOps: kFunnelOps,
              onChanged: (q) => _replace(i, q),
            ),
          ),
        ],
        if (steps.length < kFunnelMaxSteps) ...[
          const SizedBox(height: 12),
          GlanceButtonOutline(
            label: context.l10n.editorFunnelAddStep,
            leading: Icon(Icons.add_rounded, size: 18, color: p.fg),
            onTap: () => onSteps([...steps, const EventQuery('')]),
          ),
        ],
        const SizedBox(height: 20),
        GlanceField(
          label: context.l10n.editorFunnelWindowLabel,
          controller: window,
          mono: true,
          hint: '$kFunnelDefaultWindow',
          keyboardType: TextInputType.number,
          onChanged: onWindow,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 3, top: 7),
          child: Text(
            context.l10n.editorFunnelWindowHint(kFunnelMinWindow, kFunnelMaxWindow),
            style: GT.body(12.5, color: p.fg3),
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.canRemove,
    required this.onMove,
    required this.onRemove,
    required this.child,
  });

  final int index;
  final bool canMoveUp;
  final bool canMoveDown;
  final bool canRemove;
  final ValueChanged<int> onMove;
  final VoidCallback onRemove;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final l10n = context.l10n;
    Widget action(IconData icon, String label, VoidCallback? onTap) => Tooltip(
          message: label,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Icon(icon,
                  size: 18,
                  color: onTap == null ? p.fg3.withValues(alpha: 0.4) : p.fg2,
                  semanticLabel: label),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 14),
      decoration: BoxDecoration(
        color: p.chip,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(l10n.editorFunnelStep(index + 1), style: GT.label(color: p.fg2)),
              const Spacer(),
              action(Icons.arrow_upward_rounded, l10n.editorFunnelMoveUp,
                  canMoveUp ? () => onMove(-1) : null),
              action(Icons.arrow_downward_rounded, l10n.editorFunnelMoveDown,
                  canMoveDown ? () => onMove(1) : null),
              action(Icons.close_rounded, l10n.editorFunnelRemove,
                  canRemove ? onRemove : null),
            ],
          ),
          Padding(padding: const EdgeInsets.only(right: 6), child: child),
        ],
      ),
    );
  }
}
