import 'package:flutter/foundation.dart';

/// Granularité des points de série renvoyés par le provider.
enum TimeUnit { hour, day, month }

extension TimeUnitApi on TimeUnit {
  String get api => switch (this) {
    TimeUnit.hour => 'hour',
    TimeUnit.day => 'day',
    TimeUnit.month => 'month',
  };
}

/// Fenêtre temporelle résolue à un instant donné.
@immutable
class DateWindow {
  const DateWindow(this.start, this.end, this.unit);
  final DateTime start;
  final DateTime end;
  final TimeUnit unit;

  int get startMs => start.millisecondsSinceEpoch;
  int get endMs => end.millisecondsSinceEpoch;

  @override
  bool operator ==(Object other) =>
      other is DateWindow &&
      other.startMs == startMs &&
      other.endMs == endMs &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(startMs, endMs, unit);
}

/// Périodes de la maquette. Les bornes sont calculées à la volée (dépendent de
/// « maintenant »).
enum Period {
  today('today', "Aujourd'hui"),
  h24('24h', '24 h'),
  d7('7j', '7 jours'),
  d30('30j', '30 j'),
  m12('12m', '12 m'),
  custom('perso', 'Perso');

  const Period(this.key, this.label);
  final String key;
  final String label;

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Plafond de [d] au début de l'unité suivante. La fenêtre est ainsi alignée
  /// sur la grille (heure/jour/mois) : sa clé reste stable pendant toute l'unité
  /// courante, donc l'auto-refresh réutilise le même provider (pas de flash ni
  /// d'accumulation d'instances). Le bucket courant grandit au fil des données.
  static DateTime _ceil(DateTime d, TimeUnit u) => switch (u) {
    TimeUnit.hour => DateTime(d.year, d.month, d.day, d.hour + 1),
    TimeUnit.day => DateTime(d.year, d.month, d.day + 1),
    TimeUnit.month => DateTime(d.year, d.month + 1, 1),
  };

  /// Résout la fenêtre. Pour [custom], passer [customStart]/[customEnd].
  DateWindow window({DateTime? now, DateTime? customStart, DateTime? customEnd}) {
    final n = now ?? DateTime.now();
    switch (this) {
      case Period.today:
        return DateWindow(_startOfDay(n), _ceil(n, TimeUnit.hour), TimeUnit.hour);
      case Period.h24:
        final end = _ceil(n, TimeUnit.hour);
        return DateWindow(
          end.subtract(const Duration(hours: 24)),
          end,
          TimeUnit.hour,
        );
      case Period.d7:
        final end = _ceil(n, TimeUnit.day);
        return DateWindow(
          end.subtract(const Duration(days: 7)),
          end,
          TimeUnit.day,
        );
      case Period.d30:
        final end = _ceil(n, TimeUnit.day);
        return DateWindow(
          end.subtract(const Duration(days: 30)),
          end,
          TimeUnit.day,
        );
      case Period.m12:
        return DateWindow(
          DateTime(n.year, n.month - 11, 1),
          _ceil(n, TimeUnit.month),
          TimeUnit.month,
        );
      case Period.custom:
        final s = customStart ?? _startOfDay(n).subtract(const Duration(days: 29));
        final e = customEnd ?? n;
        final span = e.difference(s);
        final unit = span.inDays <= 2
            ? TimeUnit.hour
            : (span.inDays > 120 ? TimeUnit.month : TimeUnit.day);
        return DateWindow(s, e, unit);
    }
  }

  static Period fromKey(String k) =>
      Period.values.firstWhere((p) => p.key == k, orElse: () => Period.d7);
}
