import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/grid_layout.dart';
import '../../core/indicator_math.dart';
import '../../data/models/indicator.dart';
import '../../data/models/models.dart';
import '../../data/models/period.dart';
import '../../state/indicators.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../widgets/field.dart';
import '../widgets/motion.dart';
import '../../data/models/indicator_result.dart';
import 'dashboard_grid.dart';
import 'editor/indicator_editor.dart';
import 'indicator_card.dart';
import 'metrics_source_screen.dart';
import 'segments_body.dart';

/// Contenu de l'onglet Tableaux : les indicateurs du site, sur une grille
/// que « Organiser » permet d'arranger (déplacer, redimensionner). Une carte
/// chargée sans valeur à montrer est masquée (elle ne dit rien) ; une ligne en
/// bas permet de la retrouver.
class IndicatorsTab extends ConsumerStatefulWidget {
  const IndicatorsTab({super.key, required this.site, required this.window});

  final Site site;
  final DateWindow window;

  @override
  ConsumerState<IndicatorsTab> createState() => _IndicatorsTabState();
}

class _IndicatorsTabState extends ConsumerState<IndicatorsTab> {
  /// Les cartes vides ont été demandées : valable jusqu'au prochain changement
  /// de période.
  bool _revealed = false;

  /// Mode « Organiser » : toutes les cartes sont montrées, vides comprises,
  /// sinon leur place dans la grille serait perdue.
  bool _editing = false;

  @override
  void didUpdateWidget(IndicatorsTab old) {
    super.didUpdateWidget(old);
    if (old.window != widget.window) _revealed = false;
  }

  @override
  Widget build(BuildContext context) {
    final site = widget.site;
    final window = widget.window;
    final indicators = ref.watch(siteIndicatorsProvider(site));
    void create() => openIndicatorEditor(context, site);
    void openSource() => openMetricsSource(context, site);
    if (indicators.isEmpty) {
      return _EmptyState(onCreate: create, onSource: openSource);
    }

    // Même clé que celle de chaque carte : aucune requête de plus. Une erreur
    // ou un chargement en cours ne masque rien.
    final data = {
      for (final i in indicators)
        i.id: ref.watch(indicatorDataProvider((site, window, i))).value,
    };
    final empty = {
      for (final e in data.entries)
        if (e.value case final d? when !hasDisplayableData(d)) e.key,
    };
    final segmented = {
      for (final e in data.entries)
        if (e.value case final CounterData d when hasSegmentData(d)) e.key,
    };
    final shown = _revealed || _editing
        ? indicators
        : [for (final i in indicators) if (!empty.contains(i.id)) i];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ArrangeBar(
            editing: _editing,
            onToggle: () => setState(() => _editing = !_editing),
          ),
          if (shown.isEmpty)
            const _AllHidden()
          else
            _Grid(
              site: site,
              window: window,
              indicators: indicators,
              shown: {for (final i in shown) i.id},
              segmented: segmented,
              editing: _editing,
            ),
          if (!_revealed && !_editing && empty.isNotEmpty)
            _HiddenLink(
              count: empty.length,
              onTap: () => setState(() => _revealed = true),
            ),
          const SizedBox(height: 18),
          GlanceButtonOutline(
            label: 'Nouveau tableau',
            leading: Icon(Icons.add_rounded, size: 18, color: context.glance.fg),
            onTap: create,
          ),
          const SizedBox(height: 14),
          _SourceLink(onTap: openSource),
        ],
      ),
    );
  }
}

class _AllHidden extends StatelessWidget {
  const _AllHidden();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Text(
          'Aucun tableau n\'a de données sur cette période',
          textAlign: TextAlign.center,
          style: GT.body(14, color: context.glance.fg2),
        ),
      );
}

