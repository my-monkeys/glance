/// Mise en français des valeurs brutes renvoyées par les fournisseurs
/// (navigateurs, appareils, canaux d'acquisition, langues). Les tables suivent
/// celles d'Umami pour que les libellés soient les mêmes des deux côtés.
///
/// Toutes ces fonctions renvoient la valeur d'origine quand elles ne la
/// connaissent pas : un navigateur inconnu s'affiche tel quel plutôt que
/// « Inconnu », qui effacerait l'information.
library;

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
  'searchbot': 'Robot d\'indexation',
  'silk': 'Silk',
  'yandexbrowser': 'Yandex',
  'brave': 'Brave',
  'chromium': 'Chromium',
};

String browserName(String raw) {
  final k = raw.trim().toLowerCase();
  if (k.isEmpty) return 'Inconnu';
  return _browsers[k] ?? raw;
}

const _devices = <String, String>{
  'desktop': 'Ordinateur',
  'laptop': 'Portable',
  'tablet': 'Tablette',
  'mobile': 'Mobile',
  'wearable': 'Montre',
  'console': 'Console',
  'tv': 'Téléviseur',
};

String deviceName(String raw) {
  final k = raw.trim().toLowerCase();
  if (k.isEmpty) return 'Inconnu';
  return _devices[k] ?? raw;
}

/// Canaux d'acquisition d'Umami (`type=channel`) et de Plausible
/// (`visit:channel`, en « Organic Search » plutôt qu'en camelCase).
const _channels = <String, String>{
  'direct': 'Direct',
  'referral': 'Référent',
  'affiliate': 'Affiliation',
  'email': 'E-mail',
  'sms': 'SMS',
  'llm': 'LLM',
  'organicsearch': 'Recherche organique',
  'organicsocial': 'Réseaux sociaux',
  'organicshopping': 'Achat organique',
  'organicvideo': 'Vidéo organique',
  'paidads': 'Publicité payante',
  'paidsearch': 'Recherche payante',
  'paidsocial': 'Réseaux sociaux payants',
  'paidshopping': 'Achat payant',
  'paidvideo': 'Vidéo payante',
  'unknown': 'Inconnu',
};

String channelName(String raw) {
  final k = raw.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
  if (k.isEmpty) return 'Inconnu';
  return _channels[k] ?? raw;
}

const _languages = <String, String>{
  'af': 'Afrikaans',
  'ar': 'Arabe',
  'be': 'Biélorusse',
  'bg': 'Bulgare',
  'bn': 'Bengali',
  'ca': 'Catalan',
  'cs': 'Tchèque',
  'da': 'Danois',
  'de': 'Allemand',
  'el': 'Grec',
  'en': 'Anglais',
  'eo': 'Espéranto',
  'es': 'Espagnol',
  'et': 'Estonien',
  'eu': 'Basque',
  'fa': 'Persan',
  'fi': 'Finnois',
  'fr': 'Français',
  'ga': 'Irlandais',
  'he': 'Hébreu',
  'hi': 'Hindi',
  'hr': 'Croate',
  'hu': 'Hongrois',
  'hy': 'Arménien',
  'id': 'Indonésien',
  'is': 'Islandais',
  'it': 'Italien',
  'ja': 'Japonais',
  'ka': 'Géorgien',
  'kk': 'Kazakh',
  'ko': 'Coréen',
  'lt': 'Lituanien',
  'lv': 'Letton',
  'mk': 'Macédonien',
  'ms': 'Malais',
  'nb': 'Norvégien',
  'nl': 'Néerlandais',
  'nn': 'Norvégien (nynorsk)',
  'no': 'Norvégien',
  'pl': 'Polonais',
  'pt': 'Portugais',
  'ro': 'Roumain',
  'ru': 'Russe',
  'sk': 'Slovaque',
  'sl': 'Slovène',
  'sq': 'Albanais',
  'sr': 'Serbe',
  'sv': 'Suédois',
  'sw': 'Swahili',
  'ta': 'Tamoul',
  'th': 'Thaï',
  'tr': 'Turc',
  'uk': 'Ukrainien',
  'ur': 'Ourdou',
  'vi': 'Vietnamien',
  'zh': 'Chinois',
};

/// « fr », « fr-fr », « fr_FR » → « Français ». La variante régionale est
/// conservée entre parenthèses quand elle diffère de la langue (« pt-br »).
String languageName(String raw) {
  final k = raw.trim().toLowerCase().replaceAll('_', '-');
  if (k.isEmpty) return 'Inconnu';
  final parts = k.split('-');
  final base = _languages[parts.first];
  if (base == null) return raw;
  if (parts.length < 2 || parts[1].isEmpty) return base;
  return '$base (${parts[1].toUpperCase()})';
}
