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

/// Barre de contrôles sous le titre : les périodes sur toute la largeur, et un
/// bouton « Affichage » qui ouvre le reste.
///
/// Les réglages du graphique — comparaison, découpage, courbe ou barres —
/// tenaient auparavant dans des boutons sans libellé posés à droite des
/// périodes, qu'ils recouvraient. Ils n'étaient ni lisibles (deux flèches ne
/// disent pas « comparer à la période précédente ») ni atteignables sans
/// faire défiler. Regroupés dans une feuille, ils ont la place de porter leur
/// nom et une phrase d'explication.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final compare = ref.watch(periodProvider.select((s) => s.compare));
    final current = ref.watch(periodProvider.select((s) => s.period));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: ChipRow(
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
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
          child: Row(
            children: [
              _DisplayButton(
                on: compare,
                onTap: () => _openSheet(context),
              ),
              // Un réglage qui change la lecture du graphique s'annonce, sinon
              // la courbe grise de la période précédente apparaît sans
              // explication. Sur la même ligne que le bouton : une ligne qui
              // apparaît et disparaît ferait sauter tout l'écran.
              // `Expanded` et non `Flexible` + `Spacer` : les deux se
              // disputeraient la place restante et le texte se ferait tronquer
              // alors qu'il y en a.
              Expanded(
                child: compare
                    ? Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.compare_arrows_rounded,
                                size: 13, color: p.accent),
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
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              if (viewMode != null) ...[
                const SizedBox(width: 8),
                _ViewSegments(mode: viewMode!, onChanged: onViewMode!),
              ],
            ],
          ),
        ),
      ],
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

/// Bouton « Affichage », allumé quand un réglage change la lecture du graphe.
class _DisplayButton extends StatelessWidget {
  const _DisplayButton({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: kMotionFast,
        curve: kCurveOut,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: on ? p.accent : p.chip,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 15,
              color: on ? p.accentInk : p.fg2,
            ),
            const SizedBox(width: 6),
            Text(
              'Affichage',
              style: GT.mono(
                11,
                weight: on ? 600 : 400,
                color: on ? p.accentInk : p.fg2,
              ),
            ),
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