/// « 3 tableaux sans données sur cette période · Afficher ».
class _HiddenLink extends StatelessWidget {
  const _HiddenLink({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final what = count == 1 ? '1 tableau sans données' : '$count tableaux sans données';
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Text.rich(
          TextSpan(
            style: GT.body(12.5, color: p.fg3),
            children: [
              TextSpan(text: '$what sur cette période · '),
              TextSpan(
                text: 'Afficher',
                style: GT.body(12.5, weight: 600, color: p.accent),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// « Organiser » à droite, au-dessus des cartes ; en édition, la consigne et
/// « Terminé ».
class _ArrangeBar extends StatelessWidget {
  const _ArrangeBar({required this.editing, required this.onToggle});
  final bool editing;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final color = editing ? p.accent : p.fg2;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: GlanceReveal(
              show: editing,
              // GlanceReveal s'ancre au centre : la consigne reste à gauche.
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Maintenez une carte pour la déplacer, tirez son coin pour la '
                  'redimensionner.',
                  style: GT.body(12.5, color: p.fg3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    editing
                        ? Icons.check_rounded
                        : Icons.dashboard_customize_outlined,
                    size: 17,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    editing ? 'Terminé' : 'Organiser',
                    style: GT.body(13, weight: 600, color: color),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Largeur d'une carte avant la grille : en deçà, les colonnes de chiffres
/// d'un entonnoir ne tiennent plus à côté de son libellé. Elle fixe le nombre
/// de colonnes : deux par carte de cette largeur, pour pouvoir aussi en poser
/// deux plus étroites côte à côte.
const double _kCardWidth = 270;
const int _kMaxCards = 3;
const int _kColumnsPerCard = 2;

int _columnsFor(double width) =>
    ((width + kGridGutter) / (_kCardWidth + kGridGutter))
        .floor()
        .clamp(1, _kMaxCards) *
    _kColumnsPerCard;

/// Taille d'une carte encore jamais placée : la largeur d'une carte d'avant la
/// grille, et une hauteur qui montre son contenu habituel. [segmented] : un
/// compteur découpé par plateforme (légende, courbes et parts).
GridItem _gridItemFor(Indicator i, int columns, {required bool segmented}) =>
    switch (i) {
      _ when segmented =>
        GridItem(i.id, w: _kColumnsPerCard, h: 11, minH: 3),
      // Une répartition dans le temps a besoin de largeur pour sa courbe.
      BreakdownIndicator(overTime: true) => GridItem(i.id,
          w: columns, h: 12, minW: _kColumnsPerCard, minH: 6),
      BreakdownIndicator() =>
        GridItem(i.id, w: _kColumnsPerCard, h: 8, minW: _kColumnsPerCard, minH: 4),
      // Le chiffre, puis une quarantaine de pixels par étape.
      FunnelIndicator(:final steps) => GridItem(i.id,
          w: _kColumnsPerCard,
          h: ((150 + 38 * steps.length) / (kGridRow + kGridGutter)).ceil(),
          minW: _kColumnsPerCard,
          minH: 4),
      _ => GridItem(i.id, w: _kColumnsPerCard, h: 5, minH: 3),
    };

class _Grid extends ConsumerWidget {
  const _Grid({
    required this.site,
    required this.window,
    required this.indicators,
    required this.shown,
    required this.segmented,
    required this.editing,
  });

  final Site site;
  final DateWindow window;

  /// Toutes les cartes du site : la grille se calcule sur toutes, puis les
  /// cartes masquées en sont retirées.
  final List<Indicator> indicators;
  final Set<String> shown;
  final Set<String> segmented;
  final bool editing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layouts = ref.watch(siteLayoutsProvider(site));
    final byId = {for (final i in indicators) i.id: i};
    // La largeur vient des contraintes, jamais de la taille de l'écran (cf.
    // MetricSectionGrid : le panneau central du bureau est plus étroit que la
    // fenêtre).
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(constraints.maxWidth);
        final items = [
          for (final i in indicators)
            _gridItemFor(i, columns, segmented: segmented.contains(i.id)),
        ];
        final full = resolveLayout(layouts[columns], items, columns);
        // Une carte masquée laisse remonter celles d'en dessous.
        final layout = shown.length == indicators.length
            ? full
            : settleLayout({
                for (final e in full.entries)
                  if (shown.contains(e.key)) e.key: e.value,
              });
        return DashboardGrid(
          columns: columns,
          items: {for (final i in items) i.id: i},
          layout: layout,
          editing: editing,
          onChanged: (next) => ref
              .read(indicatorsProvider.notifier)
              .setLayout(site, columns, next),
          cardBuilder: (id) => IndicatorCard(
            site: site,
            window: window,
            indicator: byId[id]!,
            fill: true,
            editing: editing,
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate, required this.onSource});
  final VoidCallback onCreate;
  final VoidCallback onSource;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
      child: Column(
        children: [
          Icon(Icons.dashboard_outlined, size: 34, color: p.fg3),
          const SizedBox(height: 12),
          Text('Aucun tableau', style: GT.body(15, color: p.fg2)),
          const SizedBox(height: 6),
          Text(
            'Suivez un taux, un entonnoir ou une répartition construits sur vos événements.',
            textAlign: TextAlign.center,
            style: GT.body(13, color: p.fg3),
          ),
          const SizedBox(height: 22),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: GlanceButton(label: 'Créer un tableau', onTap: onCreate),
          ),
          const SizedBox(height: 16),
          _SourceLink(onTap: onSource),
        ],
      ),
    );
  }
}

/// Action secondaire : brancher l'API d'agrégats du site.
class _SourceLink extends StatelessWidget {
  const _SourceLink({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hub_outlined, size: 16, color: p.fg2),
            const SizedBox(width: 8),
            Text('Source de métriques',
                style: GT.body(13, weight: 600, color: p.fg2)),
          ],
        ),
      ),
    );
  }
}
