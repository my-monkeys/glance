import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/period.dart';
import '../../state/home_data.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../root_scaffold.dart';
import '../widgets/common.dart';
import '../widgets/pulse_dot.dart';

class DirectScreen extends ConsumerStatefulWidget {
  const DirectScreen({super.key});

  @override
  ConsumerState<DirectScreen> createState() => _DirectScreenState();
}

class _DirectScreenState extends ConsumerState<DirectScreen> {
  late final DateWindow _window = Period.d7.window();
  bool _onlyLive = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final secs = ref.read(settingsProvider).refreshSeconds;
    _timer = Timer.periodic(Duration(seconds: secs), (_) {
      if (mounted) ref.invalidate(homeProvider(_window));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final data = ref.watch(homeProvider(_window)).value;
    final allCards = [...?data?.cards]..sort((a, b) => b.live.compareTo(a.live));
    final cards =
        _onlyLive ? allCards.where((c) => c.live > 0).toList() : allCards;
    final hiddenCount = allCards.length - cards.length;

    return RefreshIndicator(
      color: p.accent,
      backgroundColor: p.surface,
      onRefresh: () async {
        ref.invalidate(homeProvider(_window));
        await ref.read(homeProvider(_window).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 14,
          20,
          120,
        ),
        children: [
          SectionLabel('Temps réel'),
          const SizedBox(height: 9),
          Text('En direct', style: GT.display(34, color: p.fg)),
          const SizedBox(height: 18),
          GlanceCard(
            child: Column(
              children: [
                LivePill(label: 'en ce moment'),
                const SizedBox(height: 14),
                Text(
                  '${data?.totalLive ?? 0}',
                  style: GT.stat(64, color: p.accent),
                ),
                const SizedBox(height: 4),
                Text(
                  "visiteurs sur l'ensemble de vos sites",
                  textAlign: TextAlign.center,
                  style: GT.body(13, color: p.fg2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 2, bottom: 10),
            child: Row(
              children: [
                Expanded(child: SectionLabel('Par site')),
                Text('Actifs seulement', style: GT.body(12, color: p.fg2)),
                const SizedBox(width: 8),
                GlanceToggle(
                  value: _onlyLive,
                  onTap: () => setState(() => _onlyLive = !_onlyLive),
                ),
              ],
            ),
          ),
          if (data == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(
                  color: p.accent,
                  strokeWidth: 2.4,
                ),
              ),
            )
          else if (cards.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  _onlyLive
                      ? 'Aucun visiteur en direct pour l\'instant.'
                      : 'Aucun site.',
                  style: GT.body(14, color: p.fg3),
                ),
              ),
            )
          else ...[
            for (final c in cards) ...[
              _LiveRow(card: c),
              const SizedBox(height: 10),
            ],
            if (hiddenCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '$hiddenCount site${hiddenCount > 1 ? 's' : ''} sans visiteur masqué${hiddenCount > 1 ? 's' : ''}',
                  textAlign: TextAlign.center,
                  style: GT.body(12, color: p.fg3),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _LiveRow extends StatelessWidget {
  const _LiveRow({required this.card});
  final SiteCard card;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GlanceCard(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      onTap: () => openSite(context, card.site),
      child: Row(
        children: [
          Mark(card.site.initial),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              card.site.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GT.body(15, weight: 500, color: p.fg),
            ),
          ),
          const PulseDot(),
          const SizedBox(width: 8),
          Text('${card.live}', style: GT.stat(22, color: p.accent)),
        ],
      ),
    );
  }
}
