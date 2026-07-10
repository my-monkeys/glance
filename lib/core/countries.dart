/// Nom FR pour les codes pays fréquents. Fallback = le code brut.
const Map<String, String> _names = {
  'FR': 'France',
  'BE': 'Belgique',
  'CH': 'Suisse',
  'CA': 'Canada',
  'DE': 'Allemagne',
  'GB': 'Royaume-Uni',
  'US': 'États-Unis',
  'ES': 'Espagne',
  'IT': 'Italie',
  'PT': 'Portugal',
  'NL': 'Pays-Bas',
  'LU': 'Luxembourg',
  'MA': 'Maroc',
  'DZ': 'Algérie',
  'TN': 'Tunisie',
  'SN': 'Sénégal',
  'CI': "Côte d'Ivoire",
  'IE': 'Irlande',
  'PL': 'Pologne',
  'SE': 'Suède',
  'NO': 'Norvège',
  'DK': 'Danemark',
  'FI': 'Finlande',
  'AT': 'Autriche',
  'BR': 'Brésil',
  'JP': 'Japon',
  'CN': 'Chine',
  'IN': 'Inde',
  'AU': 'Australie',
  'RU': 'Russie',
  'UA': 'Ukraine',
  'RO': 'Roumanie',
  'GR': 'Grèce',
  'CZ': 'Tchéquie',
  'MX': 'Mexique',
  'TR': 'Turquie',
};

String countryName(String code) {
  final c = code.toUpperCase();
  return _names[c] ?? code;
}

/// Émoji drapeau à partir d'un code ISO-2 (indicateurs régionaux).
String countryFlag(String code) {
  final c = code.trim().toUpperCase();
  if (c.length != 2 || !RegExp(r'^[A-Z]{2}$').hasMatch(c)) return '🌐';
  final base = 0x1F1E6;
  final a = base + (c.codeUnitAt(0) - 65);
  final b = base + (c.codeUnitAt(1) - 65);
  return String.fromCharCode(a) + String.fromCharCode(b);
}
