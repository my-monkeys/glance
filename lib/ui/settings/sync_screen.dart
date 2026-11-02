import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/sync/sync_api.dart' show kSyncMinPasswordLength;
import '../../l10n/l10n.dart';
import '../../state/sync.dart';
import '../../theme/motion.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../root_scaffold.dart';
import '../widgets/common.dart';
import '../widgets/field.dart';
import '../widgets/motion.dart';
import '../widgets/toast.dart';

/// Ouvre l'écran Glance Sync (modale sur desktop, page sur mobile).
Future<void> openSync(BuildContext context) =>
    showGlanceModal<void>(context, const SyncScreen());

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final sync = ref.watch(syncControllerProvider);

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
                        Text('Glance Sync', style: GT.display(26, color: p.fg)),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.syncSubtitle,
                          style: GT.body(13, color: p.fg2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: GlanceSwap(
                child: KeyedSubtree(
                  key: ValueKey(sync.status),
                  child: switch (sync.status) {
                    SyncStatus.unknown => Center(
                        child: CircularProgressIndicator(
                            color: p.accent, strokeWidth: 2.4),
                      ),
                    SyncStatus.signedOut => const _AuthForm(),
                    SyncStatus.signedIn => const _Account(),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formulaire connexion / création de compte.
class _AuthForm extends ConsumerStatefulWidget {
  const _AuthForm();
  @override
  ConsumerState<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<_AuthForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _createMode = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pw = _password.text;
    if (email.isEmpty || pw.isEmpty) return;
    final ctrl = ref.read(syncControllerProvider.notifier);
    final create = _createMode;
    final ok = await (create ? ctrl.signUp(email, pw) : ctrl.signIn(email, pw));
    if (ok && mounted) {
      final l10n = context.l10n;
      showGlanceToast(
          context, create ? l10n.syncToastCreated : l10n.syncToastSignedIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final l10n = context.l10n;
    final sync = ref.watch(syncControllerProvider);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        GlanceField(
          label: l10n.syncEmail,
          controller: _email,
          hint: l10n.syncEmailHint,
          url: true,
          autofocus: true,
        ),
        const SizedBox(height: 14),
        GlanceField(
          label: l10n.syncPassword,
          controller: _password,
          hint: _createMode
              ? l10n.syncPasswordHint(kSyncMinPasswordLength)
              : null,
          obscure: true,
          onSubmitted: (_) => _submit(),
        ),
        GlanceReveal(
          show: sync.error != null,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(sync.error ?? '', style: GT.body(13, color: p.neg)),
          ),
        ),
        const SizedBox(height: 20),
        GlanceButton(
          label: _createMode ? l10n.syncCreateAccountButton : l10n.syncSignIn,
          busy: sync.busy,
          onTap: _submit,
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _createMode = !_createMode),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: GlanceSwap(
                duration: kMotionFast,
                dy: 4,
                child: Text(
                  _createMode ? l10n.syncHaveAccount : l10n.syncCreateAccount,
                  key: ValueKey(_createMode),
                  style: GT.body(14, weight: 500, color: p.accent),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        GlanceCard(
          padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, size: 18, color: p.fg2),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.syncEncryptedNote,
                  style: GT.body(12.5, color: p.fg2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Vue « connecté » : statut, sync manuelle, déconnexion.
class _Account extends ConsumerWidget {
  const _Account();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final l10n = context.l10n;
    final sync = ref.watch(syncControllerProvider);
    final ctrl = ref.read(syncControllerProvider.notifier);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        GlanceCard(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: p.chip, shape: BoxShape.circle),
                child: Icon(Icons.cloud_done_rounded, size: 20, color: p.accent),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sync.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GT.body(15, weight: 600, color: p.fg)),
                    const SizedBox(height: 2),
                    Text(
                      sync.lastSyncAt == null
                          ? l10n.syncNever
                          : l10n.syncLastSync(DateFormat.MMMd()
                              .add_Hm()
                              .format(sync.lastSyncAt!)),
                      style: GT.body(12, color: p.fg2),
                    ),
                  ],
                ),
              ),
              if (sync.isPro)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('PRO', style: GT.mono(10.5, weight: 700, color: p.accent)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlanceSwap(
          child: KeyedSubtree(
            key: ValueKey(sync.isPro),
            child: sync.isPro
                ? GlanceButton(
                    label: l10n.syncNow,
                    icon: Icons.sync_rounded,
                    busy: sync.busy,
                    onTap: () async {
                      if (await ctrl.syncNow() && context.mounted) {
                        showGlanceToast(context, l10n.syncToastSynced);
                      }
                    },
                  )
                : _UnlockCard(),
          ),
        ),
        GlanceReveal(
          show: sync.error != null || sync.notice != null,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              sync.error ?? sync.notice ?? '',
              style: GT.body(13, color: sync.error != null ? p.neg : p.fg2),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              await ctrl.signOut();
              if (context.mounted) {
                showGlanceToast(context, l10n.syncToastSignedOut,
                    kind: ToastKind.info);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(l10n.syncSignOut, style: GT.body(14, color: p.fg2)),
            ),
          ),
        ),
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: sync.busy ? null : () => _confirmDelete(context, ctrl),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(l10n.syncDeleteAccount, style: GT.body(13, color: p.neg)),
            ),
          ),
        ),
      ],
    );
  }

  /// Suppression de compte (exigée par Apple) : confirmation explicite, puis
  /// effacement serveur + local. Irréversible.
  Future<void> _confirmDelete(BuildContext context, SyncController ctrl) async {
    final p = context.glance;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.syncDeleteTitle),
        content: Text(l10n.syncDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel, style: GT.body(14, color: p.fg2)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonDelete,
                style: GT.body(14, weight: 600, color: p.neg)),
          ),
        ],
      ),
    );
    if (confirmed == true && await ctrl.deleteAccount() && context.mounted) {
      showGlanceToast(context, l10n.syncToastDeleted, kind: ToastKind.info);
    }
  }
}

/// Compte non-Pro : incitation à débloquer (achat unique via RevenueCat).
class _UnlockCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final l10n = context.l10n;
    final sync = ref.watch(syncControllerProvider);
    final ctrl = ref.read(syncControllerProvider.notifier);
    final canBuy = ref.watch(purchasesSupportedProvider);

    return GlanceCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.syncUnlockTitle, style: GT.body(16, weight: 600, color: p.fg)),
          const SizedBox(height: 6),
          Text(
            canBuy
                ? l10n.syncUnlockBuy
                : l10n.syncUnlockElsewhere,
            style: GT.body(13, color: p.fg2),
          ),
          const SizedBox(height: 14),
          if (canBuy) ...[
            GlanceButton(
              label: l10n.syncUnlockButton,
              busy: sync.busy,
              onTap: () async {
                if (await ctrl.buyPro() && context.mounted) {
                  showGlanceToast(context, l10n.syncToastUnlocked);
                }
              },
            ),
            const SizedBox(height: 4),
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  if (await ctrl.restorePurchase() && context.mounted) {
                    showGlanceToast(context, l10n.syncToastRestored);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(l10n.syncRestore,
                      style: GT.body(13, weight: 500, color: p.accent)),
                ),
              ),
            ),
          ] else
            GlanceButton(label: l10n.syncSoon, onTap: null),
        ],
      ),
    );
  }
}
