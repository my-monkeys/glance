import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../data/models/account.dart';
import '../../data/providers/analytics_provider.dart';
import '../../data/providers/provider_factory.dart';
import '../../data/repository/accounts_repository.dart';
import '../../state/providers.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../widgets/common.dart';
import '../widgets/field.dart';
import 'site_picker.dart';

/// Ajout d'une source en 2 étapes : fournisseur + identifiants, puis choix des
/// sites à suivre. Utilisé aussi bien au premier lancement que depuis les
/// réglages.
class AddSourceScreen extends ConsumerStatefulWidget {
  const AddSourceScreen({super.key});

  @override
  ConsumerState<AddSourceScreen> createState() => _AddSourceScreenState();
}

class _AddSourceScreenState extends ConsumerState<AddSourceScreen> {
  ProviderKind _kind = ProviderKind.umami;
  final Map<String, TextEditingController> _ctl = {};
  final _name = TextEditingController();
  bool _busy = false;
  String? _error;

  TextEditingController _c(String key) =>
      _ctl.putIfAbsent(key, () => TextEditingController());

  @override
  void dispose() {
    for (final c in _ctl.values) {
      c.dispose();
    }
    _name.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final fields = credentialFieldsFor(_kind);
    final creds = {for (final f in fields) f.key: _c(f.key).text.trim()};
    if (creds.values.any((v) => v.isEmpty)) {
      setState(() => _error = 'Renseigne tous les champs.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    final account = Account(
      id: AccountsRepository.newId(),
      kind: _kind,
      baseUrl: creds['baseUrl'] ?? 'https://api.usefathom.com',
      label: _name.text.trim().isEmpty ? null : _name.text.trim(),
    );

    try {
      final provider = buildProvider(account, creds);
      final sites = await provider.listSites();
      if (!mounted) return;
      // Étape 2 : sélection des sites.
      final selection = await Navigator.of(context).push<List<String>?>(
        MaterialPageRoute(
          builder: (_) => SitePickerScreen(
            providerName: _kind.displayName,
            sites: sites,
          ),
        ),
      );
      if (selection == null) {
        // annulé
        setState(() => _busy = false);
        return;
      }
      // selection vide via "tous" est encodé par une liste spéciale : voir picker.
      final chosen = selection.isEmpty ? null : selection;
      await ref
          .read(accountsProvider.notifier)
          .add(account.copyWith(sites: chosen, allSites: chosen == null), creds);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final fields = credentialFieldsFor(_kind);

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
                  Text('Nouvelle source', style: GT.display(28, color: p.fg)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 3, bottom: 7),
                    child: Text('FOURNISSEUR', style: GT.label(color: p.fg2)),
                  ),
                  Row(
                    children: [
                      for (final k in ProviderKind.values) ...[
                        Expanded(
                          child: GlanceCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            selected: _kind == k,
                            onTap: () => setState(() {
                              _kind = k;
                              _error = null;
                            }),
                            child: Column(
                              children: [
                                Text(k.initial, style: GT.stat(22, color: p.fg)),
                                const SizedBox(height: 4),
                                Text(
                                  k.displayName,
                                  style: GT.body(12, color: p.fg),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (k != ProviderKind.values.last)
                          const SizedBox(width: 10),
                      ],
                    ],
                  ),
                  const SizedBox(height: 22),
                  GlanceField(
                    label: 'Nom (optionnel)',
                    controller: _name,
                    hint: 'Mon domaine',
                  ),
                  const SizedBox(height: 14),
                  for (final f in fields) ...[
                    GlanceField(
                      label: f.label,
                      controller: _c(f.key),
                      hint: f.placeholder,
                      obscure: f.secret,
                      url: f.keyboardUrl,
                      mono: f.secret,
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 16, color: p.neg),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!, style: GT.body(13, color: p.neg)),
                        ),
                      ],
                    ),
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
                label: 'Continuer',
                busy: _busy,
                icon: Icons.arrow_forward_rounded,
                onTap: _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
