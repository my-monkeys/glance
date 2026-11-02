import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/models/indicator.dart';
import 'package:glance/l10n/app_localizations_fr.dart';
import 'package:glance/ui/dashboards/labels.dart';

EventFilter _f(String p, FilterOp op, String v,
        [PropertyType t = PropertyType.string]) =>
    EventFilter(property: p, type: t, op: op, value: v);

final l10n = AppLocalizationsFr();

void main() {
  test('sans filtre, le seul nom de l\'événement', () {
    expect(queryLabel(l10n, const EventQuery('partie_demarree')), 'partie_demarree');
    expect(filtersSummary(l10n, const []), '');
  });

  test('un filtre', () {
    final q = EventQuery('partie_terminee', [_f('issue', FilterOp.eq, 'complet')]);
    expect(queryLabel(l10n, q), 'partie_terminee · issue = complet');
  });

  test('plusieurs filtres, opérateurs lisibles', () {
    final fs = [
      _f('part', FilterOp.gte, '50', PropertyType.number),
      _f('jeu', FilterOp.neq, 'flags'),
    ];
    expect(filtersSummary(l10n, fs), "part ≥ 50, jeu ≠ flags");
  });
}
