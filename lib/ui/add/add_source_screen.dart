import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../data/models/account.dart';
import '../../data/providers/analytics_provider.dart';
import '../../data/providers/provider_factory.dart';
import '../../data/repository/accounts_repository.dart';
import '../../state/period_state.dart';
import '../../state/providers.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../root_scaffold.dart';
import '../widgets/common.dart';
import '../widgets/field.dart';
import 'site_picker.dart';

/// Ajout d'une source en 2 étapes : fournisseur + identifiants, puis choix des
/// sites à suivre. Utilisé aussi bien au premier lancement que depuis les
/// réglages. Passer [editing] + [initialCreds] pour **modifier** un compte
/// existant (fournisseur figé, champs pré-remplis, mise à jour au lieu d'ajout).
class AddSourceScreen extends ConsumerStatefulWidget {
  const AddSourceScreen({super.key, this.editing, this.initialCreds});

  final Account? editing;
  final Map<String, String>? initialCreds;

  @override
  ConsumerState<AddSourceScreen> createState() => _AddSourceScreenState();
}

class _AddSourceScreenState extends ConsumerState<AddSourceScreen> {
  ProviderKind _kind = ProviderKind.umami;
  final Map<String, TextEditingController> _ctl = {};
  final _name = TextEditingController();
  bool _busy = false;
  bool _testing = false;
  String? _error;
  String? _testOk; // message de succès du test (vert)

  bool get _isEditing => widget.editing != null;

  /// Lit les identifiants saisis et signale s'il manque un champ obligatoire.
  ({Map<String, String> creds, bool missing}) _readCreds() {
    final fields = credentialFieldsFor(_kind);
    final creds = {for (final f in fields) f.key: _c(f.key).text.trim()};
    final missing =
        fields.any((f) => !f.optional && (creds[f.key] ?? '').isEmpty);
    return (creds: creds, missing: missing);
  }

  Account _accountFrom(Map<String, String> creds) => Account(
        id: widget.editing?.id ?? AccountsRepository.newId(),
        kind: _kind,
        baseUrl: creds['baseUrl'] ?? 'https://api.usefathom.com',
        label: _name.text.trim().isEmpty ? null : _name.text.trim(),
      );

  /// Teste la configuration sans l'enregistrer (valide identifiants + clé).
  Future<void> _test() async {
    final (:creds, :missing) = _readCreds();
    if (missing) {
      setState(() => _error = 'Renseigne les champs obligatoires.');
      return;
    }
    setState(() {
      _testing = true;
      _error = null;
      _testOk = null;
    });
    try {
      final n = await buildProvider(_accountFrom(creds), creds).verify();
      if (!mounted) return;
      setState(() => _testOk = n > 0
          ? 'Connexion réussie · $n site${n > 1 ? 's' : ''} détecté${n > 1 ? 's' : ''}'
          : 'Connexion réussie.');
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  TextEditingController _c(String key) =>
      _ctl.putIfAbsent(key, () => TextEditingController());

  @override
  void initState() {
    super.initState();
    final acc = widget.editing;
    if (acc != null) {
      _kind = acc.kind;
      _name.text = acc.label ?? '';
      final creds = widget.initialCreds ?? const {};
      for (final e in creds.entries) {
        _c(e.key).text = e.value;
      }
      // baseUrl peut ne pas être dans les creds selon le fournisseur.
      if ((_c('baseUrl').text).isEmpty) _c('baseUrl').text = acc.baseUrl;
    }
  }

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
    final missingRequired =
        fields.any((f) => !f.optional && (creds[f.key] ?? '').isEmpty);
    if (missingRequired) {
      setState(() => _error = 'Renseigne les champs obligatoires.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    final account = Account(
      id: widget.editing?.id ?? AccountsRepository.newId(),
      kind: _kind,
      baseUrl: creds['baseUrl'] ?? 'https://api.usefathom.com',
      label: _name.text.trim().isEmpty ? null : _name.text.trim(),
    );

    try {
      final provider = buildProvider(account, creds);
      final sites = await provider.listSites();
      if (!mounted) return;
      if (sites.isEmpty) {
        // Aucun site listé : le fournisseur ne sait pas énumérer (ex. Plausible
        // sans accès Sites API) et aucun domaine n'a été saisi. On bloque avant
        // de créer un compte vide, avec un message actionnable.
        setState(() {
          _busy = false;
          _error = _kind == ProviderKind.plausible
              ? 'Aucun site listé automatiquement : votre instance n\'expose pas '
                  'l\'API de listing (Plausible Community Edition). Renseignez le '
                  'domaine à suivre ci-dessus.'
              : 'Aucun site trouvé pour ce compte.';
        });
        return;
      }
      // Valide la clé/les identifiants de stats sur le 1er site : pour Plausible,
      // le listing (email/mdp) et les stats (clé API) sont indépendants — une
      // mauvaise clé passait inaperçue (sites listés mais stats en échec 401).
      try {
        await provider.summary(sites.first, const PeriodState().window());
      } on DioException catch (e) {
        final code = e.response?.statusCode ?? 0;
        if (code == 401 || code == 403) {
          setState(() {
            _busy = false;
            _error = _kind == ProviderKind.plausible
                ? 'Clé API refusée (accès aux stats). Vérifiez la clé API.'
                : 'Identifiants refusés.';
          });
          return;
        }
        // Autre erreur (réseau ponctuel) : on n'empêche pas la config.
      }
      if (!mounted) return;
      // Étape 2 : sélection des sites (modale sur desktop, page sur mobile).
      final choice = await showGlanceModal<SiteChoice?>(
        context,
        SitePickerScreen(
          providerName: _kind.displayName,
          sites: sites,
          initialSelection: widget.editing?.sites,
        ),
      );
      if (choice == null) {
        // annulé
        setState(() => _busy = false);
        return;
      }
      // null = tous les sites ; [] = aucun (masqué) ; [ids] = sélection explicite.
      final chosen = choice.sites;
      // add() remplace par id → sert aussi à la mise à jour d'un compte existant.
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
                  Text(_isEditing ? 'Modifier la source' : 'Nouvelle source',
                      style: GT.display(28, color: p.fg)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                children: [
                  // Fournisseur : choisissable à l'ajout, figé en édition.
                  if (!_isEditing) ...[
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
                                  Text(k.initial,
                                      style: GT.stat(22, color: p.fg)),
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
                  ],
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
                    if (f.hint != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 3, right: 3),
                        child: Text(f.hint!, style: GT.body(12, color: p.fg3)),
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
                  if (_testOk != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 16, color: p.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child:
                              Text(_testOk!, style: GT.body(13, color: p.accent)),
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
              child: Column(
                children: [
                  GlanceButtonOutline(
                    label: 'Tester la configuration',
                    busy: _testing,
                    leading: Icon(Icons.wifi_tethering_rounded,
                        size: 17, color: p.fg),
                    onTap: _test,
                  ),
                  const SizedBox(height: 10),
                  GlanceButton(
                    label: _isEditing ? 'Enregistrer' : 'Continuer',
                    busy: _busy,
                    icon: Icons.arrow_forward_rounded,
                    onTap: _continue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
