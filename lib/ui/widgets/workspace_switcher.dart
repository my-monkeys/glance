import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/models/workspace.dart';
import '../../state/providers.dart';
import '../../state/workspaces.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../settings/workspaces_screen.dart';

/// Pastille d'un groupe : son icône dans sa couleur. [group] à `null` = « tous
/// les sites », rendu en neutre.
class WorkspaceBadge extends StatelessWidget {
  const WorkspaceBadge({super.key, required this.group, this.size = 38});

  final Workspace? group;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final g = group;
    final tint = g?.color.of(Theme.of(context).brightness);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint == null ? p.chip : tint.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(
        g?.icon.data ?? Icons.donut_large_rounded,
        size: size * 0.5,
        color: tint ?? p.fg2,
      ),
    );
  }
}

/// La pastille de l'en-tête : montre le périmètre courant et ouvre la liste des
/// groupes. Sert de sélecteur pour ne pas ajouter de contrôle à l'écran.
class WorkspaceSwitcher extends ConsumerWidget {
  const WorkspaceSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeWorkspaceProvider);
    return GestureDetector(
      onTap: () => _showSheet(context),
      behavior: HitTestBehavior.opaque,
      child: WorkspaceBadge(group: active),
    );
  }

  void _showSheet(BuildContext context) {
    final p = context.glance;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadius)),
      ),
      builder: (_) => const _WorkspaceSheet(),
    );
  }
}

class _WorkspaceSheet extends ConsumerWidget {
  const _WorkspaceSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final groups = ref.watch(workspacesProvider);
    final active = ref.watch(activeWorkspaceProvider);
    final sites = ref.watch(sitesProvider).value ?? const <Site>[];

    void select(String? id) {
      ref.read(activeWorkspaceIdProvider.notifier).set(id);
      Navigator.of(context).pop();
    }

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: p.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 6),
            child: Text('Périmètre', style: GT.label(color: p.fg2)),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                _SheetRow(
                  group: null,
                  title: 'Tous les sites',
                  subtitle:
                      '${sites.length} site${sites.length > 1 ? 's' : ''} suivi${sites.length > 1 ? 's' : ''}',
                  selected: active == null,
                  onTap: () => select(null),
                ),
                for (final g in groups)
                  _SheetRow(
                    group: g,
                    title: g.name,
                    subtitle: () {
                      final n = sites.where(g.contains).length;
                      return n == 0
                          ? 'Aucun site'
                          : '$n site${n > 1 ? 's' : ''}';
                    }(),
                    selected: active?.id == g.id,
                    onTap: () => select(g.id),
                  ),
              ],
            ),
          ),
          Divider(color: p.line, height: 20),
          _ActionRow(
            icon: Icons.add_rounded,
            label: 'Nouveau groupe',
            onTap: () {
              Navigator.of(context).pop();
              openWorkspaceEditor(context, null);
            },
          ),
          if (groups.isNotEmpty)
            _ActionRow(
              icon: Icons.tune_rounded,
              label: 'Gérer les groupes',
              onTap: () {
                Navigator.of(context).pop();
                openWorkspaces(context);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.group,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final Workspace? group;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(
            children: [
              WorkspaceBadge(group: group, size: 36),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GT.body(15,
                          weight: selected ? 600 : 400, color: p.fg),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: GT.body(12, color: p.fg2)),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 20, color: p.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: p.accent),
              const SizedBox(width: 14),
              Text(label,
                  style: GT.body(15, weight: 500, color: p.accent)),
            ],
          ),
        ),
      ),
    );
  }
}
