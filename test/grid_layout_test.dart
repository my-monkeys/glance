import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/grid_layout.dart';

GridItem _i(String id, {int w = 2, int h = 4, int minW = 1, int minH = 1}) =>
    GridItem(id, w: w, h: h, minW: minW, minH: minH);

void main() {
  group('flowLayout', () {
    test('remplit les rangées de gauche à droite', () {
      final l = flowLayout([_i('a'), _i('b'), _i('c')], 4);
      expect(l['a'], const GridSlot(0, 0, 2, 4));
      expect(l['b'], const GridSlot(2, 0, 2, 4));
      expect(l['c'], const GridSlot(0, 4, 2, 4));
    });

    test('une carte plus large que la grille y est ramenée', () {
      expect(flowLayout([_i('a', w: 6)], 2)['a'], const GridSlot(0, 0, 2, 4));
    });
  });

  group('moveItem', () {
    // a au-dessus de b, sur une colonne de 2.
    final column = {
      'a': const GridSlot(0, 0, 2, 4),
      'b': const GridSlot(0, 4, 2, 4),
    };

    test('descendre une carte de moins que sa voisine ne change rien', () {
      expect(moveItem(column, _i('a'), 0, 3, 2), column);
    });

    test('descendre une carte jusqu\'à sa voisine les échange', () {
      final l = moveItem(column, _i('a'), 0, 4, 2);
      expect(l['b'], const GridSlot(0, 0, 2, 4));
      expect(l['a'], const GridSlot(0, 4, 2, 4));
    });

    test('monter une carte au-dessus de sa voisine les échange', () {
      final l = moveItem(column, _i('b'), 0, 0, 2);
      expect(l['b'], const GridSlot(0, 0, 2, 4));
      expect(l['a'], const GridSlot(0, 4, 2, 4));
    });

    test('une carte posée à côté remonte en haut de sa colonne', () {
      final l = moveItem(
        {'a': const GridSlot(0, 0, 1, 4), 'b': const GridSlot(0, 4, 1, 4)},
        _i('b'),
        1,
        6,
        2,
      );
      expect(l['a'], const GridSlot(0, 0, 1, 4));
      expect(l['b'], const GridSlot(1, 0, 1, 4));
    });

    test('la place est bornée à la grille', () {
      final l = moveItem({'a': const GridSlot(0, 0, 2, 4)}, _i('a'), 5, -3, 4);
      expect(l['a'], const GridSlot(2, 0, 2, 4));
    });
  });

  group('resizeItem', () {
    test('s\'élargir sur une voisine la pousse dessous', () {
      final l = resizeItem(
        {'a': const GridSlot(0, 0, 1, 4), 'b': const GridSlot(1, 0, 1, 4)},
        _i('a'),
        2,
        4,
        2,
      );
      expect(l['a'], const GridSlot(0, 0, 2, 4));
      expect(l['b'], const GridSlot(1, 4, 1, 4));
    });

    test('grandir repousse la carte d\'en dessous, rapetisser la fait remonter', () {
      final grown = resizeItem(
        {'a': const GridSlot(0, 0, 2, 4), 'b': const GridSlot(0, 4, 2, 4)},
        _i('a'),
        2,
        7,
        2,
      );
      expect(grown['b'], const GridSlot(0, 7, 2, 4));
      final shrunk = resizeItem(grown, _i('a'), 2, 2, 2);
      expect(shrunk['b'], const GridSlot(0, 2, 2, 4));
    });

    test('les minimums de la carte sont respectés', () {
      final l = resizeItem(
        {'a': const GridSlot(0, 0, 2, 4)},
        _i('a', minW: 2, minH: 3),
        1,
        1,
        4,
      );
      expect(l['a'], const GridSlot(0, 0, 2, 3));
    });
  });

  group('resolveLayout', () {
    test('sans grille enregistrée : ordre de la liste', () {
      expect(resolveLayout(null, [_i('a'), _i('b')], 2), {
        'a': const GridSlot(0, 0, 2, 4),
        'b': const GridSlot(0, 4, 2, 4),
      });
    });

    test('une nouvelle carte prend la première place libre', () {
      final l = resolveLayout(
        {'a': const GridSlot(0, 0, 2, 4)},
        [_i('a'), _i('b')],
        4,
      );
      expect(l['b'], const GridSlot(2, 0, 2, 4));
    });

    test('une carte retirée laisse remonter les suivantes', () {
      final l = resolveLayout(
        {'a': const GridSlot(0, 0, 2, 4), 'b': const GridSlot(0, 4, 2, 4)},
        [_i('b')],
        2,
      );
      expect(l, {'b': const GridSlot(0, 0, 2, 4)});
    });

    test('des places qui se chevauchent sont séparées', () {
      final l = resolveLayout(
        {'a': const GridSlot(0, 0, 2, 4), 'b': const GridSlot(0, 2, 2, 4)},
        [_i('a'), _i('b')],
        2,
      );
      expect(l['a']!.overlaps(l['b']!), isFalse);
    });
  });

  test('GridSlot : aller-retour JSON, formes invalides écartées', () {
    const s = GridSlot(1, 2, 3, 4);
    expect(GridSlot.fromJson(s.toJson()), s);
    expect(GridSlot.fromJson([1, 2, 3]), isNull);
    expect(GridSlot.fromJson([0, 0, 0, 4]), isNull);
    expect(GridSlot.fromJson('x'), isNull);
  });

  test('readingOrder : de haut en bas, puis de gauche à droite', () {
    expect(
      readingOrder({
        'c': const GridSlot(0, 4, 2, 4),
        'b': const GridSlot(2, 0, 2, 4),
        'a': const GridSlot(0, 0, 2, 4),
      }),
      ['a', 'b', 'c'],
    );
  });
}
