import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../data/models/account.dart';
import '../../l10n/l10n.dart';
import '../../state/account_connection.dart';
import '../../state/providers.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../add/add_source_screen.dart';
import '../add/site_picker.dart';
import '../root_scaffold.dart';
import '../widgets/adaptive_sheet.dart';
import '../widgets/toast.dart';

/// Menu d'un compte : feuille sur téléphone, pop-up sur le bureau.
/// [hostContext] (celui de l'écran, pas du menu) ouvre les écrans suivants une
/// fois le menu refermé.
Future<void> openAccountMenu(BuildContext hostContext, Account account) =>
    showGlanceSheet<void>(
      hostContext,
      (_) => AccountMenu(hostContext: hostContext, account: account),
    );

class AccountMenu extends ConsumerStatefulWidget {
  const AccountMenu({super.key, required this.hostContext, required this.account});

  final BuildContext hostContext;
  final Account account;

  @override
  ConsumerState<AccountMenu> createState() => _AccountMenuState();
}

class _AccountMenuState extends ConsumerState<AccountMenu> {
  bool _testing = false;
  String? _result;
  bool _resultOk = false;

  Account get _a => widget.account;

  Future<void> _test() async {
    // Pris avant l'attente : le menu peut être fermé pendant le test, et les
    // données du compte doivent être rechargées malgré tout.
    final container = ProviderScope.containerOf(context, listen: false);
    final l10n = context.l10n;
    setState(() {
      _testing = true;
      _result = null;
    });
    String message;
    var ok = true;
    try {
      final n = await testAccountConnection(container, _a.id);
      message = n > 0
          ? l10n.accountMenuConnectionOkSites(n)
          : l10n.accountMenuConnectionOk;
    } catch (e) {
      ok = false;
      message = friendlyError(e);
    }
    if (!mounted) return;
    setState(() {
      _testing = false;
      _result = message;
      _resultOk = ok;
    });
  }

  void _close(VoidCallback then) {
    Navigator.of(context).pop();
    then();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final l10n = context.l10n;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(_a.title, style: GT.body(16, weight: 600, color: p.fg)),
          Text(
            '${_a.kind.displayName} · ${selectionLabel(l10n, _a)}',
            style: GT.body(13, color: p.fg2),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: _testing
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: p.accent,
                        ),
                      ),
                    ),
                  )
                : Icon(Icons.wifi_tethering_rounded, color: p.fg),
            title: Text(l10n.accountMenuTest, style: GT.body(16, color: p.fg)),
            subtitle: _result == null
                ? null
                : Text(
                    _result!,
                    style: GT.body(12.5, color: _resultOk ? p.accent : p.neg),
                  ),
            onTap: _testing ? null : _test,
          ),
          ListTile(
            leading: Icon(Icons.tune_rounded, color: p.fg),
            title: Text(l10n.accountMenuEdit, style: GT.body(16, color: p.fg)),
            subtitle: Text(
              l10n.accountMenuEditHint,
              style: GT.body(12.5, color: p.fg3),
            ),
            onTap: () => _close(_editSource),
          ),
          ListTile(
            leading: Icon(Icons.checklist_rounded, color: p.fg),
            title: Text(l10n.accountMenuChooseSites, style: GT.body(16, color: p.fg)),
            onTap: () => _close(_editSites),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: p.neg),
            title: Text(l10n.accountMenuDelete, style: GT.body(16, color: p.neg)),
            onTap: () {
              ref.read(accountsProvider.notifier).remove(_a.id);
              showGlanceToast(context, l10n.accountMenuDeleted,
                  kind: ToastKind.info);
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _editSource() async {
    final host = widget.hostContext;
    final creds = await ref.read(accountsRepoProvider).credentials(_a.id);
    if (!host.mounted) return;
    await showGlanceModal<void>(
      host,
      AddSourceScreen(editing: _a, initialCreds: creds),
    );
  }

  Future<void> _editSites() async {
    final host = widget.hostContext;
    // Rechargée : la liste en cache date du lancement et ne montrerait pas un
    // site créé depuis.
    final sites = await ref.refresh(accountSitesProvider(_a.id).future);
    if (!host.mounted) return;
    final choice = await showGlanceModal<SiteChoice?>(
      host,
      SitePickerScreen(
        providerName: _a.kind.displayName,
        sites: sites,
        initialSelection: _a.sites,
        initialExcluded: _a.excludedSites,
      ),
    );
    if (choice == null) return; // annulé
    await ref
        .read(accountsProvider.notifier)
        .updateSites(_a.id, choice.sites, excluded: choice.excluded);
    if (host.mounted) showGlanceToast(host, host.l10n.accountMenuSelectionSaved);
  }
}

String selectionLabel(AppLocalizations l10n, Account a) {
  final sites = a.sites;
  if (sites == null) {
    final x = a.excludedSites.length;
    return x == 0
        ? l10n.accountSelectionAll
        : l10n.accountSelectionAllExcept(x);
  }
  return sites.isEmpty
      ? l10n.accountSelectionNone
      : l10n.commonSiteCount(sites.length);
}
