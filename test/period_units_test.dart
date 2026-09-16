import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/period.dart';

void main() {
  // Un mardi ordinaire, en milieu de mois et de journée.
  final now = DateTime(2026, 9, 16, 14, 30);

  group('granularité forcée', () {
    test(
        'la fenêtre reste alignée sur la granularité demandée, jamais sur '
        'celle de la période', () {
      // « Ce mois-ci » en heures : sans réalignement, la fin resterait calée
      // sur le jour et traînerait des heures futures à zéro.
      final w = Period.thisMonth.window(now: now, unit: TimeUnit.hour);
      expect(w.unit, TimeUnit.hour);
      expect(w.start, DateTime(2026, 9, 1));
      expect(w.end, DateTime(2026, 9, 16, 15));
    });

    test('une journée en granularité jour tient quand même un bucket entier',
        () {
      // Sans réalignement, start et end tomberaient dans le même jour et la
      // série serait vide — un graphe blanc, sans erreur.
      final w = Period.today.window(now: now, unit: TimeUnit.day);
      expect(w.start, DateTime(2026, 9, 16));
      expect(w.end, DateTime(2026, 9, 17));
      expect(w.bucketCount, 1);
    });

    test('la granularité fait partie de l\'identité de la fenêtre', () {
      final a = Period.d30.window(now: now);
      final b = Period.d30.window(now: now, unit: TimeUnit.hour);
      expect(a == b, isFalse);
      expect(a.hashCode == b.hashCode, isFalse);
    });
  });

  group('allowedUnits', () {
    test('aujourd\'hui : l\'heure seule, donc pas de sélecteur', () {
      expect(allowedUnits(Period.today.window(now: now)), [TimeUnit.hour]);
    });

    test('7 jours et 30 jours : heure ou jour, comme Umami', () {
      expect(
        allowedUnits(Period.d7.window(now: now)),
        [TimeUnit.hour, TimeUnit.day],
      );
      expect(
        allowedUnits(Period.d30.window(now: now)),
        [TimeUnit.hour, TimeUnit.day],
      );
    });

    test('12 mois : le mois seul (l\'heure y ferait 8 760 points)', () {
      expect(allowedUnits(Period.m12.window(now: now)), [TimeUnit.month]);
    });

    test('l\'unité affichée figure toujours dans la liste', () {
      // Une année en cours au 16 septembre : la règle ne propose que le mois,
      // mais si l'utilisateur a forcé le jour, le sélecteur doit le montrer.
      final w = Period.thisYear.window(now: now, unit: TimeUnit.day);
      expect(allowedUnits(w), contains(TimeUnit.day));
    });

    test('le plafond de buckets écarte les découpages illisibles', () {
      final w = Period.thisYear.window(now: now);
      for (final u in allowedUnits(w)) {
        expect(DateWindow(w.start, w.end, u).bucketCount, lessThanOrEqualTo(800));
      }
    });
  });

  group('période personnalisée', () {
    test('le dernier jour choisi figure dans la fenêtre', () {
      // Les écrans passent la fin de sélection à 23 h 59 ; sans plafonnement,
      // le bucket de ce jour-là n'est jamais demandé.
      final w = Period.custom.window(
        now: now,
        customStart: DateTime(2026, 9, 1),
        customEnd: DateTime(2026, 9, 10, 23, 59),
      );
      expect(w.unit, TimeUnit.day);
      expect(w.end, DateTime(2026, 9, 11));
    });
  });

  group('période « Tout »', () {
    test('sans date de première donnée : cadrage large, marqué allTime', () {
      final w = Period.allTime.window(now: now);
      expect(w.allTime, isTrue);
      expect(w.start.year, 2016);
      expect(w.unit, TimeUnit.month);
    });

    test('avec la date de première donnée : la fenêtre part de là', () {
      final w = Period.allTime.window(
        now: now,
        allTimeStart: DateTime(2026, 7, 4, 19, 3, 35),
      );
      // Tronquée sur la grille de l'unité retenue : la clé reste la même que
      // la date vienne du réseau ou des préférences, à la milliseconde près.
      expect(w.unit, TimeUnit.day); // moins de 6 mois d'historique
      expect(w.start, DateTime(2026, 7, 4));
      expect(w.allTime, isTrue);
    });

    test('la fin ne vient jamais de l\'API : elle reste alignée sur la grille',
        () {
      final w = Period.allTime.window(
        now: now,
        allTimeStart: DateTime(2019, 3, 14),
      );
      expect(w.end, DateTime(2026, 10, 1));
      expect(w.unit, TimeUnit.month); // plus de 6 mois d'historique
    });
  });
}
