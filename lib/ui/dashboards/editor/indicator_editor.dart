import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/indicator.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/analytics_provider.dart';
import '../../../state/indicators.dart';
import '../../../state/period_state.dart';
import '../../../state/providers.dart';
import '../../../theme/palette.dart';
import '../../../theme/type.dart';
import '../../root_scaffold.dart';
import '../../widgets/common.dart';
import '../../widgets/field.dart';
import '../../widgets/motion.dart';
import '../../widgets/toast.dart';
import '../indicator_card.dart';
import 'confirm_button.dart';
import 'draft.dart';
import 'funnel_steps.dart';
import 'kind_picker.dart';
import 'pickers.dart';
import 'query_editor.dart';

/// Délai de silence avant de recalculer l'aperçu : chaque recalcul est une
/// requête à l'instance de statistiques, et taper un nom d'événement en
/// déclencherait une par lettre.
const Duration kPreviewDebounce = Duration(milliseconds: 600);

const double kFooterButton = 52;

/// Ligne de raison de validation (13 pt, une à deux lignes) et son espacement.
const double kFooterReason = 44;

/// Id de l'aperçu : fixe, pour que seul le contenu de l'indicateur change la
/// clé de `indicatorDataProvider` (et jamais l'id tiré à chaque frappe).
const String _previewId = 'apercu';

/// Ouvre l'éditeur d'un tableau (modale sur desktop, page sur mobile).
/// [initial] à `null` = création.
Future<void> openIndicatorEditor(
  BuildContext context,
  Site site, {
  Indicator? initial,
}) =>
    showGlanceModal<void>(context, IndicatorEditor(site: site, initial: initial));

class IndicatorEditor extends ConsumerStatefulWidget {
  const IndicatorEditor({super.key, required this.site, this.initial});

  final Site site;
  final Indicator? initial;

  @override
  ConsumerState<IndicatorEditor> createState() => _IndicatorEditorState();
}

class _IndicatorEditorState extends ConsumerState<IndicatorEditor> {
  late IndicatorDraft _draft;
  late final TextEditingController _name;
  late final TextEditingController _window;
  Indicator? _preview;
  Timer? _debounce;

