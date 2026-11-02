import 'package:dio/dio.dart';

import '../../core/sites_visitors.dart';
import '../../l10n/l10n.dart';
import '../models/account.dart';
import '../models/dimension.dart';
import '../models/indicator.dart';
import '../models/indicator_result.dart';
import '../models/models.dart';
import '../models/period.dart';
import 'provider_errors.dart';

export '../models/dimension.dart';

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

  /// Nombre d'occurrences de [q] par bucket, porté par [SeriesPoint.visitors]
  /// (pageviews à 0) — même convention que [eventSeries]. Série continue : un
  /// ratio aligne deux séries par index.
  Future<List<SeriesPoint>> eventCountSeries(
          Site site, DateWindow w, EventQuery q) =>
      throw const FeatureUnsupported(UnsupportedFeature.indicators);

  /// Visiteurs uniques par bucket et sur la fenêtre, restreints à ceux venus
  /// de [referrer] (domaine exact) s'il est donné.
  Future<SiteVisitors> visitors(
    Site site,
    DateWindow w, {
    String? referrer,
  }) =>
      throw const FeatureUnsupported(UnsupportedFeature.siteTables);

  Future<List<FunnelStepResult>> funnel(
          Site site, DateWindow w, FunnelIndicator f) =>
      throw const FeatureUnsupported(UnsupportedFeature.funnels);

  /// Valeurs d'une propriété d'événement, les plus fréquentes d'abord.
  Future<List<MetricRow>> propertyValues(
    Site site,
    DateWindow w,
    String event,
    String property, {
    int limit = 30,
  }) =>
      throw const FeatureUnsupported(UnsupportedFeature.breakdowns);

  /// Propriétés connues d'un événement. Vide = le fournisseur ne sait pas les
  /// lister : l'éditeur retombe sur une saisie libre.
  Future<List<EventProperty>> eventProperties(
          Site site, DateWindow w, String event) async =>
      const [];

  /// Plage réellement couverte par les données du site (première et dernière
  /// mesure). Null quand le fournisseur ne sait pas la donner — l'appelant
  /// retombe alors sur un cadrage large. Sert à caler la période « Tout » sur
  /// les vraies données plutôt que sur une borne arbitraire.
  Future<DataRange?> dataRange(Site site) async => null;

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

/// Genres d'indicateurs que le fournisseur sait calculer (vide = onglet
/// Tableaux indisponible). Fonction libre plutôt que méthode d'instance : la
/// visibilité de l'onglet se décide de façon synchrone au premier build, sans
/// attendre la construction asynchrone du fournisseur.
Set<IndicatorKind> supportedIndicatorsFor(ProviderKind kind) => switch (kind) {
      ProviderKind.umami => IndicatorKind.values.toSet(),
      ProviderKind.plausible => const {
          // Pas `sites` : le filtre de référent n'est implémenté que pour Umami.
          IndicatorKind.counter,
          IndicatorKind.ratio,
          IndicatorKind.breakdown,
        },
      ProviderKind.fathom => const {},
    };

/// Champs d'identifiants demandés à l'écran d'ajout, par fournisseur.
List<CredentialField> credentialFieldsFor(
  AppLocalizations l10n,
  ProviderKind kind,
) {
  switch (kind) {
    case ProviderKind.umami:
      return [
        CredentialField(
          key: 'baseUrl',
          label: l10n.credInstanceUrl,
          placeholder: l10n.credUmamiUrlPlaceholder,
          keyboardUrl: true,
        ),
        CredentialField(key: 'username', label: l10n.credUsername),
        CredentialField(key: 'password', label: l10n.credPassword, secret: true),
      ];
    case ProviderKind.plausible:
      return [
        CredentialField(
          key: 'baseUrl',
          label: l10n.credInstanceUrl,
          placeholder: 'plausible.io',
          keyboardUrl: true,
        ),
        CredentialField(key: 'apiKey', label: l10n.credApiKey, secret: true),
        CredentialField(
          key: 'email',
          label: l10n.credEmailOptional,
          placeholder: l10n.credEmailPlaceholder,
          optional: true,
          hint: l10n.credEmailHint,
        ),
        CredentialField(
          key: 'password',
          label: l10n.credPasswordOptional,
          secret: true,
          optional: true,
        ),
        CredentialField(
          key: 'siteId',
          label: l10n.credDomainFallback,
          placeholder: l10n.credDomainPlaceholder,
          optional: true,
        ),
      ];
    case ProviderKind.fathom:
      return [
        CredentialField(key: 'apiKey', label: l10n.credApiKey, secret: true),
      ];
  }
}
