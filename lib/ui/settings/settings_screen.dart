import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/account.dart';
import '../../data/models/period.dart';
import '../../data/providers/analytics_provider.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../state/workspaces.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../add/add_source_screen.dart';
import '../add/site_picker.dart';
import '../root_scaffold.dart';
import '../widgets/chip.dart';
import '../widgets/common.dart';
import 'transfer_screen.dart';
import 'workspaces_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final accounts = ref.watch(accountsProvider);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final sites = ref.watch(sitesProvider).value ?? const [];
    final groups = ref.watch(workspacesProvider);

    int siteCount(Account a) => sites.where((s) => s.accountId == a.id).length;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 14,
        20,
        120,
      ),
      children: [
        Text('Réglages', style: GT.display(34, color: p.fg)),
        const SizedBox(height: 22),

        // Compte.
        _GroupLabel('Compte'),
        _Group(
          children: [
            for (final a in accounts)
              Builder(builder: (context) {
                final health = ref.watch(accountHealthProvider(a.id)).value;
                final problem = health == AccountHealth.badAuth ||
                    health == AccountHealth.unreachable;
                return _Row(
                  leading: Mark(
                    a.kind.initial,
                    size: 30,
                    circle: false,
                  ),
                  title: a.title,
                  subtitle: problem
                      ? (health == AccountHealth.badAuth
                          ? 'Identifiants ou clé API refusés'
                          : 'Instance injoignable')
                      : '${a.kind.displayName} · ${siteCount(a)} site${siteCount(a) > 1 ? 's' : ''}',
                  subtitleColor: problem ? p.neg : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (problem)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(Icons.error_outline_rounded,
                              color: p.neg, size: 19),
                        ),
                      Icon(Icons.chevron_right_rounded, color: p.fg3, size: 22),
                    ],
                  ),
                  onTap: () => _openAccount(context, ref, a),
                );
              }),
            _Row(
              leading: Icon(Icons.add, color: p.accent, size: 22),
              title: 'Ajouter une source',
              titleColor: p.accent,
              onTap: () => openAddSource(context),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Sites.
        _GroupLabel('Sites'),
        _Group(
          children: [
            _Row(
              leading: Icon(Icons.folder_rounded, color: p.fg2, size: 20),
              title: 'Groupes',
              subtitle: groups.isEmpty
                  ? 'Lire une partie de vos sites à part'
                  : groups.map((g) => g.name).join(' · '),
              trailing:
                  Icon(Icons.chevron_right_rounded, color: p.fg3, size: 22),
              onTap: () => openWorkspaces(context),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Transfert d'un appareil à l'autre.
        _GroupLabel('Transfert'),
        _Group(
          children: [
            _Row(
              leading: Icon(Icons.qr_code_2_rounded, color: p.fg2, size: 20),
              title: 'Afficher un QR de transfert',
              subtitle: accounts.isEmpty
                  ? 'Aucun compte à transférer'
                  : 'Comptes, identifiants et groupes',
              trailing:
                  Icon(Icons.chevron_right_rounded, color: p.fg3, size: 22),
              onTap: accounts.isEmpty ? null : () => openTransferExport(context),
            ),
            _Row(
              leading: Icon(Icons.qr_code_scanner_rounded,
                  color: p.fg2, size: 20),
              title: 'Importer depuis un autre appareil',
              subtitle: 'Scanner un QR de transfert',
              trailing:
                  Icon(Icons.chevron_right_rounded, color: p.fg3, size: 22),
              onTap: () => openTransferImport(context),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Apparence.
        _GroupLabel('Apparence'),
        _Group(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Thème', style: GT.body(15, color: p.fg)),
                  const SizedBox(height: 12),
                  ChipRow(
                    children: [
                      for (final t in ThemeChoice.values)
                        GlanceChip(
                          label: t.label,
                          selected: settings.theme == t,
                          onTap: () => notifier.setTheme(t),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Période par défaut', style: GT.body(15, color: p.fg)),
                  const SizedBox(height: 4),
                  Text('À l\'ouverture de l\'application',
                      style: GT.body(12.5, color: p.fg3)),
                  const SizedBox(height: 12),
                  ChipRow(
                    children: [
                      for (final per in Period.values)
                        if (per != Period.custom)
                          GlanceChip(
                            label: per.label,
                            selected: settings.defaultPeriod == per,
                            onTap: () => notifier.setDefaultPeriod(per),
                          ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Notifications.
        _GroupLabel('Notifications'),
        _Group(
          children: [
            _Row(
              title: 'Pic de trafic',
              trailing: GlanceToggle(
                value: settings.spike,
                onTap: notifier.toggleSpike,
              ),
            ),
            _Row(
              title: 'Rapport quotidien',
              subtitle: 'Chaque jour à 9 h 00',
              trailing: GlanceToggle(
                value: settings.daily,
                onTap: notifier.toggleDaily,
              ),
            ),
            _Row(
              title: 'Objectifs atteints',
              trailing: GlanceToggle(
                value: settings.goals,
                onTap: notifier.toggleGoals,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Données.
        _GroupLabel('Données'),
        _Group(
          children: [
            _Row(
              title: 'Actualisation auto',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _refreshLabel(settings.refreshSeconds),
                    style: GT.mono(13, color: p.fg2),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: p.fg3, size: 22),
                ],
              ),
              onTap: () => _pickRefresh(context, ref, settings.refreshSeconds),
            ),
            _Row(
              title: 'Se déconnecter',
              titleColor: p.neg,
              onTap: () => _confirmLogout(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  static String _refreshLabel(int s) => s >= 60 ? '${s ~/ 60} min' : '$s s';

  void _pickRefresh(BuildContext context, WidgetRef ref, int current) {
    const options = [10, 30, 60, 300];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.glance.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            for (final o in options)
              ListTile(
                title: Text(
                  _refreshLabel(o),
                  style: GT.body(16, color: ctx.glance.fg),
                ),
                trailing: o == current
                    ? Icon(Icons.check_rounded, color: ctx.glance.accent)
                    : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setRefresh(o);
                  Navigator.of(ctx).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _openAccount(BuildContext context, WidgetRef ref, Account a) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.glance.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(a.title, style: GT.body(16, weight: 600, color: ctx.glance.fg)),
            Text(
              '${a.kind.displayName} · ${a.sites == null ? 'tous les sites' : a.sites!.isEmpty ? 'aucun site' : '${a.sites!.length} site${a.sites!.length > 1 ? 's' : ''}'}',
              style: GT.body(13, color: ctx.glance.fg2),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.tune_rounded, color: ctx.glance.fg),
              title: Text(
                'Modifier la source',
                style: GT.body(16, color: ctx.glance.fg),
              ),
              subtitle: Text(
                'URL, identifiants, clé API…',
                style: GT.body(12.5, color: ctx.glance.fg3),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _editSource(context, ref, a);
              },
            ),
            ListTile(
              leading: Icon(Icons.checklist_rounded, color: ctx.glance.fg),
              title: Text(
                'Choisir les sites',
                style: GT.body(16, color: ctx.glance.fg),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _editSites(context, ref, a);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: ctx.glance.neg),
              title: Text(
                'Supprimer ce compte',
                style: GT.body(16, color: ctx.glance.neg),
              ),
              onTap: () {
                ref.read(accountsProvider.notifier).remove(a.id);
                Navigator.of(ctx).pop();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _editSource(BuildContext context, WidgetRef ref, Account a) async {
    final creds = await ref.read(accountsRepoProvider).credentials(a.id);
    if (!context.mounted) return;
    await showGlanceModal<void>(
      context,
      AddSourceScreen(editing: a, initialCreds: creds),
    );
  }

  Future<void> _editSites(BuildContext context, WidgetRef ref, Account a) async {
    final sites = await ref.read(accountSitesProvider(a.id).future);
    if (!context.mounted) return;
    final choice = await showGlanceModal<SiteChoice?>(
      context,
      SitePickerScreen(
        providerName: a.kind.displayName,
        sites: sites,
        initialSelection: a.sites,
      ),
    );
    if (choice == null) return; // annulé
    // null = tous ; [] = aucun (masqué) ; [ids] = sélection explicite.
    await ref.read(accountsProvider.notifier).updateSites(a.id, choice.sites);
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.glance.surface,
        title: Text('Se déconnecter ?', style: GT.display(20, color: ctx.glance.fg)),
        content: Text(
          'Toutes les sources configurées seront supprimées de cet appareil.',
          style: GT.body(14, color: ctx.glance.fg2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Annuler', style: GT.body(15, color: ctx.glance.fg2)),
          ),
          TextButton(
            onPressed: () {
              ref.read(accountsProvider.notifier).clear();
              Navigator.of(ctx).pop();
            },
            child: Text(
              'Déconnexion',
              style: GT.body(15, weight: 600, color: ctx.glance.neg),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 3, bottom: 8),
      child: SectionLabel(text),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: p.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: p.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.subtitleColor,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            if (leading != null) ...[
              SizedBox(width: 30, child: Center(child: leading)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GT.body(15, color: titleColor ?? p.fg),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: GT.body(12, color: subtitleColor ?? p.fg2)),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
