import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/site_search.dart';
import 'package:glance/data/models/models.dart';

Site _site(String name, String domain) =>
    Site(id: name, accountId: 'a', name: name, domain: domain);

void main() {
  final geo = _site('GeoDaily (app)', 'geodaily-app.fr');
  final cafe = _site('Café Écran', 'cafe-ecran.com');

  test('requête vide : tout passe', () {
    expect(siteMatches(geo, ''), isTrue);
    expect(siteMatches(geo, '   '), isTrue);
  });

  test('casse et accents ignorés, dans les deux sens', () {
    expect(siteMatches(cafe, 'cafe'), isTrue);
    expect(siteMatches(cafe, 'ÉCRAN'), isTrue);
    expect(siteMatches(_site('Cafe', 'x.fr'), 'café'), isTrue);
  });

  test('cherche aussi dans le domaine', () {
    expect(siteMatches(cafe, '.com'), isTrue);
    expect(siteMatches(geo, 'geodaily-app'), isTrue);
  });

  test('chaque mot doit figurer, dans n\'importe quel ordre', () {
    expect(siteMatches(geo, 'app geo'), isTrue);
    expect(siteMatches(geo, 'geo web'), isFalse);
  });

  test('filterSites garde l\'ordre d\'origine', () {
    expect(filterSites([cafe, geo], 'a'), [cafe, geo]);
    expect(filterSites([cafe, geo], 'daily'), [geo]);
  });
}
