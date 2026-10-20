import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/models/period.dart';
import 'package:glance/theme/palette.dart';
import 'package:glance/ui/widgets/chart_model.dart';
import 'package:glance/ui/widgets/chart_util.dart';

// Des pages vues bien au-dessus des visiteurs : le cas qui écrasait la courbe.
final _series = [
  for (var i = 0; i < 6; i++)
    SeriesPoint(DateTime(2026, 10, 1 + i), 10.0 + i * 30, 90.0 + i * 700),
];

ChartModel _model({Set<String> hidden = const {}}) => ChartModel.from(
      series: _series,
      unit: TimeUnit.day,
      showPageviews: true,
      hidden: hidden,
      palette: GlancePalette.light,
    );

ChartSeries _views(ChartModel m) =>
    m.drawn.firstWhere((s) => s.role == ChartSeriesRole.pageviews);

void main() {
  test('deux courbes : les pages vues ont leur échelle à droite', () {
    final m = _model();
    expect(m.hasRightAxis, isTrue);
    expect(m.maxY, chartNiceMax(160));
    expect(m.rightMaxY, chartNiceMax(3590));
  });

  test('les pages vues ramenées à gauche tiennent dans le cadre', () {
    final m = _model();
    final s = _views(m);
    for (final v in s.values) {
      expect(m.toPlot(s, v), lessThanOrEqualTo(m.maxY));
      expect(m.fromPlot(s, m.toPlot(s, v)), closeTo(v, 1e-9));
    }
  });

  test('les visiteurs ne sont jamais ramenés', () {
    final m = _model();
    final s = m.drawn.firstWhere((s) => s.role == ChartSeriesRole.visitors);
    expect(m.toPlot(s, 42), 42);
  });

  test('pages vues masquées : un seul axe, celui des visiteurs', () {
    final m = _model(hidden: {ChartModel.kPageviewsKey});
    expect(m.hasRightAxis, isFalse);
    expect(m.maxY, chartNiceMax(160));
  });

  test('visiteurs masqués : les pages vues seules sur l\'axe de gauche', () {
    final m = _model(hidden: {ChartModel.kVisitorsKey});
    expect(m.hasRightAxis, isFalse);
    expect(m.maxY, chartNiceMax(3590));
    final s = _views(m);
    expect(m.toPlot(s, 500), 500);
  });
}
