import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/indicator.dart';
import '../../data/models/models.dart';
import '../../data/models/period.dart';
import '../../state/indicators.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../widgets/field.dart';
import 'editor/indicator_editor.dart';
import 'indicator_card.dart';
import 'metrics_source_screen.dart';

/// Contenu de l'onglet Tableaux : les indicateurs du site, en une ou deux
/// colonnes selon la place.
class IndicatorsTab extends ConsumerWidget {
  const IndicatorsTab({super.key, required this.site, required this.window});

  final Site site;
  final DateWindow window;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indicators = ref.watch(siteIndicatorsProvider(site));
    void create() => openIndicatorEditor(context, site);
    void openSource() => openMetricsSource(context, site);
    if (indicators.isEmpty) {
      return _EmptyState(onCreate: create, onSource: openSource);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardsGrid(site: site, window: window, indicators: indicators),
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

class _CardsGrid extends StatelessWidget {
  const _CardsGrid({
    required this.site,
    required this.window,
    required this.indicators,
  });

  final Site site;
  final DateWindow window;
  final List<Indicator> indicators;

  /// Largeur minimale d'une carte : en deçà, les colonnes de chiffres d'un
  /// entonnoir ne tiennent plus à côté de son libellé.
  static const double _minCard = 320;
  static const double _gutter = 14;
  static const int _maxColumns = 2;

  @override
  Widget build(BuildContext context) {
    // La largeur vient des contraintes, jamais de la taille de l'écran (cf.
    // MetricSectionGrid : le panneau central du bureau est plus étroit que la
    // fenêtre).
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ((constraints.maxWidth + _gutter) / (_minCard + _gutter))
            .floor()
            .clamp(1, _maxColumns);

        Widget card(int i) => IndicatorCard(
              // L'id suffit : le déplacement d'une carte d'une colonne à
              // l'autre doit la déplacer, pas la reconstruire.
              key: ValueKey(indicators[i].id),
              site: site,
              window: window,
              indicator: indicators[i],
            );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var col = 0; col < columns; col++) ...[
              if (col > 0) const SizedBox(width: _gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = col; i < indicators.length; i += columns) ...[
                      if (i > col) const SizedBox(height: _gutter),
                      card(i),
                    ],
                  ],
                ),
              ),
            ],
          ],
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
