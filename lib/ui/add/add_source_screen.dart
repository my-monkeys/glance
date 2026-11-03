import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../data/models/account.dart';
import '../../data/providers/analytics_provider.dart';
import '../../data/providers/provider_factory.dart';
import '../../data/providers/umami_provider.dart';
import '../../data/repository/accounts_repository.dart';
import '../../l10n/l10n.dart';
import '../../state/period_state.dart';
import '../../state/providers.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../root_scaffold.dart';
import '../widgets/chip.dart';
import '../widgets/common.dart';
import '../widgets/field.dart';
import '../widgets/motion.dart';
import '../widgets/toast.dart';
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
  bool _umamiCloud = false;
  final Map<String, TextEditingController> _ctl = {};
  final _name = TextEditingController();
  bool _busy = false;
  bool _testing = false;
  String? _error;
  String? _testOk; // message de succès du test (vert)

  bool get _isEditing => widget.editing != null;

  bool get _cloud => _kind == ProviderKind.umami && _umamiCloud;

  List<CredentialField> _fields() =>
      credentialFieldsFor(context.l10n, _kind, umamiCloud: _cloud);

  /// Lit les identifiants saisis ; [error] dit pourquoi ils sont inutilisables.
  ({Map<String, String> creds, String? error}) _readCreds() {
    final l10n = context.l10n;
    final fields = _fields();
    final creds = {for (final f in fields) f.key: _c(f.key).text.trim()};
    final missing =
        fields.any((f) => !f.optional && (creds[f.key] ?? '').isEmpty);
    // Umami Cloud n'a pas de login : son adresse dans le champ « URL de
    // l'instance » finirait en « Ressource introuvable ».
    final cloudUrl = _kind == ProviderKind.umami &&
        !_cloud &&
        UmamiProvider.looksLikeCloud(creds['baseUrl'] ?? '');
    final error = missing
        ? l10n.addSourceMissingFields
        : cloudUrl
            ? l10n.addSourceUmamiCloudUseKey
            : null;
    return (creds: creds, error: error);
  }

  Account _accountFrom(Map<String, String> creds) => Account(
        id: widget.editing?.id ?? AccountsRepository.newId(),
        kind: _kind,
        baseUrl: _cloud
            ? UmamiProvider.cloudBase
            : creds['baseUrl'] ?? 'https://api.usefathom.com',
        label: _name.text.trim().isEmpty ? null : _name.text.trim(),
      );

  /// Teste la configuration sans l'enregistrer (valide identifiants + clé).
  Future<void> _test() async {
    final l10n = context.l10n;
    final (:creds, :error) = _readCreds();
    if (error != null) {
      setState(() => _error = error);
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
          ? l10n.addSourceTestOkSites(n)
          : l10n.addSourceTestOk);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(l10n, e));
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
      _umamiCloud = UmamiProvider.isCloud(acc.baseUrl);
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
    final l10n = context.l10n;
    final (:creds, :error) = _readCreds();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    final account = _accountFrom(creds);

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
              ? l10n.addSourceNoSitesPlausible
              : l10n.addSourceNoSites;
        });
        return;
      }
      // Valide la clé/les identifiants de stats sur le 1er site : pour Plausible,
      // le listing (email/mdp) et les stats (clé API) sont indépendants — une
      // mauvaise clé passait inaperçue (sites listés mais stats en échec 401).
      try {
        await provider.summary(sites.first, const PeriodState().resolve());
      } on DioException catch (e) {
        final code = e.response?.statusCode ?? 0;
        if (code == 401 || code == 403) {
          setState(() {
            _busy = false;
            _error = _kind == ProviderKind.plausible || _cloud
                ? l10n.addSourceKeyRejected
                : l10n.addSourceCredsRejected;
          });
          return;
        }
        // Autre erreur (réseau ponctuel) : on n'empêche pas la config.
      }
      if (!mounted) return;
      // Étape 2 : sélection des sites (modale sur desktop, page sur mobile).
      // Continuation du flux déjà ouvert → slide horizontal, pas slide-up.
      final choice = await showGlanceModal<SiteChoice?>(
        context,
        SitePickerScreen(
          providerName: _kind.displayName,
          sites: sites,
          initialSelection: widget.editing?.sites,
          initialExcluded: widget.editing?.excludedSites ?? const [],
        ),
        fullscreenDialog: false,
      );
      if (choice == null) {
        // annulé
        setState(() => _busy = false);
        return;
      }
      final chosen = choice.sites;
      // add() remplace par id → sert aussi à la mise à jour d'un compte existant.
      await ref.read(accountsProvider.notifier).add(
            account.copyWith(
              sites: chosen,
              allSites: chosen == null,
              excluded: choice.excluded,
            ),
            creds,
          );
      if (mounted) {
        showGlanceToast(
            context, _isEditing ? l10n.addSourceEdited : l10n.addSourceAdded);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final l10n = context.l10n;
    final fields = _fields();

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
                  Text(_isEditing ? l10n.accountMenuEdit : l10n.addSourceNewTitle,
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
                      child: Text(l10n.addSourceProvider, style: GT.label(color: p.fg2)),
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
                    GlanceReveal(
                      show: _kind == ProviderKind.umami,
                      child: _UmamiHosting(
                        cloud: _umamiCloud,
                        onChanged: (cloud) => setState(() {
                          _umamiCloud = cloud;
                          _error = null;
                          _testOk = null;
                        }),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  GlanceField(
                    label: l10n.addSourceName,
                    controller: _name,
                    hint: l10n.addSourceNameHint,
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
                  GlanceReveal(
                    show: _error != null,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 16, color: p.neg),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error ?? '',
                                style: GT.body(13, color: p.neg)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GlanceReveal(
                    show: _testOk != null,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              size: 16, color: p.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_testOk ?? '',
                                style: GT.body(13, color: p.accent)),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                    label: l10n.addSourceTest,
                    busy: _testing,
                    leading: Icon(Icons.wifi_tethering_rounded,
                        size: 17, color: p.fg),
                    onTap: _test,
                  ),
                  const SizedBox(height: 10),
                  GlanceButton(
                    label: _isEditing ? l10n.commonSave : l10n.addSourceContinue,
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

/// Umami Cloud ou instance auto-hébergée : la première se connecte avec une
/// clé API, la seconde avec un identifiant et un mot de passe.
class _UmamiHosting extends StatelessWidget {
  const _UmamiHosting({required this.cloud, required this.onChanged});

  final bool cloud;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final l10n = context.l10n;
    // Pleine largeur : `GlanceReveal` centre un enfant plus étroit que lui.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 3, bottom: 7),
            child:
                Text(l10n.addSourceUmamiHosting, style: GT.label(color: p.fg2)),
          ),
          ChipRow(
            children: [
              GlanceChip(
                label: l10n.addSourceUmamiSelfHosted,
                selected: !cloud,
                onTap: () => onChanged(false),
              ),
              GlanceChip(
                label: 'Umami Cloud',
                selected: cloud,
                onTap: () => onChanged(true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
