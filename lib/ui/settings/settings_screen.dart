import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/account.dart';
import '../../data/models/period.dart';
import '../../data/providers/analytics_provider.dart';
import '../../l10n/l10n.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../state/sync.dart';
import '../../state/updater.dart';
import '../../state/workspaces.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../root_scaffold.dart';
import '../widgets/adaptive_sheet.dart';
import '../widgets/chip.dart';
import '../widgets/common.dart';
import 'account_menu.dart';
import 'settings_labels.dart';
import 'sync_screen.dart';
import 'transfer_screen.dart';
import 'workspaces_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final l10n = context.l10n;
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
        Text(l10n.settingsTitle, style: GT.display(34, color: p.fg)),
        const SizedBox(height: 22),

        // Compte.
        _GroupLabel(l10n.settingsGroupAccount),
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
                          ? l10n.settingsAccountBadAuth
                          : l10n.settingsAccountUnreachable)
                      : l10n.settingsAccountSubtitle(
                          a.kind.displayName, siteCount(a)),
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
                  onTap: () => openAccountMenu(context, a),
                );
              }),
            _Row(
              leading: Icon(Icons.add, color: p.accent, size: 22),
              title: l10n.settingsAddSource,
              titleColor: p.accent,
              onTap: () => openAddSource(context),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Sites.
        _GroupLabel(l10n.settingsGroupSites),
        _Group(
          children: [
            _Row(
              leading: Icon(Icons.folder_rounded, color: p.fg2, size: 20),
              title: l10n.settingsGroupsTitle,
              subtitle: groups.isEmpty
                  ? l10n.settingsGroupsHint
                  : groups.map((g) => g.name).join(' · '),
              trailing:
                  Icon(Icons.chevron_right_rounded, color: p.fg3, size: 22),
              onTap: () => openWorkspaces(context),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Synchronisation cloud (compte Glance Sync).
        _GroupLabel(l10n.settingsGroupSync),
        _Group(
          children: [
            Builder(builder: (context) {
              final sync = ref.watch(syncControllerProvider);
              final signedIn = sync.status == SyncStatus.signedIn;
              return _Row(
                leading: Icon(
                  signedIn ? Icons.cloud_done_rounded : Icons.cloud_outlined,
                  color: signedIn ? p.accent : p.fg2,
                  size: 20,
                ),
                title: 'Glance Sync',
                subtitle: signedIn
                    ? (sync.email ?? l10n.settingsSyncConnected)
                    : l10n.settingsSyncPitch,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (signedIn && sync.isPro)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text('PRO',
                            style: GT.mono(10.5, weight: 700, color: p.accent)),
                      ),
                    Icon(Icons.chevron_right_rounded, color: p.fg3, size: 22),
                  ],
                ),
                onTap: () => openSync(context),
              );
            }),
          ],
        ),
        const SizedBox(height: 22),

        // Transfert d'un appareil à l'autre.
        _GroupLabel(l10n.settingsGroupTransfer),
        _Group(
          children: [
            _Row(
              leading: Icon(Icons.qr_code_2_rounded, color: p.fg2, size: 20),
              title: l10n.settingsTransferShow,
              subtitle: accounts.isEmpty
                  ? l10n.settingsTransferNone
                  : l10n.settingsTransferContents,
              trailing:
                  Icon(Icons.chevron_right_rounded, color: p.fg3, size: 22),
              onTap: accounts.isEmpty ? null : () => openTransferExport(context),
            ),
            _Row(
              leading: Icon(Icons.qr_code_scanner_rounded,
                  color: p.fg2, size: 20),
              title: l10n.settingsTransferImport,
              subtitle: l10n.settingsTransferScan,
              trailing:
                  Icon(Icons.chevron_right_rounded, color: p.fg3, size: 22),
              onTap: () => openTransferImport(context),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Apparence.
        _GroupLabel(l10n.settingsGroupAppearance),
        _Group(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(context.l10n.settingsLanguageTitle,
                      style: GT.body(15, color: p.fg)),
                  const SizedBox(height: 12),
                  ChipRow(
                    children: [
                      GlanceChip(
                        label: context.l10n.settingsLanguageAuto,
                        selected: settings.locale == null,
                        onTap: () => notifier.setLocale(null),
                      ),
                      // Une langue ajoutée à l'app apparaît ici sans autre geste.
                      for (final l in AppLocalizations.supportedLocales)
                        GlanceChip(
                          label: nativeLanguageName(l),
                          selected: settings.locale == l,
                          onTap: () => notifier.setLocale(l),
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
                  Text(l10n.settingsThemeTitle, style: GT.body(15, color: p.fg)),
                  const SizedBox(height: 12),
                  ChipRow(
                    children: [
                      for (final t in ThemeChoice.values)
                        GlanceChip(
                          label: t.localized(l10n),
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
                  Text(l10n.settingsChartsTitle, style: GT.body(15, color: p.fg)),
                  const SizedBox(height: 4),
                  Text(l10n.settingsChartsHint,
                      style: GT.body(12.5, color: p.fg3)),
                  const SizedBox(height: 12),
                  ChipRow(
                    children: [
                      for (final style in ChartStyle.values)
                        GlanceChip(
                          label: style.localized(l10n),
                          selected: settings.chartStyle == style,
                          onTap: () => notifier.setChartStyle(style),
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
                  Text(l10n.settingsDefaultPeriod, style: GT.body(15, color: p.fg)),
                  const SizedBox(height: 4),
                  Text(l10n.settingsDefaultPeriodHint,
                      style: GT.body(12.5, color: p.fg3)),
                  const SizedBox(height: 12),
                  ChipRow(
                    children: [
                      for (final per in Period.values)
                        if (per != Period.custom)
                          GlanceChip(
                            label: per.label(l10n),
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

        // Données.
        _GroupLabel(l10n.settingsGroupData),
        _Group(
          children: [
            _Row(
              title: l10n.settingsRefresh,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _refreshLabel(l10n, settings.refreshSeconds),
                    style: GT.mono(13, color: p.fg2),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: p.fg3, size: 22),
                ],
              ),
              onTap: () => _pickRefresh(context, ref, settings.refreshSeconds),
            ),
          ],
        ),

        // Application (desktop uniquement : les stores gèrent les MàJ mobiles).
        if (Updater.isSupported) ...[
          const SizedBox(height: 22),
          _GroupLabel(l10n.settingsGroupApp),
          _Group(
            children: [
              _Row(
                leading:
                    Icon(Icons.system_update_rounded, color: p.fg2, size: 20),
                title: l10n.settingsCheckUpdates,
                trailing:
                    Icon(Icons.chevron_right_rounded, color: p.fg3, size: 22),
                onTap: () => Updater.checkNow(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static String _refreshLabel(AppLocalizations l10n, int s) => s >= 60
      ? l10n.settingsRefreshMinutes(s ~/ 60)
      : l10n.settingsRefreshSeconds(s);

  void _pickRefresh(BuildContext context, WidgetRef ref, int current) {
    const options = [10, 30, 60, 300];
    showGlanceSheet<void>(
      context,
      (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            for (final o in options)
              ListTile(
                title: Text(
                  _refreshLabel(ctx.l10n, o),
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
