import '../data/models/models.dart';

/// En dessous, la liste se parcourt d'un coup d'œil : pas de champ de recherche.
const int kSiteSearchThreshold = 6;

const _accents = {
  'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a', 'å': 'a',
  'ç': 'c',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'î': 'i', 'ï': 'i', 'í': 'i', 'ì': 'i',
  'ñ': 'n',
  'ô': 'o', 'ö': 'o', 'ó': 'o', 'ò': 'o', 'õ': 'o',
  'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
  'ÿ': 'y', 'ý': 'y',
  'œ': 'oe', 'æ': 'ae',
};

String _fold(String s) {
  final lower = s.toLowerCase();
  final out = StringBuffer();
  for (final ch in lower.split('')) {
    out.write(_accents[ch] ?? ch);
  }
  return out.toString();
}

/// Le site correspond si **chaque** mot de [query] figure dans son nom ou son
/// domaine, sans tenir compte de la casse ni des accents : « geo app » trouve
/// « GeoDaily (app) ». Une requête vide garde tout.
bool siteMatches(Site site, String query) {
  final words = _fold(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return true;
  final haystack = _fold('${site.name} ${site.domain}');
  return words.every(haystack.contains);
}

List<Site> filterSites(Iterable<Site> sites, String query) =>
    [for (final s in sites) if (siteMatches(s, query)) s];
