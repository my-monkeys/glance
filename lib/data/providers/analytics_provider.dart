import 'package:dio/dio.dart';

import '../models/account.dart';
import '../models/models.dart';
import '../models/period.dart';

enum MetricType { pages, sources, countries, events }

/// État de santé d'un compte (pour signaler un souci d'auth dans l'UI).
enum AccountHealth {
  ok,
  badAuth, // identifiants ou clé API refusés (401/403)
  unreachable, // instance injoignable / erreur réseau
}

/// Contrat que chaque fournisseur d'analytics implémente. La couche UI ne parle
/// qu'à cette interface — brancher un nouveau fournisseur = une nouvelle classe.
abstract class AnalyticsProvider {
  AnalyticsProvider(this.account, this.creds);

  final Account account;
  final Map<String, String> creds;

  /// Teste la connexion et renvoie le nombre de sites détectés.
  Future<int> verify();

  Future<List<Site>> listSites();

  Future<StatsSummary> summary(Site site, DateWindow w);

  Future<List<SeriesPoint>> series(Site site, DateWindow w);

  /// Visiteurs actifs en ce moment.
  Future<int> active(Site site);

  Future<List<MetricRow>> metric(
    Site site,
    DateWindow w,
    MetricType type, {
    int limit = 8,
  });

  /// Pages consultées dans les dernières minutes.
  Future<List<LivePage>> livePages(Site site);

  /// Une série temporelle par nom d'événement (triées par total décroissant).
  Future<List<EventSeries>> eventSeries(Site site, DateWindow w);

  /// Diagnostic léger du compte : valide les identifiants (et la clé pour les
  /// fournisseurs à clé). Par défaut, dérivé de [verify] : 401/403 → badAuth,
  /// erreur réseau → unreachable, autre échec → badAuth (creds incohérents).
  Future<AccountHealth> health() async {
    try {
      await verify();
      return AccountHealth.ok;
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      if (code == 401 || code == 403) return AccountHealth.badAuth;
      return AccountHealth.unreachable;
    } catch (_) {
      return AccountHealth.badAuth;
    }
  }
}

/// Champs d'identifiants demandés à l'écran d'ajout, par fournisseur.
List<CredentialField> credentialFieldsFor(ProviderKind kind) {
  switch (kind) {
    case ProviderKind.umami:
      return const [
        CredentialField(
          key: 'baseUrl',
          label: "URL de l'instance",
          placeholder: 'analytics.mondomaine.fr',
          keyboardUrl: true,
        ),
        CredentialField(key: 'username', label: "Nom d'utilisateur"),
        CredentialField(key: 'password', label: 'Mot de passe', secret: true),
      ];
    case ProviderKind.plausible:
      return const [
        CredentialField(
          key: 'baseUrl',
          label: "URL de l'instance",
          placeholder: 'plausible.io',
          keyboardUrl: true,
        ),
        CredentialField(key: 'apiKey', label: 'Clé API', secret: true),
        CredentialField(
          key: 'email',
          label: 'Email du compte (facultatif)',
          placeholder: 'vous@exemple.fr',
          optional: true,
          hint: 'Email + mot de passe : Glance liste vos sites automatiquement. '
              'Sinon, laissez vide et renseignez un domaine ci-dessous.',
        ),
        CredentialField(
          key: 'password',
          label: 'Mot de passe (facultatif)',
          secret: true,
          optional: true,
        ),
        CredentialField(
          key: 'siteId',
          label: 'Domaine (si pas d\'email/mot de passe)',
          placeholder: 'mondomaine.fr',
          optional: true,
        ),
      ];
    case ProviderKind.fathom:
      return const [
        CredentialField(key: 'apiKey', label: 'Clé API', secret: true),
      ];
  }
}
