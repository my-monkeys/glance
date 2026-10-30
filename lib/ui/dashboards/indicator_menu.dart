import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/indicator.dart';
import '../../data/models/models.dart';
import '../../state/indicators.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../widgets/toast.dart';
import 'editor/confirm_button.dart';
import 'editor/indicator_editor.dart';
import 'editor/pickers.dart';

enum _Action { edit, delete }

/// Menu « ⋯ » d'une carte : modifier, supprimer (on la déplace dans la
/// grille, bouton « Organiser »). La feuille ne fait
/// que choisir ; l'action s'exécute ici, une fois la feuille fermée, avec le
/// contexte de la carte (celui de la feuille est mort à ce moment-là).
Future<void> showIndicatorMenu(
  BuildContext context,
  WidgetRef ref,
  Site site,
  Indicator indicator,
) async {
  final action = await showGlanceSheet<_Action>(
    context,
    (_) => _MenuSheet(indicator: indicator),
  );
  if (action == null || !context.mounted) return;
  final notifier = ref.read(indicatorsProvider.notifier);
  switch (action) {
    case _Action.edit:
      await openIndicatorEditor(context, site, initial: indicator);
    case _Action.delete:
      await notifier.remove(site, indicator.id);
      if (context.mounted) {
        showGlanceToast(context, 'Tableau supprimé', kind: ToastKind.info);
      }
  }
}

class _MenuSheet extends StatelessWidget {
  const _MenuSheet({required this.indicator});

  final Indicator indicator;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    void pick(_Action a) => Navigator.of(context).pop(a);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              indicator.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GT.display(22, color: p.fg),
            ),
            const SizedBox(height: 8),
            _Item('Modifier', Icons.edit_outlined, () => pick(_Action.edit)),
            const SizedBox(height: 14),
            ConfirmButton(
              label: 'Supprimer',
              confirmLabel: 'Confirmer la suppression',
              onConfirmed: () => pick(_Action.delete),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 19, color: p.fg2),
            const SizedBox(width: 14),
            Text(label, style: GT.body(15.5, color: p.fg)),
          ],
        ),
      ),
    );
  }
}
