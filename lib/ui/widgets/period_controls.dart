import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/predict.dart';
import '../../data/models/period.dart';
import '../../state/period_state.dart';
import '../../state/settings.dart';
import '../../theme/motion.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import 'chip.dart';
import 'common.dart';

/// Barre de contrôles sous le titre : les périodes, et un bouton « Affichage »
/// qui ouvre le reste.
///
/// Les réglages du graphique — comparaison, découpage, courbe ou barres —
/// tenaient auparavant dans des boutons sans libellé posés à droite des
/// périodes, qu'ils recouvraient. Ils n'étaient ni lisibles (deux flèches ne
/// disent pas « comparer à la période précédente ») ni atteignables sans
/// faire défiler. Regroupés dans une feuille, ils ont la place de porter leur
/// nom et une phrase d'explication.
///
/// Quand la largeur disponible loge toutes les périodes ET les contrôles sans
/// défilement (bureau), tout tient sur une seule ligne ; sinon les contrôles
/// passent sur une seconde ligne (téléphone).
class PeriodControls extends ConsumerWidget {
  const PeriodControls({
    super.key,
    required this.onPickCustom,
    this.viewMode,
    this.onViewMode,
  });

  /// Ouvre le sélecteur de dates (période personnalisée).
  final VoidCallback onPickCustom;

  /// Bascule liste/grille — accueil seulement.
  final HomeViewMode? viewMode;
  final ValueChanged<HomeViewMode>? onViewMode;

  static const double _chipGap = 6;
  static const double _groupGap = 12;
  static const EdgeInsets _padding = EdgeInsets.fromLTRB(20, 0, 16, 0);

  /// Largeur du segmenté liste/grille : 2 icônes de 15 px, 8 px de marge de
  /// chaque côté, 2 px de cadre.
  static const double _viewSegmentsWidth = 2 * (15 + 16) + 4;
  static const double _viewSegmentsGap = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compare = ref.watch(periodProvider.select((s) => s.compare));
    final current = ref.watch(periodProvider.select((s) => s.period));

    final chips = ChipRow(
      children: [
        for (final per in Period.values)
          GlanceChip(
            label: per.label,
            selected: current == per,
            onTap: () => per == Period.custom
                ? onPickCustom()
                : ref.read(periodProvider.notifier).set(per),
          ),
      ],
    );
    final toggle = viewMode == null
        ? null
        : _ViewSegments(mode: viewMode!, onChanged: onViewMode!);

    // Mesuré sur le contenu réel (libellés, police, échelle de texte), pas sur
    // un seuil de fenêtre : le panneau central du bureau est plus étroit que
    // l'écran. On compte le pire cas du bouton, indice de comparaison inclus,
    // pour que l'allumer ne fasse jamais défiler les périodes.
    return LayoutBuilder(
      builder: (context, constraints) {
        final chipsWidth = Period.values.fold<double>(
                0, (w, per) => w + GlanceChip.widthOf(context, per.label)) +
            _chipGap * (Period.values.length - 1);
        final trailing = _DisplayButton.widthOf(context, withHint: true) +
            (toggle == null ? 0 : _viewSegmentsGap + _viewSegmentsWidth);
        final fitsOneRow =chipsWidth + _groupGap + trailing <=
            constraints.maxWidth - _padding.horizontal;

        final button = _DisplayButton(
          on: compare,
          hint: fitsOneRow && compare,
          onTap: () => _openSheet(context),
        );

        if (fitsOneRow) {
          return Padding(
            padding: _padding,
            child: Row(
              children: [
                Expanded(child: chips),
                const SizedBox(width: _groupGap),
                button,
                if (toggle != null) ...[
                  const SizedBox(width: _viewSegmentsGap),
                  toggle,
                ],
              ],
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: chips,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: _padding,
              child: Row(
                children: [
                  button,
                  // Un réglage qui change la lecture du graphique s'annonce,
                  // sinon la courbe grise de la période précédente apparaît
                  // sans explication. Sur la même ligne que le bouton : une
                  // ligne qui apparaît et disparaît ferait sauter tout l'écran.
                  // `Expanded` et non `Flexible` + `Spacer` : les deux se
                  // disputeraient la place restante et le texte se ferait
                  // tronquer alors qu'il y en a.
                  Expanded(
                    child: compare
                        ? const Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: _CompareHint(),
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (toggle != null) ...[
                    const SizedBox(width: _viewSegmentsGap),
                    toggle,
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.glance.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const _DisplaySheet(),
    );
  }
}

/// Annonce de la comparaison, sur la ligne du bouton « Affichage ».
class _CompareHint extends StatelessWidget {
  const _CompareHint();

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.compare_arrows_rounded, size: 13, color: p.accent),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            'vs période précédente',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GT.body(11.5, color: p.accent),
          ),
        ),
      ],
    );
  }
}

/// Bouton « Affichage », allumé quand un réglage change la lecture du graphe.
/// Avec [hint], il porte lui-même l'annonce de la comparaison (une seule
/// ligne : pas de place à côté de lui).
class _DisplayButton extends StatelessWidget {
  const _DisplayButton({required this.on, required this.onTap, this.hint = false});
  final bool on;
  final bool hint;
  final VoidCallback onTap;

