import 'package:flutter_test/flutter_test.dart';
import 'package:glance/ui/dashboards/indicator_chart.dart';

void main() {
  group('percentAxisMax', () {
    test('plafonné à 100 tant que les données y tiennent', () {
      expect(percentAxisMax(0), 10);
      expect(percentAxisMax(50), lessThanOrEqualTo(100));
      expect(percentAxisMax(50), greaterThanOrEqualTo(50));
      expect(percentAxisMax(99), 100);
      expect(percentAxisMax(100), 100);
    });

    test('suit les données au-delà de 100 %', () {
      expect(percentAxisMax(125), 160);
      expect(percentAxisMax(260), 320);
      expect(percentAxisMax(125), greaterThan(125));
      expect(percentAxisMax(260), greaterThan(260));
    });
  });
}
