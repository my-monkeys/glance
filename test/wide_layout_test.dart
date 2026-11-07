import 'package:flutter_test/flutter_test.dart';
import 'package:glance/ui/detail/metric_sections.dart';
import 'package:glance/ui/widgets/chart_util.dart';

void main() {
  group('sections de données : nombre de colonnes', () {
    test('téléphone : une colonne', () {
      expect(MetricSectionGrid.columnsFor(350), 1);
    });

    test('jamais trois : la place pour trois donne deux colonnes (2 × 2)', () {
      expect(MetricSectionGrid.columnsFor(700), 2);
      expect(MetricSectionGrid.columnsFor(1000), 2);
    });

    test('grand écran : les quatre sections sur une ligne', () {
      expect(MetricSectionGrid.columnsFor(1250), 4);
      expect(MetricSectionGrid.columnsFor(1800), 4);
    });
  });

  group('hauteur des grands graphiques', () {
    test('téléphone et petit bureau : la hauteur de base', () {
      expect(chartHeightFor(350, base: 172), 172);
      expect(chartHeightFor(860, base: 172), 172);
    });

    test('grand écran : un cinquième de la largeur, plafonné', () {
      expect(chartHeightFor(1200, base: 172), 240);
      expect(chartHeightFor(1800, base: 172), 360);
      expect(chartHeightFor(3000, base: 172), 360);
    });
  });
}
