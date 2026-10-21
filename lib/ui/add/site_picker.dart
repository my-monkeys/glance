import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../widgets/common.dart';
import '../widgets/site_avatar.dart';
import '../widgets/field.dart';

/// Résultat du choix des sites (pop du picker). Un pop **sans valeur** (`null`)
/// = annulé. Un [SiteChoice] = confirmé, où [sites] encode les trois cas gérés
/// par [Account] : `null` = tous les sites sauf [excluded] (suit aussi les
/// futurs), `[]` = **aucun** (rien n'est affiché), `[ids]` = sélection
/// explicite.
@immutable
class SiteChoice {
  const SiteChoice(List<String> this.sites) : excluded = const [];
  const SiteChoice.all({this.excluded = const []}) : sites = null;
  final List<String>? sites;
  final List<String> excluded;
}

/// Étape 2 de l'ajout : choix des sites à suivre. Renvoie un [SiteChoice] via
/// Navigator.pop (ou `null` si annulé).
///
/// Deux réglages indépendants : les sites cochés aujourd'hui, et « Afficher les
/// nouveaux sites ». Activé, la sélection s'enregistre comme une **exclusion**
/// (les décochés), pour qu'un site créé plus tard apparaisse sans repasser ici.
class SitePickerScreen extends StatefulWidget {
  const SitePickerScreen({
    super.key,
    required this.providerName,
    required this.sites,
    this.initialSelection,
    this.initialExcluded = const [],
  });

  final String providerName;
  final List<Site> sites;

  /// null = tous sauf [initialExcluded] ; sinon ids présélectionnés.
  final List<String>? initialSelection;
  final List<String> initialExcluded;

  @override
  State<SitePickerScreen> createState() => _SitePickerScreenState();
}

class _SitePickerScreenState extends State<SitePickerScreen> {
  late bool _followNew;
  late final Set<String> _checked;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSelection;
    // Une liste explicite qui couvre tous les sites vient presque toujours de
    // l'ancien écran, où décocher puis recocher un site perdait le suivi des
    // nouveaux : on la rouvre en « tous », que la confirmation enregistre.
    _followNew = initial == null ||
        (widget.sites.isNotEmpty &&
            widget.sites.every((s) => initial.contains(s.id)));
    final excluded = widget.initialExcluded.toSet();
    _checked = initial != null
        ? {...initial}
        : {
            for (final s in widget.sites)
              if (!excluded.contains(s.id)) s.id,
          };
  }

  bool get _allChecked => widget.sites.every((s) => _checked.contains(s.id));

  void _toggleAll() {
    setState(() {
      if (_allChecked) {
        _checked.clear();
      } else {
        _checked.addAll(widget.sites.map((s) => s.id));
      }
    });
  }

  void _toggle(String id) {
    setState(() {
      if (!_checked.remove(id)) _checked.add(id);
    });
  }

  void _confirm() {
    final choice = _followNew
        ? SiteChoice.all(excluded: [
            for (final s in widget.sites)
              if (!_checked.contains(s.id)) s.id,
          ])
        : SiteChoice([
            for (final s in widget.sites)
              if (_checked.contains(s.id)) s.id,
          ]);
    Navigator.of(context).pop<SiteChoice>(choice);
  }

  String get _confirmLabel {
    final n = widget.sites.where((s) => _checked.contains(s.id)).length;
    final sites = '$n site${n > 1 ? 's' : ''}';
    if (_followNew) {
      return _allChecked ? 'Suivre tous les sites' : 'Suivre $sites et les nouveaux';
    }
    // Zéro site est un choix valide (masquer ce compte).
    return n == 0 ? 'N\'afficher aucun site' : 'Suivre $sites';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final sites = widget.sites;

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
                        Text('Choix des sites', style: GT.display(26, color: p.fg)),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.providerName} · ${sites.length} site${sites.length > 1 ? 's' : ''} détecté${sites.length > 1 ? 's' : ''}',
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
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  GlanceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 14,
                    ),
                    selected: _followNew,
                    onTap: () => setState(() => _followNew = !_followNew),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 22, color: p.accent),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Afficher les nouveaux sites',
                                style: GT.body(15, weight: 500, color: p.fg),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Un site créé plus tard apparaît tout seul',
                                style: GT.body(12, color: p.fg2),
                              ),
                            ],
                          ),
                        ),
                        GlanceCheck(on: _followNew),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.only(left: 3, right: 3, bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: SectionLabel('Sites actuels')),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _toggleAll,
                          child: Text(
                            _allChecked ? 'Tout décocher' : 'Tout cocher',
                            style: GT.body(13, weight: 500, color: p.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final s in sites) ...[
                    GlanceCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      selected: _checked.contains(s.id),
                      onTap: () => _toggle(s.id),
                      child: Row(
                        children: [
                          SiteAvatar(s, size: 34),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GT.body(15, weight: 500, color: p.fg),
                                ),
                                if (s.domain.isNotEmpty &&
                                    s.domain != s.name) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    s.domain,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GT.mono(11, color: p.fg2),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          GlanceCheck(on: _checked.contains(s.id)),
                        ],
                      ),
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
                label: _confirmLabel,
                onTap: _confirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

