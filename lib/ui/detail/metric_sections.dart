import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/internal_traffic.dart';
import '../../data/models/dimension.dart';
import '../../data/models/models.dart';
import '../../data/models/period.dart';
import '../../state/internal_traffic.dart';
import '../../state/metric_sections.dart';
import '../../state/providers.dart';
import '../../theme/motion.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

/// Lignes affichées par carte. Au-delà, la carte deviendrait une liste, pas un
/// aperçu — le reste se lit dans l'outil d'origine.
const int kSectionRows = 8;

/// Les quatre panneaux de données d'un site, disposés en colonnes selon la
/// place disponible.
///
/// Colonnes-seaux plutôt qu'une grille : les cartes n'ont pas toutes le même
/// contenu, et une grille imposerait à chaque rangée la hauteur de sa plus
/// haute carte. Ici chaque colonne empile ses cartes, donc rien ne s'étire et
/// aucun trou ne se creuse.
class MetricSectionGrid extends StatelessWidget {
  const MetricSectionGrid({
    super.key,
    required this.site,
    required this.window,
    required this.visitors,
  });

  final Site site;
  final DateWindow window;

  /// Univers auquel rapporter les pourcentages.
  final int visitors;

  /// Largeur en deçà de laquelle une carte ne tient plus ses deux colonnes de
  /// chiffres à côté d'un chemin.
  static const double _minCard = 290;
  static const double _gutter = 14;
  static const int _maxColumns = 3;

