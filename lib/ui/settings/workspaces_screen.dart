import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/models/workspace.dart';
import '../../state/providers.dart';
import '../../state/workspaces.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../add/add_source_screen.dart';
import '../root_scaffold.dart';
import '../widgets/chip.dart';
import '../widgets/common.dart';
import '../widgets/field.dart';
import '../widgets/site_avatar.dart';
import '../widgets/workspace_switcher.dart';

/// Ouvre l'éditeur d'un groupe (modale sur desktop, page sur mobile).
/// [group] à `null` = création.
Future<void> openWorkspaceEditor(BuildContext context, Workspace? group) =>
    showGlanceModal<void>(context, WorkspaceEditScreen(group: group));

/// Ouvre la liste des groupes.
Future<void> openWorkspaces(BuildContext context) =>
    showGlanceModal<void>(context, const WorkspacesScreen());

/// Liste des groupes : créer, renommer, remplir, supprimer.
class WorkspacesScreen extends ConsumerWidget {
  const WorkspacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final groups = ref.watch(workspacesProvider);
    final sites = ref.watch(sitesProvider).value ?? const <Site>[];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  GlanceIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Groupes', style: GT.display(26, color: p.fg)),
                        const SizedBox(height: 2),
                        Text(
                          'Un périmètre de lecture : totaux et courbe ne comptent que ses sites.',
                          style: GT.body(13, color: p.fg2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: groups.isEmpty
                  ? _NoGroups(onCreate: () => openWorkspaceEditor(context, null))
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      children: [
                        for (final g in groups) ...[
                          _GroupCard(
                            group: g,
                            // Un groupe ne montre que les sites encore connus :
                            // une référence orpheline ne se compte pas.
                            count: sites.where(g.contains).length,
                            onTap: () => openWorkspaceEditor(context, g),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
            ),
            // L'état vide porte déjà son propre CTA — pas deux boutons pour
            // la même action.
            if (groups.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  MediaQuery.of(context).padding.bottom + 12,
                ),
                child: GlanceButton(
                  label: 'Nouveau groupe',
                  onTap: () => openWorkspaceEditor(context, null),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.count,
    required this.onTap,
  });
  final Workspace group;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GlanceCard(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          WorkspaceBadge(group: group, size: 34),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GT.body(15, weight: 500, color: p.fg),
                ),
                const SizedBox(height: 2),
                Text(
                  count == 0 ? 'Aucun site' : '$count site${count > 1 ? 's' : ''}',
                  style: GT.body(12, color: p.fg2),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 20, color: p.fg3),
        ],
      ),
    );
  }
}

