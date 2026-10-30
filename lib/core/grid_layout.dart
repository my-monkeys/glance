import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Place d'une carte dans la grille des tableaux, en cellules : colonne,
/// rangée, largeur, hauteur.
@immutable
class GridSlot {
  const GridSlot(this.x, this.y, this.w, this.h);

  final int x;
  final int y;
  final int w;
  final int h;

  int get bottom => y + h;

  bool overlaps(GridSlot o) =>
      x < o.x + o.w && o.x < x + w && y < o.bottom && o.y < bottom;

  GridSlot copyWith({int? x, int? y, int? w, int? h}) =>
      GridSlot(x ?? this.x, y ?? this.y, w ?? this.w, h ?? this.h);

  List<int> toJson() => [x, y, w, h];

  /// Une forme inattendue rend null : la carte est alors replacée d'office.
  static GridSlot? fromJson(Object? j) {
    if (j is! List || j.length != 4 || j.any((v) => v is! int)) return null;
    final [x, y, w, h] = j.cast<int>();
    if (x < 0 || y < 0 || w < 1 || h < 1) return null;
    return GridSlot(x, y, w, h);
  }

  @override
  bool operator ==(Object other) =>
      other is GridSlot &&
      other.x == x &&
      other.y == y &&
      other.w == w &&
      other.h == h;

  @override
  int get hashCode => Object.hash(x, y, w, h);

  @override
  String toString() => 'GridSlot($x, $y, $w×$h)';
}

/// Taille d'une carte quand rien n'est enregistré, et ses minimums.
@immutable
class GridItem {
  const GridItem(
    this.id, {
    required this.w,
    required this.h,
    this.minW = 1,
    this.minH = 1,
  });

  final String id;
  final int w;
  final int h;
  final int minW;
  final int minH;
}

/// Ramène une place dans la grille et au-dessus des minimums de sa carte.
GridSlot fitSlot(GridSlot s, GridItem item, int columns) {
  final w = _clamp(s.w, math.min(item.minW, columns), columns);
  return GridSlot(
    _clamp(s.x, 0, columns - w),
    math.max(0, s.y),
    w,
    math.max(s.h, item.minH),
  );
}

int _clamp(int v, int lo, int hi) => math.min(math.max(v, lo), hi);

/// Dispose des cartes dans l'ordre de lecture, chacune à la première place
/// libre (de haut en bas, puis de gauche à droite).
Map<String, GridSlot> flowLayout(List<GridItem> items, int columns) {
  final placed = <String, GridSlot>{};
  for (final i in items) {
    placed[i.id] = _firstFree(i, placed.values, columns);
  }
  return placed;
}

GridSlot _firstFree(GridItem item, Iterable<GridSlot> placed, int columns) {
  final w = _clamp(item.w, math.min(item.minW, columns), columns);
  final h = math.max(item.h, item.minH);
  for (var y = 0; ; y++) {
    for (var x = 0; x + w <= columns; x++) {
      final s = GridSlot(x, y, w, h);
      if (!placed.any(s.overlaps)) return s;
    }
  }
}

/// Disposition à afficher : l'enregistrée pour les cartes qu'elle connaît,
/// une place libre pour les nouvelles, puis tout est tassé vers le haut.
Map<String, GridSlot> resolveLayout(
  Map<String, GridSlot>? stored,
  List<GridItem> items,
  int columns,
) {
  if (stored == null) return flowLayout(items, columns);
  final placed = <String, GridSlot>{
    for (final i in items)
      if (stored[i.id] case final s?) i.id: fitSlot(s, i, columns),
  };
  // Deux places enregistrées peuvent se chevaucher après un ajustement à une
  // grille plus étroite : le tassement les sépare avant d'ajouter les autres.
  final settled = settleLayout(placed);
  for (final i in items) {
    if (!settled.containsKey(i.id)) {
      settled[i.id] = _firstFree(i, settled.values, columns);
    }
  }
  return settleLayout(settled);
}

/// Déplace une carte. La carte déplacée passe après celles dont le centre
/// est au-dessus du sien : la descendre sur une voisine les échange dès que
/// son centre dépasse celui de la voisine.
Map<String, GridSlot> moveItem(
  Map<String, GridSlot> layout,
  GridItem item,
  int x,
  int y,
  int columns,
) {
  final from = layout[item.id]!;
  final to = fitSlot(from.copyWith(x: x, y: y), item, columns);
  return settleLayout(
    {...layout, item.id: to},
    lead: item.id,
    leadKey: _centerKey(to),
    leadAfterTies: to.y > from.y,
  );
}

/// Redimensionne une carte : elle garde son coin haut gauche et repousse
/// vers le bas ce qu'elle recouvre.
Map<String, GridSlot> resizeItem(
  Map<String, GridSlot> layout,
  GridItem item,
  int w,
  int h,
  int columns,
) {
  final from = layout[item.id]!;
  final to = fitSlot(from.copyWith(w: w, h: h), item, columns);
  return settleLayout(
    {...layout, item.id: to},
    lead: item.id,
    // Par son haut, pas par son centre : en s'élargissant sur une colonne
    // voisine, la carte doit pousser sa voisine, pas passer dessous.
    leadKey: 2 * to.y,
  );
}

/// Centre vertical, doublé pour rester entier.
int _centerKey(GridSlot s) => 2 * s.y + s.h;

/// Tasse la grille vers le haut, carte par carte, dans l'ordre de leur
/// centre : une carte qui en recouvre une déjà posée passe dessous, puis
/// chacune remonte jusqu'à toucher une autre carte. [lead] (la carte qu'on
/// manipule) est rangée selon [leadKey], avant les cartes de même rang, ou
/// après si [leadAfterTies].
Map<String, GridSlot> settleLayout(
  Map<String, GridSlot> layout, {
  String? lead,
  int? leadKey,
  bool leadAfterTies = false,
}) {
  int key(MapEntry<String, GridSlot> e) =>
      e.key == lead && leadKey != null ? leadKey : _centerKey(e.value);
  final order = layout.entries.toList()
    ..sort((a, b) {
      final byKey = key(a).compareTo(key(b));
      if (byKey != 0) return byKey;
      if (a.key == lead) return leadAfterTies ? 1 : -1;
      if (b.key == lead) return leadAfterTies ? -1 : 1;
      return a.value.x.compareTo(b.value.x);
    });

  final placed = <String, GridSlot>{};
  for (final e in order) {
    var s = e.value;
    while (true) {
      final hits = placed.values.where(s.overlaps);
      if (hits.isEmpty) break;
      s = s.copyWith(y: hits.map((o) => o.bottom).reduce(math.max));
    }
    while (s.y > 0 && !placed.values.any(s.copyWith(y: s.y - 1).overlaps)) {
      s = s.copyWith(y: s.y - 1);
    }
    placed[e.key] = s;
  }
  return placed;
}

/// Nombre de rangées occupées.
int layoutRows(Iterable<GridSlot> slots) =>
    slots.fold(0, (m, s) => math.max(m, s.bottom));

/// Identifiants dans l'ordre de lecture : de haut en bas, puis de gauche à
/// droite.
List<String> readingOrder(Map<String, GridSlot> layout) {
  final entries = layout.entries.toList()
    ..sort((a, b) {
      final byY = a.value.y.compareTo(b.value.y);
      return byY != 0 ? byY : a.value.x.compareTo(b.value.x);
    });
  return [for (final e in entries) e.key];
}
