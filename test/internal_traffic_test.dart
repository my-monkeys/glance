import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/internal_traffic.dart';
import 'package:glance/data/models/models.dart';

void main() {
  group('normDomain', () {
    test('strip schéma, www, chemin et port', () {
      expect(normDomain('https://www.tamdoku.fr/grille'), 'tamdoku.fr');
      expect(normDomain('feet-match.com:443'), 'feet-match.com');
      expect(normDomain('Games.My-Monkey.fr'), 'games.my-monkey.fr');
    });
  });

  group('InternalTraffic.build', () {
    final known = {'a.fr', 'b.fr', 'c.fr'};

    test('ne garde que les referrers suivis, hors self', () {
      final t = InternalTraffic.build({
        'b.fr': const [
          MetricRow(label: 'a.fr', value: 12),
          MetricRow(label: 'google.com', value: 90),
          MetricRow(label: 'www.b.fr', value: 5), // self → exclu
        ],
        'c.fr': const [
          MetricRow(label: 'https://a.fr/', value: 3),
          MetricRow(label: 'b.fr', value: 7),
        ],
      }, known);

      expect(t.total, 22);
      expect(t.flows.length, 3);
      // Émetteurs : a.fr = 15 (12 + 3), b.fr = 7.
      expect(t.sources.first.domain, 'a.fr');
      expect(t.sources.first.total, 15);
      expect(t.sources.first.flows.first.to, 'b.fr');
      // Récepteurs : b.fr = 12, c.fr = 10.
      expect(t.destinations.first.domain, 'b.fr');
      expect(t.destinations.first.total, 12);
    });

    test('vide quand aucun referrer interne', () {
      final t = InternalTraffic.build({
        'a.fr': const [MetricRow(label: 'duckduckgo.com', value: 4)],
      }, known);
      expect(t.isEmpty, true);
      expect(t.total, 0);
    });
  });
}
