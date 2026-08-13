import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/internal_traffic.dart';
import '../../data/models/period.dart';
import '../../state/internal_traffic.dart';
import '../../state/period_state.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../widgets/chip.dart';
import '../widgets/common.dart';

/// Navigation interne : les visiteurs que vos sites s'envoient entre eux
/// (referrers croisés avec vos propres domaines), sur la période partagée.
class InternalTrafficScreen extends ConsumerWidget {
  const InternalTrafficScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final periodState = ref.watch(periodProvider);
    final window = periodState.window();
    final state = ref.watch(internalTrafficProvider(window));
    final t = state.data;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back_rounded, color: p.fg),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('Entre vos sites',
                      style: GT.display(24, color: p.fg)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ChipRow(
              children: [
                for (final per in Period.values)
                  if (per != Period.custom)
                    GlanceChip(
                      label: per.label,
                      selected: periodState.period == per,
                      onTap: () => ref.read(periodProvider.notifier).set(per),
                    ),
              ],
            ),
            const SizedBox(height: 18),
            GlanceCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel('Visiteurs échangés · ${periodState.period.label}'),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(fmtInt(t.total), style: GT.stat(40, color: p.fg)),
                      const SizedBox(width: 10),
                      if (state.pending > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${state.pending} site(s) en cours…',
                            style: GT.mono(10, color: p.fg3),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Visiteurs arrivés sur un de vos sites depuis un autre de vos sites.',
                    style: GT.body(12.5, color: p.fg2),
                  ),
                ],
              ),
            ),
            if (t.isEmpty && !state.loading) ...[
              const SizedBox(height: 26),
              Center(
                child: Text(
                  'Aucune navigation interne sur cette période.',
                  style: GT.body(13, color: p.fg3),
                ),
              ),
            ],
            if (t.flows.isNotEmpty) ...[
              const SizedBox(height: 14),
              _PeerCard(
                title: 'Qui envoie',
                peers: t.sources,
                arrow: '→',
              ),
              const SizedBox(height: 14),
              _PeerCard(
                title: 'Qui reçoit',
                peers: t.destinations,
                arrow: '←',
              ),
              const SizedBox(height: 14),
              GlanceCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel('Flux'),
                    const SizedBox(height: 10),
                    MetricBars(
                      mono: true,
                      rows: [
                        for (final f in t.flows.take(20))
                          MetricBarRow(
                            label: '${f.from} → ${f.to}',
                            value: f.visitors,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Carte agrégée par site (émetteurs ou récepteurs), avec le détail des flux
/// en sous-lignes.
class _PeerCard extends StatelessWidget {
  const _PeerCard({
    required this.title,
    required this.peers,
    required this.arrow,
  });

  final String title;
  final List<InternalPeer> peers;
  final String arrow;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GlanceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          const SizedBox(height: 10),
          MetricBars(
            rows: [
              for (final peer in peers)
                MetricBarRow(label: peer.domain, value: peer.total),
            ],
          ),
          if (peers.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              [
                for (final peer in peers.take(3))
                  '${peer.domain} $arrow ${peer.flows.map((f) => arrow == '→' ? f.to : f.from).take(3).join(', ')}',
              ].join('\n'),
              style: GT.mono(10, color: p.fg3),
            ),
          ],
        ],
      ),
    );
  }
}
