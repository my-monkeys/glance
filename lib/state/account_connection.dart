import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Reteste la connexion d'un compte depuis un fournisseur neuf (un échec passé,
/// ou un jeton périmé, ne doit pas fausser le résultat) et renvoie le nombre de
/// sites. En cas de succès, recharge tout ce que ce compte alimente. Prend le
/// conteneur : l'appelant peut être fermé avant la fin du test.
Future<int> testAccountConnection(ProviderContainer c, String accountId) async {
  final provider = await c.read(providerRegistryProvider).fresh(accountId);
  final sites = await provider.verify();
  c.invalidate(accountHealthProvider(accountId));
  c.invalidate(accountSitesProvider(accountId));
  c.invalidate(sitesProvider);
  c.invalidate(siteStatsProvider);
  c.invalidate(siteLiveProvider);
  return sites;
}