class _NoGroups extends StatelessWidget {
  const _NoGroups({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_rounded, size: 34, color: p.fg3),
            const SizedBox(height: 14),
            Text('Aucun groupe', style: GT.display(22, color: p.fg)),
            const SizedBox(height: 8),
            Text(
              'Regroupez vos sites — par exemple « Jeux » ou « Clients » — pour '
              'lire leurs statistiques à part, sans le reste.',
              textAlign: TextAlign.center,
              style: GT.body(14, color: p.fg2),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onCreate,
              child: Text(
                'Créer un groupe',
                style: GT.body(15, weight: 600, color: p.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Création / édition d'un groupe : nom + sites, tous comptes confondus.
class WorkspaceEditScreen extends ConsumerStatefulWidget {
  const WorkspaceEditScreen({super.key, this.group});
  final Workspace? group;

  @override
  ConsumerState<WorkspaceEditScreen> createState() =>
      _WorkspaceEditScreenState();
}

class _WorkspaceEditScreenState extends ConsumerState<WorkspaceEditScreen> {
  late final TextEditingController _name;
  late final Set<SiteRef> _selected;
  late WorkspaceIcon _icon;
  late WorkspaceColor _color;

  bool get _isNew => widget.group == null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.group?.name ?? '')
      // Le bouton d'enregistrement s'active dès qu'un nom est saisi.
      ..addListener(() => setState(() {}));
    _selected = {...?widget.group?.sites};
    _icon = widget.group?.icon ?? WorkspaceIcon.dossier;
    // Nouveau groupe : couleur suivante du nuancier → deux groupes ne se
    // ressemblent pas sans que l'utilisateur ait à choisir.
    _color = widget.group?.color ??
        WorkspaceColor.values[ref.read(workspacesProvider).length %
            WorkspaceColor.values.length];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _toggle(Site s) {
    final ref_ = SiteRef.of(s);
    setState(() {
      if (!_selected.remove(ref_)) _selected.add(ref_);
    });
  }

  /// Ajouter une source sans quitter le groupe : les sites qu'elle apporte
  /// entrent directement dedans — c'est le sens de « créer une source depuis
  /// le groupe ».
  Future<void> _addSource() async {
    final before = (ref.read(sitesProvider).value ?? const <Site>[])
        .map(SiteRef.of)
        .toSet();
    await showGlanceModal<void>(context, const AddSourceScreen());
    if (!mounted) return;
    final after = await ref.read(sitesProvider.future);
    if (!mounted) return;
    setState(() {
      for (final s in after) {
        final r = SiteRef.of(s);
        if (!before.contains(r)) _selected.add(r);
      }
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final notifier = ref.read(workspacesProvider.notifier);
    if (_isNew) {
      final created = await notifier.create(
        name,
        _selected.toList(),
        icon: _icon,
        color: _color,
      );
      // Créer un groupe, c'est vouloir le regarder → on l'active.
      ref.read(activeWorkspaceIdProvider.notifier).set(created.id);
    } else {
      await notifier.update(
        widget.group!.copyWith(
          name: name,
          sites: _selected.toList(),
          icon: _icon,
          color: _color,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce groupe ?'),
        content: const Text(
          'Les sites et leurs statistiques ne sont pas touchés — seul le '
          'regroupement disparaît.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(workspacesProvider.notifier).remove(widget.group!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final sitesAsync = ref.watch(sitesProvider);
    final sites = sitesAsync.value ?? const <Site>[];
    final accounts = ref.watch(accountsProvider);
    final multiAccount = accounts.length > 1;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  GlanceIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isNew ? 'Nouveau groupe' : 'Modifier le groupe',
                      style: GT.display(24, color: p.fg),
                    ),
                  ),
                  if (!_isNew)
                    GlanceIconButton(
                      icon: Icons.delete_outline_rounded,
                      onTap: _delete,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: WorkspaceBadge(
                          group: Workspace(
                            id: '',
                            name: '',
                            icon: _icon,
                            color: _color,
                          ),
                          size: 48,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: GlanceField(
                          label: 'Nom',
                          controller: _name,
                          hint: 'Jeux, Clients, Perso…',
                          autofocus: _isNew,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ChipRow(
                    children: [
                      for (final c in WorkspaceColor.values)
                        _Swatch(
                          color: c,
                          on: _color == c,
                          onTap: () => setState(() => _color = c),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ChipRow(
                    children: [
                      for (final i in WorkspaceIcon.values)
                        _IconChoice(
                          icon: i,
                          color: _color,
                          on: _icon == i,
                          onTap: () => setState(() => _icon = i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.only(left: 3, bottom: 8),
                    child: SectionLabel('Sites du groupe'),
                  ),
                  _AddSourceRow(onTap: _addSource),
                  const SizedBox(height: 10),
                  if (sites.isEmpty && sitesAsync.isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: p.accent,
                          strokeWidth: 2.4,
                        ),
                      ),
                    )
                  else if (sites.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Aucun site suivi pour l\'instant — ajoutez une source '
                        'ci-dessus pour remplir ce groupe.',
                        textAlign: TextAlign.center,
                        style: GT.body(14, color: p.fg3),
                      ),
                    )
                  else
                    for (final s in sites) ...[
                      _SiteRow(
                        site: s,
                        // L'origine n'est utile à distinguer que si plusieurs
                        // comptes coexistent.
                        accountLabel: multiAccount
                            ? accounts
                                .firstWhere((a) => a.id == s.accountId)
                                .title
                            : null,
                        on: _selected.contains(SiteRef.of(s)),
                        onTap: () => _toggle(s),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              child: GlanceButton(
                label: _isNew ? 'Créer le groupe' : 'Enregistrer',
                // Un groupe sans nom n'a pas de chip lisible ; sans site il
                // reste valide (on le remplira plus tard).
                onTap: _name.text.trim().isEmpty ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pastille de couleur du nuancier.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.on, required this.onTap});
  final WorkspaceColor color;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final c = color.of(Theme.of(context).brightness);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          // Anneau de sélection détaché : lisible sur toutes les teintes.
          border: Border.all(
            color: on ? p.fg : Colors.transparent,
            width: 2,
          ),
        ),
        child: on
            ? Icon(Icons.check_rounded, size: 16, color: p.surface)
            : null,
      ),
    );
  }
}

/// Choix d'icône, teinté de la couleur courante du groupe.
class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.color,
    required this.on,
    required this.onTap,
  });
  final WorkspaceIcon icon;
  final WorkspaceColor color;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final c = color.of(Theme.of(context).brightness);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: on ? c.withValues(alpha: 0.16) : p.chip,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: on ? c : Colors.transparent, width: 1.5),
        ),
        child: Icon(icon.data, size: 18, color: on ? c : p.fg2),
      ),
    );
  }
}

/// Ajouter une source sans quitter le groupe en cours de composition.
class _AddSourceRow extends StatelessWidget {
  const _AddSourceRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GlanceCard(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.add, size: 22, color: p.accent),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              'Ajouter une source',
              style: GT.body(15, weight: 500, color: p.accent),
            ),
          ),
          Text('ses sites entrent ici', style: GT.body(11.5, color: p.fg3)),
        ],
      ),
    );
  }
}

class _SiteRow extends StatelessWidget {
  const _SiteRow({
    required this.site,
    required this.on,
    required this.onTap,
    this.accountLabel,
  });
  final Site site;
  final bool on;
  final VoidCallback onTap;
  final String? accountLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final sub = [
      if (site.domain.isNotEmpty && site.domain != site.name) site.domain,
      ?accountLabel,
    ].join(' · ');

    return GlanceCard(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      selected: on,
      onTap: onTap,
      child: Row(
        children: [
          SiteAvatar(site, size: 34),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  site.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GT.body(15, weight: 500, color: p.fg),
                ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GT.mono(11, color: p.fg2),
                  ),
                ],
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: on ? p.accent : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: on ? p.accent : p.fg3, width: 2),
            ),
            child:
                on ? Icon(Icons.check_rounded, size: 15, color: p.accentInk) : null,
          ),
        ],
      ),
    );
  }
}
