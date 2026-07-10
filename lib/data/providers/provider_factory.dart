import '../models/account.dart';
import 'analytics_provider.dart';
import 'fathom_provider.dart';
import 'plausible_provider.dart';
import 'umami_provider.dart';

/// Construit le client concret correspondant au fournisseur du compte.
AnalyticsProvider buildProvider(Account account, Map<String, String> creds) {
  switch (account.kind) {
    case ProviderKind.umami:
      return UmamiProvider(account, creds);
    case ProviderKind.plausible:
      return PlausibleProvider(account, creds);
    case ProviderKind.fathom:
      return FathomProvider(account, creds);
  }
}
