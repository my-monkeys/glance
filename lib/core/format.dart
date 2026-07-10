import 'package:intl/intl.dart';

final _frNum = NumberFormat.decimalPattern('fr_FR');

/// 1204 -> "1 204", 1204000 -> "1,2 M" au-delà de 100 000 pour rester lisible.
String fmtCount(num n) {
  if (n >= 1000000) {
    return '${_frNum.format((n / 1000000))} M'
        .replaceAll(RegExp(r'(\.\d).*M'), r'$1 M');
  }
  if (n >= 100000) {
    final v = n / 1000;
    return '${v.toStringAsFixed(0)} k';
  }
  return _frNum.format(n.round());
}

/// Format compact simple (chiffres bruts avec séparateur de milliers).
String fmtInt(num n) => _frNum.format(n.round());

/// Delta signé en pourcentage : 8.4 -> "8,4 %".
String fmtPct(num n, {int decimals = 1}) {
  final s = n.toStringAsFixed(decimals).replaceAll('.', ',');
  return '$s %';
}

/// Durée moyenne : Duration -> "2 m 14".
String fmtDuration(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m m ${s.toString().padLeft(2, '0')}';
}

/// Formatte une date d'axe selon la granularité.
String fmtAxis(DateTime t, String unit) {
  switch (unit) {
    case 'hour':
      return '${DateFormat('HH', 'fr_FR').format(t)}h';
    case 'month':
      return DateFormat('MMM', 'fr_FR').format(t);
    case 'day':
    default:
      return DateFormat('d', 'fr_FR').format(t);
  }
}
