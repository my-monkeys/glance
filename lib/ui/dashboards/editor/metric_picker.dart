import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/metrics_source.dart';
import '../../../data/models/models.dart';
import '../../../state/metrics_sources.dart';
import '../../../theme/palette.dart';
import '../../../theme/type.dart';
import '../labels.dart';
import 'pickers.dart';

/// Choisit un indicateur parmi le catalogue de la source du site.
Future<MetricDef?> pickMetric(BuildContext context, Site site) =>
    showGlanceSheet<MetricDef>(context, (_) => _MetricSheet(site: site));

class _MetricSheet extends ConsumerWidget {
  const _MetricSheet({required this.site});
  final Site site;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final catalogue = ref.watch(metricsCatalogueProvider(site));
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Métrique du site', style: GT.display(22, color: p.fg)),
            const SizedBox(height: 14),
            Flexible(
              child: catalogue.when(
                loading: () => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: p.accent,
                      strokeWidth: 2.4,
                    ),
                  ),
                ),
                error: (e, _) => _Note(metricsErrorMessage(e)),
                data: (defs) => defs.isEmpty
                    ? const _Note('Cette source ne propose aucun indicateur.')
                    : ListView(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          for (final d in defs)
                            _MetricRow(
                              def: d,
                              onTap: () => Navigator.of(context).pop(d),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.def, required this.onTap});
  final MetricDef def;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(def.libelle, style: GT.body(14.5, weight: 600, color: p.fg)),
            if (def.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(def.description, style: GT.body(12.5, color: p.fg3)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(text, style: GT.body(13, color: context.glance.fg3)),
      );
}
