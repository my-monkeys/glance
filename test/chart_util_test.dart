import 'package:flutter_test/flutter_test.dart';
import 'package:glance/ui/widgets/chart_util.dart';

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
}
