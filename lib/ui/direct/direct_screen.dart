import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../state/workspaces.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../root_scaffold.dart';
import '../widgets/common.dart';
import '../widgets/site_avatar.dart';
import '../widgets/pulse_dot.dart';

class DirectScreen extends ConsumerStatefulWidget {
  const DirectScreen({super.key});

  @override
  ConsumerState<DirectScreen> createState() => _DirectScreenState();
}

class _DirectScreenState extends ConsumerState<DirectScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final secs = ref.read(settingsProvider).refreshSeconds;
    // Le live est indépendant de la période → on invalide juste cette famille.
    _timer = Timer.periodic(Duration(seconds: secs), (_) {
      if (mounted) ref.invalidate(siteLiveProvider);
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
    final onlyLive = ref.watch(settingsProvider.select((s) => s.directOnlyLive));
    // Même périmètre que l'accueil : le direct porte sur le groupe actif.
    final sitesAsync = ref.watch(visibleSitesProvider);
    final sites = sitesAsync.value ?? const <Site>[];
    final group = ref.watch(activeWorkspaceProvider);

    // Live par site, chargé indépendamment (incrémental).
    final entries = <({Site site, int live, bool loading})>[];
    var totalLive = 0;
    var loading = sitesAsync.isLoading;
    for (final s in sites) {
      final lv = ref.watch(siteLiveProvider(s));
      final v = lv.value ?? 0;
      totalLive += v;
      if (lv.isLoading) loading = true;
      entries.add((site: s, live: v, loading: lv.isLoading && !lv.hasValue));
    }
    entries.sort((a, b) => b.live.compareTo(a.live));
    final shown =
        onlyLive ? entries.where((e) => e.live > 0).toList() : entries;
    final hiddenCount = entries.length - shown.length;
    final refreshing = loading && sites.isNotEmpty;

    return Stack(
      children: [
        RefreshIndicator(
          color: p.accent,
          backgroundColor: p.surface,
          onRefresh: () async {
            ref.invalidate(siteLiveProvider);
            await ref.read(sitesProvider.future);
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
                    LivePill(count: totalLive, text: 'en ce moment'),
                    const SizedBox(height: 14),
                    Text(
                      '$totalLive',
                      style: GT.stat(64, color: totalLive > 0 ? p.accent : p.fg3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group == null
                          ? "visiteurs sur l'ensemble de vos sites"
                          : 'visiteurs sur le groupe « ${group.name} »',
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
                      value: onlyLive,
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setDirectOnlyLive(!onlyLive),
                    ),
                  ],
                ),
              ),
              if (sites.isEmpty && sitesAsync.isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: p.accent,
                      strokeWidth: 2.4,
                    ),
                  ),
                )
              else if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      onlyLive
                          ? 'Aucun visiteur en direct pour l\'instant.'
                          : 'Aucun site.',
                      style: GT.body(14, color: p.fg3),
                    ),
                  ),
                )
              else ...[
                for (final e in shown) ...[
                  _LiveRow(site: e.site, live: e.live, loading: e.loading),
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
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top,
          left: 0,
          right: 0,
          child: RefreshBar(visible: refreshing),
        ),
      ],
    );
  }
}

class _LiveRow extends StatelessWidget {
  const _LiveRow({required this.site, required this.live, this.loading = false});
  final Site site;
  final int live;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GlanceCard(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      onTap: () => openSite(context, site),
      child: Row(
        children: [
          SiteAvatar(site),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              site.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GT.body(15, weight: 500, color: p.fg),
            ),
          ),
          if (loading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: p.fg3),
            )
          else ...[
            PulseDot(pulse: live > 0, color: live > 0 ? p.accent : p.fg3),
            const SizedBox(width: 8),
            Text(
              '$live',
              style: GT.stat(22, color: live > 0 ? p.accent : p.fg3),
            ),
          ],
        ],
      ),
    );
  }
}
