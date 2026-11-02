/// Mise en forme des valeurs brutes renvoyées par les fournisseurs
/// (navigateurs, appareils, canaux d'acquisition, langues). Les tables suivent
/// celles d'Umami pour que les libellés soient les mêmes des deux côtés.
///
/// Les noms propres (navigateurs, systèmes) restent tels quels ; le reste est
/// traduit à l'affichage, jamais au chargement : les lignes sont mises en cache
/// et doivent suivre la langue de l'app.
///
/// Toutes ces fonctions renvoient la valeur d'origine quand elles ne la
/// connaissent pas : un navigateur inconnu s'affiche tel quel plutôt que
/// « Inconnu », qui effacerait l'information.
library;

import 'package:intl/intl.dart';

import '../data/models/dimension.dart';
import '../data/models/models.dart';
import '../l10n/display_names.dart';
import '../l10n/l10n.dart';
import 'countries.dart';

const _browsers = <String, String>{
  'android': 'Android',
  'aol': 'AOL',
  'bb10': 'BlackBerry 10',
  'beaker': 'Beaker',
  'chrome': 'Chrome',
  'chromium-webview': 'Chrome (webview)',
  'crios': 'Chrome (iOS)',
  'curl': 'Curl',
  'edge': 'Edge',
  'edge-chromium': 'Edge',
  'edge-ios': 'Edge (iOS)',
  'facebook': 'Facebook',
  'firefox': 'Firefox',
  'fxios': 'Firefox (iOS)',
  'ie': 'Internet Explorer',
  'instagram': 'Instagram',
  'ios': 'Safari (iOS)',
  'ios-webview': 'iOS (webview)',
  'kakaotalk': 'KakaoTalk',
  'miui': 'MIUI',
  'opera': 'Opera',
  'opera-mini': 'Opera Mini',
  'phantomjs': 'PhantomJS',
  'safari': 'Safari',
  'samsung': 'Samsung Internet',
  'silk': 'Silk',
  'yandexbrowser': 'Yandex',
  'brave': 'Brave',
  'chromium': 'Chromium',
};

String browserName(AppLocalizations l10n, String raw) {
  final k = raw.trim().toLowerCase();
  if (k.isEmpty) return l10n.entityUnknown;
  if (k == 'searchbot') return l10n.entityBrowserSearchBot;
  return _browsers[k] ?? raw;
}

String deviceName(AppLocalizations l10n, String raw) =>
    switch (raw.trim().toLowerCase()) {
      '' => l10n.entityUnknown,
      'desktop' => l10n.entityDeviceDesktop,
      'laptop' => l10n.entityDeviceLaptop,
      'tablet' => l10n.entityDeviceTablet,
      'mobile' => l10n.entityDeviceMobile,
      'wearable' => l10n.entityDeviceWearable,
      'console' => l10n.entityDeviceConsole,
      'tv' => l10n.entityDeviceTv,
      _ => raw,
    };

/// Canaux d'acquisition d'Umami (`type=channel`) et de Plausible
/// (`visit:channel`, en « Organic Search » plutôt qu'en camelCase).
String channelName(AppLocalizations l10n, String raw) =>
    switch (raw.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '')) {
      '' || 'unknown' => l10n.entityUnknown,
      'direct' => l10n.channelDirect,
      'referral' => l10n.channelReferral,
      'affiliate' => l10n.channelAffiliate,
      'email' => l10n.channelEmail,
      'sms' => 'SMS',
      'llm' => 'LLM',
      'organicsearch' => l10n.channelOrganicSearch,
      'organicsocial' => l10n.channelOrganicSocial,
      'organicshopping' => l10n.channelOrganicShopping,
      'organicvideo' => l10n.channelOrganicVideo,
      'paidads' => l10n.channelPaidAds,
      'paidsearch' => l10n.channelPaidSearch,
      'paidsocial' => l10n.channelPaidSocial,
      'paidshopping' => l10n.channelPaidShopping,
      'paidvideo' => l10n.channelPaidVideo,
      _ => raw,
    };

/// « fr », « fr-fr », « fr_FR » → « Français » (dans la langue de l'app). La
/// variante régionale est conservée entre parenthèses quand elle diffère de la
/// langue (« pt-br »).
String languageName(AppLocalizations l10n, String raw) {
  final k = raw.trim().toLowerCase().replaceAll('_', '-');
  if (k.isEmpty) return l10n.entityUnknown;
  final parts = k.split('-');
  final name = lookupDisplayName(kLanguageNames, parts.first);
  if (name == null) return raw;
  final base = toBeginningOfSentenceCase(name, Intl.defaultLocale);
  if (parts.length < 2 || parts[1].isEmpty || parts[1] == parts.first) {
    return base;
  }
  return '$base (${parts[1].toUpperCase()})';
}

/// Libellé affiché d'une ligne de métrique. Le fournisseur ne rend que la
/// valeur brute (`code`) : la traduction se fait ici, à l'affichage.
String metricRowLabel(AppLocalizations l10n, MetricType type, MetricRow row) {
  final raw = row.code ?? row.label;
  return switch (type) {
    MetricType.channels => channelName(l10n, raw),
    MetricType.countries => countryName(raw),
    MetricType.browsers => browserName(l10n, raw),
    MetricType.devices => deviceName(l10n, raw),
    MetricType.languages => languageName(l10n, raw),
    MetricType.referrers when row.isDirect => l10n.entityReferrerDirect,
    MetricType.pages || MetricType.entryPages || MetricType.exitPages => row.label,
    _ => row.label.isEmpty ? l10n.entityUnknown : row.label,
  };
}
