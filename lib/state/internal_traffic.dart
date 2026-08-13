import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/internal_traffic.dart';
import '../data/models/models.dart';
import '../data/models/period.dart';
import '../data/providers/analytics_provider.dart';
import 'providers.dart';
import 'workspaces.dart';

/// Sources (referrers) d'un site sur une fenêtre, avec assez de lignes pour
/// que les referrers internes ne passent pas sous le top 6 du détail.
final siteReferrersProvider = FutureProvider.autoDispose
    .family<List<MetricRow>, (Site, DateWindow)>((ref, key) async {
  cacheSession(ref);
  final (site, w) = key;
  final gate = ref.watch(fetchGateProvider);
  final reg = ref.watch(providerRegistryProvider);
  final p = await reg.forAccount(site.accountId);
  return gate.run(() => p.metric(site, w, MetricType.sources, limit: 50));
});

/// Domaines normalisés de TOUT le périmètre suivi (pas seulement le groupe
/// actif) : un referrer est « interne » dès qu'il vient d'un site suivi.
final knownDomainsProvider = Provider.autoDispose<Set<String>>((ref) {
  final all = ref.watch(sitesProvider).value ?? const <Site>[];
  return {
    for (final s in all)
      if (normDomain(s.domain).isNotEmpty) normDomain(s.domain),
  };
});

class InternalTrafficState {
  const InternalTrafficState({
    required this.data,
    required this.pending,
    required this.loading,
  });

  final InternalTraffic data;
  final int pending; // sites dont les referrers ne sont pas encore arrivés
  final bool loading;
}

/// Trafic interne du groupe actif, recomposé au fil de l'eau (même pattern que
/// `homeTotalsProvider`) : chaque site qui livre ses referrers affine le total.
final internalTrafficProvider =
    Provider.autoDispose.family<InternalTrafficState, DateWindow>((ref, w) {
  final known = ref.watch(knownDomainsProvider);
  final sitesAsync = ref.watch(visibleSitesProvider);
  final sites = sitesAsync.value ?? const <Site>[];
  final referrersByDest = <String, List<MetricRow>>{};
  var pending = 0;
  var loading = sitesAsync.isLoading;

  for (final s in sites) {
    final rows = ref.watch(siteReferrersProvider((s, w)));
    if (rows.isLoading) {
      pending++;
      loading = true;
    }
    final v = rows.value;
    if (v != null) referrersByDest[normDomain(s.domain)] = v;
  }

  return InternalTrafficState(
    data: InternalTraffic.build(referrersByDest, known),
    pending: pending,
    loading: loading,
  );
});
