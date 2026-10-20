import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/indicator_math.dart';
import 'package:glance/data/models/models.dart';

List<SeriesPoint> _s(List<double> v) => [
      for (var i = 0; i < v.length; i++) SeriesPoint(DateTime(2026, 1, 1 + i), v[i], 0),
    ];

void main() {
  test('dénominateur nul : 0 par défaut', () {
    final r = ratioOf(_s([1, 0, 3]), _s([2, 0, 4]));
    expect(r.points.map((p) => p.value), [0.5, 0.0, 0.75]);
  });

  test('dénominateur nul : trou avec gapsWhenEmpty', () {
    final r = ratioOf(_s([1, 0, 3]), _s([2, 0, 4]), gapsWhenEmpty: true);
    expect(r.points.map((p) => p.value), [0.5, null, 0.75]);
  });

  test('le global ne dépend pas du choix', () {
    final a = ratioOf(_s([1, 0]), _s([2, 0]));
    final b = ratioOf(_s([1, 0]), _s([2, 0]), gapsWhenEmpty: true);
    expect(a.overall, 0.5);
    expect(b.overall, 0.5);
  });

  test('global = ratio des sommes, pas moyenne des ratios', () {
    // 3/3 le premier jour, 10/300 le second : moyenne des ratios = 0,52,
    // ratio des sommes = 13/303.
    final r = ratioOf(_s([3, 10]), _s([3, 300]));
    expect(r.overall, closeTo(13 / 303, 1e-9));
    expect(r.numeratorTotal, 13);
    expect(r.denominatorTotal, 303);
  });

  test('tout à zéro : global nul', () {
    final r = ratioOf(_s([0, 0]), _s([0, 0]));
    expect(r.overall, isNull);
    expect(r.points.every((p) => p.value == 0.0), isTrue);
  });
}
