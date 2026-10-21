import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/period.dart';
import '../../state/period_state.dart';
import '../../state/settings.dart';
import '../../theme/motion.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import 'chip.dart';

/// Barre de contrôles sous le titre : les périodes, et un bouton « Affichage »
/// qui ouvre le reste.
///
/// Les réglages du graphique — découpage, courbe ou barres — tenaient
/// auparavant dans des boutons sans libellé posés à droite des périodes, qu'ils
/// recouvraient. Ils n'étaient ni lisibles ni atteignables sans faire défiler.
/// Regroupés dans une feuille, ils ont la place de porter leur nom. La
/// comparaison n'y est plus : elle se coche dans la légende du graphique, à
/// côté des courbes qu'elle compare.
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
    // l'écran.
    return LayoutBuilder(
      builder: (context, constraints) {
        final chipsWidth = Period.values.fold<double>(
                0, (w, per) => w + GlanceChip.widthOf(context, per.label)) +
            _chipGap * (Period.values.length - 1);
        final room = constraints.maxWidth -
            _padding.horizontal -
            chipsWidth -
            _groupGap -
            (toggle == null ? 0 : _viewSegmentsGap + _viewSegmentsWidth);
        // Trois paliers : libellé complet, puis icône seule (le panneau
        // central du bureau rate souvent le libellé de quelques pixels), puis
        // deux lignes. Le libellé tient d'abord : c'est lui qui dit ce que
        // fait le bouton, l'infobulle ne le remplace que faute de place.
        final fitsOneRow =
            room >= _DisplayButton.widthOf(context, compact: true);
        final compact = room < _DisplayButton.widthOf(context, compact: false);

        final button = _DisplayButton(
          compact: fitsOneRow && compact,
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
                  const Spacer(),
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

/// Bouton « Affichage ». [compact] : icône seule, le libellé passe dans
/// l'infobulle.
class _DisplayButton extends StatelessWidget {
  const _DisplayButton({required this.onTap, this.compact = false});
  final bool compact;
  final VoidCallback onTap;

  static const String _label = 'Affichage';
  static const double _hPad = 10;
  static const double _iconWidth = 15;
  static const double _labelGap = 6;

  static TextStyle _style() => GT.mono(11);

  static double _textWidth(BuildContext context, String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return tp.width;
  }

  static double widthOf(BuildContext context, {required bool compact}) =>
      2 * _hPad +
      _iconWidth +
      (compact ? 0 : _labelGap + _textWidth(context, _label, _style()));

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final ink = p.fg2;
    final button = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: kMotionFast,
        curve: kCurveOut,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: _hPad),
        decoration: BoxDecoration(
          color: p.chip,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, size: _iconWidth, color: ink),
            if (!compact) ...[
              const SizedBox(width: _labelGap),
              Text(_label, style: GT.mono(11, color: ink)),
            ],
          ],
        ),
      ),
    );
    if (!compact) return button;
    return Tooltip(message: _label, child: button);
  }
}

/// Découpage et style de graphique.
class _DisplaySheet extends ConsumerWidget {
  const _DisplaySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final window = ref.watch(windowProvider);
    final units = window == null ? const <TimeUnit>[] : allowedUnits(window);
    final style = ref.watch(settingsProvider.select((s) => s.chartStyle));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Affichage', style: GT.display(22, color: p.fg)),
            const SizedBox(height: 18),
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
