import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../widgets/common.dart';
import '../widgets/site_avatar.dart';
import '../widgets/field.dart';

/// Étape 2 de l'ajout : choix des sites à suivre.
///
/// Renvoie via Navigator.pop :
/// - `null` si annulé (retour arrière) ;
/// - une liste **vide** = « tous les sites » (le compte suivra automatiquement
///   les nouveaux sites aussi) ;
/// - une liste d'ids = sélection explicite.
class SitePickerScreen extends StatefulWidget {
  const SitePickerScreen({
    super.key,
    required this.providerName,
    required this.sites,
    this.initialSelection,
  });

  final String providerName;
  final List<Site> sites;

  /// null = tous ; sinon ids présélectionnés.
  final List<String>? initialSelection;

  @override
  State<SitePickerScreen> createState() => _SitePickerScreenState();
}

class _SitePickerScreenState extends State<SitePickerScreen> {
  late bool _all;
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _all = widget.initialSelection == null;
    _selected = {...?widget.initialSelection};
  }

  void _toggleAll() {
    setState(() {
      _all = !_all;
      if (_all) _selected.clear();
    });
  }

  void _toggle(String id) {
    setState(() {
      _all = false;
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  bool get _canConfirm => _all || _selected.isNotEmpty;

  void _confirm() {
    Navigator.of(context).pop<List<String>>(_all ? const [] : _selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final sites = widget.sites;
    final count = _all ? sites.length : _selected.length;

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
                  // Master « Tous les sites ».
                  GlanceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 14,
                    ),
                    selected: _all,
                    onTap: _toggleAll,
                    child: Row(
                      children: [
                        Icon(Icons.select_all_rounded, size: 22, color: p.accent),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tous les sites',
                                style: GT.body(15, weight: 500, color: p.fg),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Suit aussi les futurs sites',
                                style: GT.body(12, color: p.fg2),
                              ),
                            ],
                          ),
                        ),
                        _Check(on: _all),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.only(left: 3, bottom: 8),
                    child: SectionLabel('Ou choisir'),
                  ),
                  for (final s in sites) ...[
                    GlanceCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      selected: !_all && _selected.contains(s.id),
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
                          _Check(on: _all || _selected.contains(s.id)),
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
                label: count == 0
                    ? 'Sélectionne au moins un site'
                    : 'Suivre $count site${count > 1 ? 's' : ''}',
                onTap: _canConfirm ? _confirm : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: on ? p.accent : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: on ? p.accent : p.fg3, width: 2),
      ),
      child: on
          ? Icon(Icons.check_rounded, size: 15, color: p.accentInk)
          : null,
    );
  }
}