  @override
  Widget build(BuildContext context) {
    final sections = MetricSection.values;
    // La largeur vient des contraintes, jamais de la taille de l'écran : le
    // panneau central du bureau est plus étroit que la fenêtre, et franchir le
    // seuil du mode bureau fait apparaître une barre latérale de 320 px.
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ((constraints.maxWidth + _gutter) / (_minCard + _gutter))
            .floor()
            .clamp(1, _maxColumns);

        Widget card(MetricSection s) => MetricSectionCard(
              key: ValueKey(s),
              section: s,
              site: site,
              window: window,
              visitors: visitors,
            );

        if (columns == 1) {
          return Column(
            children: [
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0) const SizedBox(height: _gutter),
                card(sections[i]),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var col = 0; col < columns; col++) ...[
              if (col > 0) const SizedBox(width: _gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = col; i < sections.length; i += columns) ...[
                      if (i > col) const SizedBox(height: _gutter),
                      card(sections[i]),
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

/// Une carte de données : un titre, un sélecteur de sous-dimension, et les
/// lignes correspondantes.
class MetricSectionCard extends ConsumerStatefulWidget {
  const MetricSectionCard({
    super.key,
    required this.section,
    required this.site,
    required this.window,
    required this.visitors,
  });

  final MetricSection section;
  final Site site;
  final DateWindow window;
  final int visitors;

  @override
  ConsumerState<MetricSectionCard> createState() => _MetricSectionCardState();
}

class _MetricSectionCardState extends ConsumerState<MetricSectionCard> {
  // Dernières lignes affichées, par fenêtre ET par dimension : un rechargement
  // en fond garde l'affichage précédent au lieu de repasser par un squelette.
  // La fenêtre fait partie de la clé, sinon changer de période afficherait les
  // chiffres de la précédente sous le nouveau libellé.
  final Map<(DateWindow, MetricType), List<MetricRow>> _last = {};

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final dim = ref.watch(metricSectionsProvider)[widget.section]!;
    final async =
        ref.watch(siteMetricProvider((widget.site, widget.window, dim)));
    final memo = (widget.window, dim);
    if (async.hasValue) _last[memo] = async.value!;
    final rows = async.value ??
        ref.watch(cachedMetricProvider((widget.site, widget.window, dim))) ??
        _last[memo];

    return GlanceCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            section: widget.section,
            current: dim,
            onPick: (t) =>
                ref.read(metricSectionsProvider.notifier).select(widget.section, t),
          ),
          const SizedBox(height: 4),
          // La hauteur est réservée par `reserveRows`, donc le changement de
          // sous-dimension ne fait pas sauter la colonne ; l'AnimatedSize reste
          // en filet pour l'état d'erreur.
          ClipRect(
            child: AnimatedSize(
              duration: kMotionBase,
              curve: kCurveOutCubic,
              alignment: Alignment.topCenter,
              child: GlanceSwap(
                dy: 0,
                child: KeyedSubtree(
                  key: ValueKey((dim, rows == null)),
                  child: rows == null
                      ? (async.hasError
                          ? _SectionError(
                              onRetry: () => ref.invalidate(siteMetricProvider(
                                  (widget.site, widget.window, dim))),
                            )
                          : const _SectionSkeleton())
                      : _SectionRows(
                          rows: rows,
                          dim: dim,
                          site: widget.site,
                          visitors: widget.visitors,
                        ),
                ),
              ),
            ),
          ),
          if (rows != null && rows.length > kSectionRows)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: GestureDetector(
                onTap: () => _openAll(context, dim, rows),
                behavior: HitTestBehavior.opaque,
                child: Text(
                  'Voir les ${rows.length} lignes',
                  style: GT.body(12.5, weight: 500, color: p.accent),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openAll(BuildContext context, MetricType dim, List<MetricRow> rows) {
    final p = context.glance;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          children: [
            Text(
              '${widget.section.label} · ${dim.label}',
              style: GT.display(22, color: ctx.glance.fg),
            ),
            const SizedBox(height: 14),
            _SectionRows(
              rows: rows,
              dim: dim,
              site: widget.site,
              visitors: widget.visitors,
              limit: rows.length,
            ),
          ],
        ),
      ),
    );
  }
}

/// Lignes d'une dimension, avec leur icône, leur part et le repérage des sites
/// qu'on suit déjà.
class _SectionRows extends ConsumerWidget {
  const _SectionRows({
    required this.rows,
    required this.dim,
    required this.site,
    required this.visitors,
    this.limit = kSectionRows,
  });

  final List<MetricRow> rows;
  final MetricType dim;
  final Site site;
  final int visitors;
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final known = dim == MetricType.referrers
        ? ref.watch(knownDomainsProvider)
        : const <String>{};
    final self = normDomain(site.domain);

    return MetricBars(
      rows: [
        for (final r in rows.take(limit))
          MetricBarRow(
            label: r.label,
            value: r.value,
            code: r.code,
            icon: dim.iconKind,
            // Referrer venant d'un de vos propres sites suivis.
            badge: dim == MetricType.referrers &&
                    r.code != null &&
                    known.contains(normDomain(r.code!)) &&
                    normDomain(r.code!) != self
                ? 'INTERNE'
                : null,
          ),
      ],
      mono: dim.isMono,
      total: visitors,
      accountId: site.accountId,
      reserveRows: limit == kSectionRows ? kSectionRows : 0,
    );
  }
}

/// Titre + sélecteur de sous-dimension.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.section,
    required this.current,
    required this.onPick,
  });

  final MetricSection section;
  final MetricType current;
  final ValueChanged<MetricType> onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    // Le sélecteur prend sa propre ligne : à côté du titre, quatre libellés ne
    // tiennent pas sur un téléphone et le premier — celui qui est actif —
    // partirait hors champ.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(section.label),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final t in section.dimensions)
                GestureDetector(
                  onTap: () => onPick(t),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: kMotionFast,
                    curve: kCurveOut,
                    margin: const EdgeInsets.only(right: 5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: t == current ? p.accentSoft : p.chip,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      t.label,
                      style: GT.mono(
                        10.5,
                        weight: t == current ? 600 : 400,
                        color: t == current ? p.accent : p.fg2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return SizedBox(
      height: kSectionRows * kMetricRowHeight,
      child: Column(
        children: [
          for (var i = 0; i < kSectionRows; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: 90 + (i % 3) * 40,
                    decoration: BoxDecoration(
                      color: p.chip,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: p.chip,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          Text('Chargement impossible.', style: GT.body(13, color: p.fg2)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Réessayer',
              style: GT.body(13, weight: 600, color: p.accent),
            ),
          ),
        ],
      ),
    );
  }
}
