/// Dimensions de métriques et leur regroupement en sections, calqués sur le
/// découpage d'Umami (Pages / Sources / Environnement / Emplacement) : c'est le
/// vocabulaire que connaissent déjà les gens qui viennent de leur tableau de
/// bord.
///
/// Un fournisseur qui ne sait pas répondre à une dimension renvoie une liste
/// vide — la carte affiche « Aucune donnée » plutôt que de disparaître, sinon la
/// mise en page saute d'un fournisseur à l'autre.
library;

import '../../l10n/l10n.dart';

/// Ce qu'on demande au fournisseur. Une valeur = une dimension d'agrégation.
enum MetricType {
  pages,
  entryPages,
  exitPages,
  pageTitles,
  referrers,
  channels,
  queries,
  browsers,
  operatingSystems,
  devices,
  screens,
  countries,
  regions,
  cities,
  languages,
  events,
}

/// Pastille affichée devant un libellé de ligne. Le rendu vit dans l'UI
/// (`MetricIcon`) ; ici on ne dit que *quelle famille* d'icône convient.
enum MetricIconKind {
  /// Favicon du domaine (sources).
  favicon,

  /// Logo de navigateur servi par l'instance Umami.
  browser,

  /// Logo de système servi par l'instance Umami.
  os,

  /// Icône d'appareil (dessinée localement).
  device,

  /// Drapeau émoji (pays).
  flag,

  /// Rien devant le libellé.
  none,
}

extension MetricTypeInfo on MetricType {
  /// Libellé court, tel qu'il apparaît dans le sélecteur d'une section.
  String label(AppLocalizations l10n) => switch (this) {
    MetricType.pages => l10n.metricTypePages,
    MetricType.entryPages => l10n.metricTypeEntry,
    MetricType.exitPages => l10n.metricTypeExit,
    MetricType.pageTitles => l10n.metricTypeTitle,
    MetricType.referrers => l10n.metricTypeReferrers,
    MetricType.channels => l10n.metricTypeChannels,
    MetricType.queries => l10n.metricTypeQueries,
    MetricType.browsers => l10n.metricTypeBrowsers,
    MetricType.operatingSystems => l10n.metricTypeOs,
    MetricType.devices => l10n.metricTypeDevices,
    MetricType.screens => l10n.metricTypeScreens,
    MetricType.countries => l10n.metricTypeCountries,
    MetricType.regions => l10n.metricTypeRegions,
    MetricType.cities => l10n.metricTypeCities,
    MetricType.languages => l10n.metricTypeLanguages,
    MetricType.events => l10n.metricTypeEvents,
  };

  /// Libellé en police à chasse fixe (chemins, requêtes, résolutions) : ce sont
  /// des valeurs techniques qu'on lit caractère par caractère.
  bool get isMono => switch (this) {
    MetricType.pages ||
    MetricType.entryPages ||
    MetricType.exitPages ||
    MetricType.queries ||
    MetricType.screens ||
    MetricType.events => true,
    _ => false,
  };

  MetricIconKind get iconKind => switch (this) {
    MetricType.referrers => MetricIconKind.favicon,
    MetricType.browsers => MetricIconKind.browser,
    MetricType.operatingSystems => MetricIconKind.os,
    MetricType.devices => MetricIconKind.device,
    MetricType.countries => MetricIconKind.flag,
    _ => MetricIconKind.none,
  };

  /// Clé courte et stable pour la persistance (dernière sous-dimension choisie,
  /// cache disque). Ne jamais la dériver de `name` : renommer une valeur
  /// invaliderait silencieusement tout ce qui est déjà écrit.
  String get key => switch (this) {
    MetricType.pages => 'path',
    MetricType.entryPages => 'entry',
    MetricType.exitPages => 'exit',
    MetricType.pageTitles => 'title',
    MetricType.referrers => 'referrer',
    MetricType.channels => 'channel',
    MetricType.queries => 'query',
    MetricType.browsers => 'browser',
    MetricType.operatingSystems => 'os',
    MetricType.devices => 'device',
    MetricType.screens => 'screen',
    MetricType.countries => 'country',
    MetricType.regions => 'region',
    MetricType.cities => 'city',
    MetricType.languages => 'language',
    MetricType.events => 'event',
  };
}

/// Les quatre panneaux de données du détail d'un site.
enum MetricSection {
  pages([
    MetricType.pages,
    MetricType.entryPages,
    MetricType.exitPages,
    MetricType.pageTitles,
  ]),
  sources([
    MetricType.referrers,
    MetricType.channels,
    MetricType.queries,
  ]),
  environment([
    MetricType.browsers,
    MetricType.operatingSystems,
    MetricType.devices,
    MetricType.screens,
  ]),
  location([
    MetricType.countries,
    MetricType.regions,
    MetricType.cities,
    MetricType.languages,
  ]);

  const MetricSection(this.dimensions);

  String label(AppLocalizations l10n) => switch (this) {
    pages => l10n.metricSectionPages,
    sources => l10n.metricSectionSources,
    environment => l10n.metricSectionEnvironment,
    location => l10n.metricSectionLocation,
  };

  final List<MetricType> dimensions;

  MetricType get defaultDimension => dimensions.first;

  static MetricType? dimensionFromKey(String? key) {
    if (key == null) return null;
    for (final t in MetricType.values) {
      if (t.key == key) return t;
    }
    return null;
  }
}