  static const String _hintLabel = 'vs préc.';
  static const double _hPad = 10;
  static const double _iconWidth = 15 + 6;
  static const double _hintExtra = 8 + 13 + 4;

  static TextStyle _style(bool on) =>
      GT.mono(11, weight: on ? 600 : 400);

  static double _textWidth(BuildContext context, String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return tp.width;
  }

  /// Largeur du bouton ; [withHint] = pire cas, indice de comparaison inclus.
  static double widthOf(BuildContext context, {required bool withHint}) {
    final style = _style(true);
    return 2 * _hPad +
        _iconWidth +
        _textWidth(context, 'Affichage', style) +
        (withHint ? _hintExtra + _textWidth(context, _hintLabel, style) : 0);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final ink = on ? p.accentInk : p.fg2;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: kMotionFast,
        curve: kCurveOut,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: _hPad),
        decoration: BoxDecoration(
          color: on ? p.accent : p.chip,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, size: 15, color: ink),
            const SizedBox(width: 6),
            Text('Affichage',
                style: GT.mono(11, weight: on ? 600 : 400, color: ink)),
            if (hint) ...[
              const SizedBox(width: 8),
              Icon(Icons.compare_arrows_rounded, size: 13, color: ink),
              const SizedBox(width: 4),
              Text(_hintLabel, style: GT.mono(11, weight: 600, color: ink)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Comparaison, découpage et style de graphique.
class _DisplaySheet extends ConsumerWidget {
  const _DisplaySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final window = ref.watch(windowProvider);
    final units = window == null ? const <TimeUnit>[] : allowedUnits(window);
    final compare = ref.watch(periodProvider.select((s) => s.compare));
    final style = ref.watch(settingsProvider.select((s) => s.chartStyle));
    // Une période sans « avant » comparable (« Tout », une période
    // personnalisée trop large) n'offre pas la bascule.
    final canCompare = window != null && previousPeriodWindow(window) != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Affichage', style: GT.display(22, color: p.fg)),
            const SizedBox(height: 18),
            if (canCompare) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Comparer', style: GT.body(15, color: p.fg)),
                        const SizedBox(height: 2),
                        Text(
                          'Superpose la période précédente',
                          style: GT.body(12.5, color: p.fg3),
                        ),
                      ],
                    ),
                  ),
                  GlanceToggle(
                    value: compare,
                    onTap: () =>
                        ref.read(periodProvider.notifier).toggleCompare(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],
            if (units.length > 1) ...[
              Text('Découpage', style: GT.body(15, color: p.fg)),
              const SizedBox(height: 10),
              ChipRow(
                children: [
                  for (final u in units)
                    GlanceChip(
                      label: u.label,
                      selected: u == window!.unit,
                      onTap: () => ref.read(periodProvider.notifier).setUnit(u),
                    ),
                ],
              ),
              const SizedBox(height: 18),
            ],
            Text('Graphique', style: GT.body(15, color: p.fg)),
            const SizedBox(height: 10),
            ChipRow(
              children: [
                for (final s in ChartStyle.values)
                  GlanceChip(
                    label: s.label,
                    selected: s == style,
                    onTap: () =>
                        ref.read(settingsProvider.notifier).setChartStyle(s),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmenté liste / grille.
class _ViewSegments extends StatelessWidget {
  const _ViewSegments({required this.mode, required this.onChanged});
  final HomeViewMode mode;
  final ValueChanged<HomeViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: p.chip,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final v in HomeViewMode.values)
            GestureDetector(
              onTap: () => onChanged(v),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: kMotionFast,
                curve: kCurveOut,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: v == mode ? p.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: v == mode ? p.shadow : null,
                ),
                child: Icon(
                  v == HomeViewMode.list
                      ? Icons.view_agenda_outlined
                      : Icons.grid_view_rounded,
                  size: 15,
                  color: v == mode ? p.fg : p.fg2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
