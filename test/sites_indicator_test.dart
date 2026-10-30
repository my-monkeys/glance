import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/sites_visitors.dart';
import 'package:glance/data/models/indicator.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/data/models/workspace.dart';
import 'package:glance/ui/dashboards/editor/draft.dart';

final _days = [DateTime(2026, 10, 29), DateTime(2026, 10, 30)];

SiteVisitors _v(List<double> perDay, int total) => (
      points: [for (final (i, t) in _days.indexed) SeriesPoint(t, perDay[i], 0)],
      total: total,
    );

const _app = SiteRef('a', 'app');
const _geo = SiteRef('a', 'geo');

void main() {
  test('sauf un référent : soustraction par jour et sur la période', () {
    final geo = visitorsExcept(_v([300, 211], 511), _v([46, 30], 75));
    expect(geo.points.map((p) => p.visitors), [254, 181]);
    expect(geo.total, 436);
    // Jamais négatif, même si les deux comptes divergent un peu.
    expect(visitorsExcept(_v([1, 0], 1), _v([2, 0], 2)).total, 0);
  });

  test('les lignes deviennent les parts d\'un compteur, total = somme', () {
    const lines = [
      SiteLine(site: _app, label: 'Appli'),
      SiteLine(site: _geo, label: 'Site', mode: ReferrerMode.except, referrer: 'alldle.net'),
      SiteLine(site: _geo, label: 'Alldle', mode: ReferrerMode.only, referrer: 'alldle.net'),
    ];
    final d = sitesCounterOf(lines, [
      _v([50, 44], 94),
      _v([254, 181], 436),
      _v([46, 30], 75),
    ]);
    expect(d.total, 94 + 436 + 75);
    expect(d.points.map((p) => p.visitors), [350, 255]);
    expect(d.segments.map((s) => s.label), ['Appli', 'Site', 'Alldle']);
    expect(d.segments[2].values, [46, 30]);
    expect(d.segments[1].periodTotal, 436);
  });

  test('JSON : aller-retour, référent omis pour « tous »', () {
    const i = SitesIndicator(id: 'x', name: 'Visiteurs', lines: [
      SiteLine(site: _app, label: 'Appli'),
      SiteLine(site: _geo, label: 'Site', mode: ReferrerMode.except, referrer: 'alldle.net'),
    ]);
    final json = i.toJson();
    expect((json['lines'] as List).first, isNot(contains('mode')));
    expect(Indicator.fromJson(json), i);
  });

  group('brouillon', () {
    test('choisir « Sites » ouvre une ligne à remplir', () {
      final d = const IndicatorDraft().withKind(IndicatorKind.sites);
      expect(d.siteLines, [kEmptySiteLine]);
      expect(d.validationError(), 'Choisissez le site de chaque ligne');
    });

    test('validation et référent ramené à son domaine', () {
      var d = const IndicatorDraft(kind: IndicatorKind.sites, siteLines: [
        SiteLine(site: _geo, label: 'Alldle', mode: ReferrerMode.only),
      ]);
      expect(d.validationError(), 'Indiquez le domaine du référent');

      d = d.copyWith(siteLines: [
        d.siteLines.single.copyWith(referrer: ' https://www.Alldle.net/jeux '),
      ]);
      expect(d.validationError(), isNull);
      final i = d.toIndicator('id') as SitesIndicator;
      expect(i.lines.single.referrer, 'alldle.net');
      expect(i.name, 'Alldle');
    });

    test('nom proposé : les libellés, séparés', () {
      const d = IndicatorDraft(kind: IndicatorKind.sites, siteLines: [
        SiteLine(site: _app, label: 'Appli'),
        SiteLine(site: _geo, label: 'Site'),
      ]);
      expect(d.suggestedName(), 'Appli · Site');
    });
  });
}