  bool get _isNew => widget.initial == null;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial == null
        ? const IndicatorDraft()
        : IndicatorDraft.fromIndicator(widget.initial!);
    _name = TextEditingController(text: _draft.name);
    _window = TextEditingController(text: _draft.windowText);
    _preview = _previewOf(_draft);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _window.dispose();
    super.dispose();
  }

  /// Le nom ne fait pas partie de l'aperçu : le taper ne doit pas relancer de
  /// requête, la carte montre le nom suggéré (qui ne dépend que du contenu).
  static Indicator? _previewOf(IndicatorDraft d) =>
      d.copyWith(name: '').toIndicator(_previewId);

  void _update(IndicatorDraft next) {
    setState(() => _draft = next);
    _debounce?.cancel();
    final preview = _previewOf(next);
    if (preview == null) {
      setState(() => _preview = null);
      return;
    }
    _debounce = Timer(kPreviewDebounce, () {
      if (mounted) setState(() => _preview = preview);
    });
  }

  Future<void> _save() async {
    final id = widget.initial?.id ?? IndicatorsNotifier.newId();
    final indicator = _draft.toIndicator(id)!;
    final notifier = ref.read(indicatorsProvider.notifier);
    if (_isNew) {
      await notifier.add(widget.site, indicator);
    } else {
      await notifier.update(widget.site, indicator);
    }
    if (!mounted) return;
    showGlanceToast(context, _isNew ? 'Tableau créé' : 'Tableau enregistré');
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref
        .read(indicatorsProvider.notifier)
        .remove(widget.site, widget.initial!.id);
    if (!mounted) return;
    showGlanceToast(context, 'Tableau supprimé', kind: ToastKind.info);
    Navigator.of(context).pop();
  }

  /// Hauteur du pied fixe : bouton, raison de validation, marges et zone sûre.
  /// Le bas de la liste doit au moins la valoir, sinon le dernier bouton
  /// (« Supprimer ») reste sous le pied une fois tout défilé.
  static double _footerHeight(BuildContext context) =>
      kFooterButton + kFooterReason + 20 + MediaQuery.of(context).padding.bottom;

  List<IndicatorKind> _kinds() {
    final accounts = ref.watch(accountsProvider);
    final account = accounts.firstWhere((a) => a.id == widget.site.accountId);
    final supported = supportedIndicatorsFor(account.kind);
    return [
      for (final k in IndicatorKind.values)
        if (supported.contains(k)) k,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final error = _draft.validationError();
    final bottom = MediaQuery.of(context).padding.bottom;

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
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isNew ? 'Nouveau tableau' : 'Modifier le tableau',
                      style: GT.display(24, color: p.fg),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, 0, 20, _footerHeight(context) + 24),
                children: [
                  GlanceField(
                    label: 'Nom',
                    controller: _name,
                    hint: _draft.suggestedName(),
                    onChanged: (v) => _update(_draft.copyWith(name: v)),
                  ),
                  const SizedBox(height: 22),
                  const _Heading('Type'),
                  KindPicker(
                    kinds: _kinds(),
                    selected: _draft.kind,
                    onChanged: (k) => _update(_draft.withKind(k)),
                  ),
                  const SizedBox(height: 14),
                  GlanceSwap(
                    child: KeyedSubtree(
                      key: ValueKey(_draft.kind),
                      child: _kindForm(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _Heading('Aperçu'),
                  _PreviewCard(
                    site: widget.site,
                    indicator: _preview,
                    // Le nom n'entre pas dans la clé de l'aperçu (cf.
                    // _previewOf) : il ne s'affiche qu'en en-tête.
                    title: _draft.name.trim().isEmpty
                        ? _draft.suggestedName()
                        : _draft.name.trim(),
                  ),
                  if (!_isNew) ...[
                    const SizedBox(height: 28),
                    ConfirmButton(
                      label: 'Supprimer ce tableau',
                      confirmLabel: 'Confirmer la suppression',
                      onConfirmed: _delete,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlanceReveal(
                    show: error != null,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 3),
                      child: Text(error ?? '', style: GT.body(13, color: p.neg)),
                    ),
                  ),
                  GlanceButton(
                    label: _isNew ? 'Créer' : 'Enregistrer',
                    onTap: error == null ? _save : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kindForm() {
    final site = widget.site;
    return switch (_draft.kind) {
      IndicatorKind.counter => QueryEditor(
          site: site,
          query: _draft.query,
          onChanged: (q) => _update(_draft.copyWith(query: q)),
        ),
      IndicatorKind.ratio => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            QueryEditor(
              site: site,
              label: 'Ce qu\'on compte',
              query: _draft.query,
              onChanged: (q) => _update(_draft.copyWith(query: q)),
            ),
            const SizedBox(height: 18),
            QueryEditor(
              site: site,
              label: 'Rapporté à',
              query: _draft.denominator,
              onChanged: (q) => _update(_draft.copyWith(denominator: q)),
            ),
            const SizedBox(height: 18),
            _gapsRow(),
          ],
        ),
      IndicatorKind.funnel => FunnelStepsEditor(
          site: site,
          steps: _draft.steps,
          window: _window,
          onSteps: (s) => _update(_draft.copyWith(steps: s)),
          onWindow: (t) => _update(_draft.copyWith(windowText: t)),
        ),
      IndicatorKind.breakdown => _breakdownForm(site),
    };
  }

  Widget _gapsRow() {
    final p = context.glance;
    return GestureDetector(
      onTap: () => _update(
          _draft.copyWith(gapsWhenEmpty: !_draft.gapsWhenEmpty)),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlanceCheck(on: _draft.gapsWhenEmpty),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Laisser un trou quand rien ne s\'est passé',
                    style: GT.body(14, color: p.fg)),
                const SizedBox(height: 2),
                Text('Sinon, ces jours-là comptent pour 0 %.',
                    style: GT.body(12.5, color: p.fg3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdownForm(Site site) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PickerField(
            label: 'Événement',
            placeholder: 'Choisir un événement',
            value: _draft.breakdownEvent,
            onTap: () async {
              final e = await pickEvent(context, site);
              if (e == null || e == _draft.breakdownEvent) return;
              // La propriété appartient à l'ancien événement.
              _update(_draft.copyWith(breakdownEvent: e, breakdownProperty: ''));
            },
          ),
          const SizedBox(height: 14),
          PickerField(
            label: 'Propriété',
            placeholder: 'Choisir une propriété',
            value: _draft.breakdownProperty,
            enabled: _draft.breakdownEvent.isNotEmpty,
            onTap: () async {
              final prop = await pickProperty(context, site, _draft.breakdownEvent);
              if (prop != null) _update(_draft.copyWith(breakdownProperty: prop.name));
            },
          ),
        ],
      );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 3, bottom: 8),
        child: SectionLabel(text),
      );
}

/// L'indicateur tel qu'il apparaîtra dans l'onglet, sur la période affichée.
class _PreviewCard extends ConsumerWidget {
  const _PreviewCard({
    required this.site,
    required this.indicator,
    required this.title,
  });

  final Site site;
  final Indicator? indicator;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(windowProvider);
    final i = indicator;
    if (i == null || window == null) {
      return Text(
        'L\'aperçu apparaît dès que le tableau est complet.',
        style: GT.body(13, color: context.glance.fg3),
      );
    }
    return IndicatorCard(
      site: site,
      window: window,
      indicator: i,
      title: title,
      menu: false,
    );
  }
}
