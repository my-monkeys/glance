import '../l10n/display_names.dart';
import '../l10n/l10n.dart';

/// Nom d'un pays dans la langue de l'app (CLDR). Repli : le code brut.
String countryName(String code) =>
    lookupDisplayName(kRegionNames, code.toUpperCase()) ?? code;

/// Émoji drapeau à partir d'un code ISO-2 (indicateurs régionaux).
String countryFlag(String code) {
  final c = code.trim().toUpperCase();
  if (c.length != 2 || !RegExp(r'^[A-Z]{2}$').hasMatch(c)) return '🌐';
  final base = 0x1F1E6;
  final a = base + (c.codeUnitAt(0) - 65);
  final b = base + (c.codeUnitAt(1) - 65);
  return String.fromCharCode(a) + String.fromCharCode(b);
}
