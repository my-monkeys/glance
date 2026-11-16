import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/format.dart';
import 'package:glance/data/models/period.dart';
import 'package:glance/l10n/app_localizations_fr.dart';
import 'package:glance/ui/dashboards/labels.dart';
import 'package:glance/ui/widgets/chart_util.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  group('chartNiceMax', () {
    test('valeurs de référence', () {
      expect(chartNiceMax(0), 8);
      expect(chartNiceMax(185), 240);
      expect(chartNiceMax(9), 12);
      expect(chartNiceMax(1000), 1200);
      expect(chartNiceMax(3500), 4800);
    });

    test('sous 1 : échelle fractionnaire, avec marge', () {
      expect(chartNiceMax(0.5), greaterThanOrEqualTo(0.5 * 1.15));
      expect(chartNiceMax(0.5), lessThan(1));
    });

    test('marge, quarts entiers, vide borné', () {
      for (var m = 1; m <= 100000; m++) {
        final max = chartNiceMax(m.toDouble());
        expect(max, greaterThanOrEqualTo(m * 1.15), reason: 'm=$m');
        expect(max % 4, 0, reason: 'm=$m : max/4 doit être entier');
        // Dès 10, deux paliers voisins diffèrent d'au plus 1/3 (60 → 80) ;
        // sous 10 il n'y a que 4, 8 et 12, pas de borne utile.
        if (m >= 10) {
          expect(max, lessThanOrEqualTo(m * 1.15 * 1.34), reason: 'm=$m');
        }
      }
    });
  });

  group('semaine', () {
    final l10n = AppLocalizationsFr();
    final monday = DateTime(2026, 11, 9);

    setUpAll(() async {
      await initializeDateFormatting('fr');
      Intl.defaultLocale = 'fr';
    });
    tearDownAll(() => Intl.defaultLocale = null);

    test('infobulle : « Semaine du … », « en cours » pour la semaine de now', () {
      expect(chartWeekLabel(l10n, monday, DateTime(2026, 11, 13)), 'Semaine du 9 nov. · en cours');
      expect(chartWeekLabel(l10n, monday, DateTime(2026, 11, 16)), 'Semaine du 9 nov.');
      expect(chartWeekLabel(l10n, monday, DateTime(2026, 11, 8)), 'Semaine du 9 nov.');
    });

    test('axe : quatre libellés, jamais collés au dernier', () {
      List<int> shown(int len, {bool weekly = true}) => [
            for (var i = 0; i < len; i++)
              if (axisLabelShown(i, len, weekly: weekly)) i,
          ];
      expect(shown(5), [0, 2, 4]);
      expect(shown(6), [0, 2, 5]);
      expect(shown(52), [0, 13, 26, 51]);
      expect(shown(1), [0]);
      // En jours, rien ne change : un sur ceil(len / 6), plus le dernier.
      expect(shown(30, weekly: false), [0, 5, 10, 15, 20, 25, 29]);
    });

    test('axe : jour et mois abrégé', () {
      expect(fmtAxis(l10n, DateTime(2026, 10, 5), TimeUnit.day, weekly: true), '5 oct.');
    });

    test('sous-titre d\'un compteur « dernier »', () {
      String label(DateTime t, bool ongoing, TimeUnit u, {bool weekly = false}) =>
          latestLabel(l10n, (t: t, ongoing: ongoing), u, weekly: weekly);
      expect(label(monday, true, TimeUnit.day, weekly: true), 'Semaine du 9 nov. · en cours');
      expect(label(DateTime(2026, 11, 2), false, TimeUnit.day, weekly: true), 'Semaine du 2 nov.');
      expect(label(DateTime(2026, 11, 13), false, TimeUnit.day), '13 nov.');
      expect(label(DateTime(2026, 11), true, TimeUnit.month), 'novembre 2026 · en cours');
    });
  });
}
