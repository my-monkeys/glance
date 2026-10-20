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

enum _Action { edit, up, down, delete }

/// Menu « ⋯ » d'une carte : modifier, déplacer, supprimer. La feuille ne fait
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
    (_) => _MenuSheet(site: site, indicator: indicator),
  );
  if (action == null || !context.mounted) return;
  final notifier = ref.read(indicatorsProvider.notifier);
  final index = ref
      .read(siteIndicatorsProvider(site))
      .indexWhere((i) => i.id == indicator.id);
  switch (action) {
    case _Action.edit:
      await openIndicatorEditor(context, site, initial: indicator);
    case _Action.up:
      await notifier.reorder(site, index, index - 1);
      if (context.mounted) showGlanceToast(context, 'Tableau monté');
    case _Action.down:
      // `reorder` suit la convention d'`onReorder` : l'indice cible est donné
      // avant retrait de l'élément.
      await notifier.reorder(site, index, index + 2);
      if (context.mounted) showGlanceToast(context, 'Tableau descendu');
    case _Action.delete:
      await notifier.remove(site, indicator.id);
      if (context.mounted) {
        showGlanceToast(context, 'Tableau supprimé', kind: ToastKind.info);
      }
  }
}

class _MenuSheet extends ConsumerWidget {
  const _MenuSheet({required this.site, required this.indicator});

  final Site site;
  final Indicator indicator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final all = ref.watch(siteIndicatorsProvider(site));
    final index = all.indexWhere((i) => i.id == indicator.id);
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
            if (index > 0)
              _Item('Monter', Icons.arrow_upward_rounded, () => pick(_Action.up)),
            if (index >= 0 && index < all.length - 1)
              _Item('Descendre', Icons.arrow_downward_rounded,
                  () => pick(_Action.down)),
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
