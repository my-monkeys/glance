import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/indicator_math.dart';
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
/// colonnes selon la place. Une carte chargée sans valeur à montrer est
/// masquée (elle ne dit rien) ; une ligne en bas permet de la retrouver.
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
    final empty = {
      for (final i in indicators)
        if (ref.watch(indicatorDataProvider((site, window, i))).value
            case final data? when !hasDisplayableData(data))
          i.id,
    };
    final shown = _revealed
        ? indicators
        : [for (final i in indicators) if (!empty.contains(i.id)) i];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (shown.isEmpty)
            const _AllHidden()
          else
            _CardsGrid(site: site, window: window, indicators: shown),
          if (!_revealed && empty.isNotEmpty)
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

        Widget card(Indicator i) => IndicatorCard(
              // L'id suffit : le déplacement d'une carte d'une colonne à
              // l'autre doit la déplacer, pas la reconstruire.
              key: ValueKey(i.id),
              site: site,
              window: window,
              indicator: i,
            );

        // Une carte large coupe la grille : les cartes normales d'avant et
        // d'après se répartissent chacune en colonnes, de leur côté.
        final children = <Widget>[];
        var run = <Indicator>[];
        void flush() {
          if (run.isEmpty) return;
          children.add(_Columns(
            columns: columns,
            gutter: _gutter,
            cards: [for (final i in run) card(i)],
          ));
          run = [];
        }

        for (final i in indicators) {
          if (columns > 1 && _isWide(i)) {
            flush();
            children.add(card(i));
          } else {
            run.add(i);
          }
        }
        flush();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (n, w) in children.indexed) ...[
              if (n > 0) const SizedBox(height: _gutter),
              w,
            ],
          ],
        );
      },
    );
  }

  /// Une répartition dans le temps a besoin de largeur pour sa courbe.
  static bool _isWide(Indicator i) => i is BreakdownIndicator && i.overTime;
}

/// Cartes réparties en colonnes, rangée après rangée (0 à gauche, 1 à droite…).
class _Columns extends StatelessWidget {
  const _Columns({
    required this.columns,
    required this.gutter,
    required this.cards,
  });

  final int columns;
  final double gutter;
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var col = 0; col < columns; col++) ...[
            if (col > 0) SizedBox(width: gutter),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = col; i < cards.length; i += columns) ...[
                    if (i > col) SizedBox(height: gutter),
                    cards[i],
                  ],
                ],
              ),
            ),
          ],
        ],
      );
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
