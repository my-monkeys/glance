import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../state/sync.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../root_scaffold.dart';
import '../widgets/common.dart';
import '../widgets/field.dart';

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
                          'Vos comptes et groupes, synchronisés et chiffrés.',
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
              child: switch (sync.status) {
                SyncStatus.unknown => Center(
                    child: CircularProgressIndicator(color: p.accent, strokeWidth: 2.4),
                  ),
                SyncStatus.signedOut => const _AuthForm(),
                SyncStatus.signedIn => const _Account(),
              },
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
    await (_createMode ? ctrl.signUp(email, pw) : ctrl.signIn(email, pw));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final sync = ref.watch(syncControllerProvider);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        GlanceField(
          label: 'E-mail',
          controller: _email,
          hint: 'vous@exemple.fr',
          url: true,
          autofocus: true,
        ),
        const SizedBox(height: 14),
        GlanceField(
          label: 'Mot de passe',
          controller: _password,
          obscure: true,
          onSubmitted: (_) => _submit(),
        ),
        if (sync.error != null) ...[
          const SizedBox(height: 12),
          Text(sync.error!, style: GT.body(13, color: p.neg)),
        ],
        const SizedBox(height: 20),
        GlanceButton(
          label: _createMode ? 'Créer le compte' : 'Se connecter',
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
              child: Text(
                _createMode ? 'J\'ai déjà un compte' : 'Créer un compte',
                style: GT.body(14, weight: 500, color: p.accent),
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
                  'Votre config est chiffrée sur l\'appareil avant l\'envoi : le '
                  'serveur ne peut pas la lire. Mot de passe oublié = sync '
                  'irrécupérable.',
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
                          ? 'Jamais synchronisé'
                          : 'Sync ${DateFormat('d MMM HH:mm', 'fr_FR').format(sync.lastSyncAt!)}',
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
        if (sync.isPro) ...[
          GlanceButton(
            label: 'Synchroniser maintenant',
            icon: Icons.sync_rounded,
            busy: sync.busy,
            onTap: ctrl.syncNow,
          ),
        ] else
          _UnlockCard(),
        if (sync.error != null) ...[
          const SizedBox(height: 12),
          Text(sync.error!, style: GT.body(13, color: p.neg)),
        ],
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: ctrl.signOut,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text('Se déconnecter', style: GT.body(14, color: p.neg)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Compte non-Pro : incitation à débloquer (achat unique via RevenueCat).
class _UnlockCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final sync = ref.watch(syncControllerProvider);
    final ctrl = ref.read(syncControllerProvider.notifier);
    final canBuy = ref.watch(purchasesSupportedProvider);

    return GlanceCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Débloquez Glance Sync', style: GT.body(16, weight: 600, color: p.fg)),
          const SizedBox(height: 6),
          Text(
            canBuy
                ? 'Sauvegardez et synchronisez vos comptes et groupes sur tous '
                    'vos appareils. Achat unique.'
                : 'Achat unique depuis l\'app mobile (iOS/Android). Une fois '
                    'débloqué, connectez-vous ici avec le même compte : la sync '
                    'suit automatiquement.',
            style: GT.body(13, color: p.fg2),
          ),
          const SizedBox(height: 14),
          if (canBuy) ...[
            GlanceButton(
              label: 'Débloquer',
              busy: sync.busy,
              onTap: ctrl.buyPro,
            ),
            const SizedBox(height: 4),
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: ctrl.restorePurchase,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text('Restaurer un achat',
                      style: GT.body(13, weight: 500, color: p.accent)),
                ),
              ),
            ),
          ] else
            const GlanceButton(label: 'Bientôt disponible', onTap: null),
        ],
      ),
    );
  }
}
