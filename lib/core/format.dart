import 'package:intl/intl.dart';

import '../data/models/period.dart';
import '../l10n/l10n.dart';

// Les formats suivent `Intl.defaultLocale`, posée par le délégué de la langue
// de l'app (`l10n/l10n.dart`) : ces fonctions pures n'ont pas de BuildContext.
NumberFormat _decimal(int maxDigits) =>
    NumberFormat.decimalPattern()..maximumFractionDigits = maxDigits;

/// 1204 -> "1 204", 1204000 -> "1,2 M" au-delà de 100 000 pour rester lisible.
String fmtCount(num n) {
  if (n >= 1000000) return '${_decimal(1).format(n / 1000000)} M';
  // Dès 10 000 le nombre complet déborde des labels d'axe (36 px réservés).
  if (n >= 10000) return '${_decimal(1).format(n / 1000)} k';
  return _decimal(0).format(n.round());
}

/// Format compact simple (chiffres bruts avec séparateur de milliers).
String fmtInt(num n) => _decimal(0).format(n.round());

/// Delta signé en pourcentage : 8.4 -> "8,4 %" (fr), "8.4%" (en).
String fmtPct(num n, {int decimals = 1}) =>
    NumberFormat.decimalPercentPattern(decimalDigits: decimals).format(n / 100);

/// Durée moyenne : Duration -> "2 m 14".
String fmtDuration(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m m ${s.toString().padLeft(2, '0')}';
}

/// « 13 oct. » / « Oct 13 ».
String fmtDay(DateTime t) => DateFormat.MMMd().format(t);

/// « du 7 au 13 oct. » ou « du 28 sept. au 4 oct. ». Le jour seul n'est
/// court que si les deux bornes tombent dans le même mois.
String fmtDayRange(AppLocalizations l10n, DateTime a, DateTime b) {
  final from = a.month == b.month && a.year == b.year
      ? DateFormat.d().format(a)
      : fmtDay(a);
  return l10n.dayRange(from, fmtDay(b));
}

/// Date d'axe selon la granularité. Le switch est exhaustif à dessein : un
/// repli silencieux sur « jour » ferait afficher un axe faux au lieu de faire
/// échouer la compilation.
String fmtAxis(AppLocalizations l10n, DateTime t, TimeUnit unit) => switch (unit) {
  TimeUnit.hour => l10n.chartHour(DateFormat('HH').format(t)),
  TimeUnit.day => DateFormat.d().format(t),
  TimeUnit.month => DateFormat.MMM().format(t),
};
