import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/grid_layout.dart';
import '../../theme/motion.dart';
import '../../theme/palette.dart';
import 'editable_card.dart';

/// Hauteur d'une rangée de la grille et espace entre deux cellules.
const double kGridRow = 40;
const double kGridGutter = 14;

/// Rangées vides ajoutées sous les cartes en mode « Organiser », pour pouvoir
/// y poser une carte.
const int _kSpareRows = 3;

/// Grille des tableaux. Hors édition, les cartes sont simplement posées à leur
/// place. En édition, la grille se dessine ; un appui long sur une carte la
/// déplace, son coin bas droit la redimensionne, et les autres cartes
/// s'écartent pendant le geste. [onChanged] reçoit la grille au lâcher.
class DashboardGrid extends StatefulWidget {
  const DashboardGrid({
    super.key,
    required this.columns,
    required this.items,
    required this.layout,
    required this.editing,
    required this.cardBuilder,
    required this.onChanged,
  });

  final int columns;
  final Map<String, GridItem> items;
  final Map<String, GridSlot> layout;
  final bool editing;
  final Widget Function(String id) cardBuilder;
  final ValueChanged<Map<String, GridSlot>> onChanged;

  @override
  State<DashboardGrid> createState() => _DashboardGridState();
}

enum _Mode { move, resize }

/// Geste en cours : la carte suit le doigt, la grille montre où elle tombera.
class _Gesture {
  _Gesture({
    required this.id,
    required this.mode,
    required this.base,
    required this.start,
    required this.grab,
    required this.pointer,
  }) : rect = start;

  final String id;
  final _Mode mode;

  /// Grille au début du geste : chaque aperçu en repart, pour qu'un aller et
  /// retour du doigt rende la grille de départ.
  final Map<String, GridSlot> base;
  final Rect start;

  /// Écart entre le doigt et le coin suivi (haut gauche pour un déplacement,
  /// bas droit pour un redimensionnement).
  final Offset grab;
  Offset pointer;
  Rect rect;
}

/// Conversions entre cellules et pixels, pour une largeur donnée.
class _Metrics {
  _Metrics(this.width, this.columns)
    : colUnit = (width + kGridGutter) / columns;

  final double width;
  final int columns;
  final double colUnit;
  static const double rowUnit = kGridRow + kGridGutter;

  Rect rect(GridSlot s) => Rect.fromLTWH(
    s.x * colUnit,
    s.y * rowUnit,
    s.w * colUnit - kGridGutter,
    s.h * rowUnit - kGridGutter,
  );

  double height(int rows) => rows <= 0 ? 0 : rows * rowUnit - kGridGutter;

  (int, int) cellAt(Offset topLeft) =>
      ((topLeft.dx / colUnit).round(), (topLeft.dy / rowUnit).round());

  (int, int) spanOf(Size size) => (
    ((size.width + kGridGutter) / colUnit).round(),
    ((size.height + kGridGutter) / rowUnit).round(),
  );
}

class _DashboardGridState extends State<DashboardGrid> {
  final _box = GlobalKey();
  _Gesture? _gesture;
  _Metrics? _metrics;
  Timer? _autoScroll;

  /// Grille montrée pendant le geste, puis jusqu'à ce que le parent rende
  /// celle qu'il a enregistrée : sans quoi les cartes repasseraient une image
  /// à leur ancienne place.
  Map<String, GridSlot>? _preview;

  @override
  void didUpdateWidget(DashboardGrid old) {
    super.didUpdateWidget(old);
    if (_gesture == null &&
        (old.columns != widget.columns ||
            !mapEquals(old.layout, widget.layout))) {
      _preview = null;
    }
    // Sortie du mode « Organiser » pendant un geste : on l'abandonne, sans
    // enregistrer (on est en plein build du parent).
    if (!widget.editing && _gesture != null) {
      _autoScroll?.cancel();
      _autoScroll = null;
      _gesture = null;
      _preview = null;
    }
  }

  @override
  void dispose() {
    _autoScroll?.cancel();
    super.dispose();
  }

  RenderBox? get _renderBox =>
      _box.currentContext?.findRenderObject() as RenderBox?;

  void _start(String id, _Mode mode, Offset pointer) {
    final m = _metrics;
    final box = _renderBox;
    if (_gesture != null || m == null || box == null) return;
    final base = _preview ?? widget.layout;
    final rect = m.rect(base[id]!);
    final local = box.globalToLocal(pointer);
    HapticFeedback.mediumImpact();
    setState(() {
      _gesture = _Gesture(
        id: id,
        mode: mode,
        base: base,
        start: rect,
        grab: mode == _Mode.move
            ? local - rect.topLeft
            : rect.bottomRight - local,
        pointer: pointer,
      );
      _preview = base;
    });
    _autoScroll = Timer.periodic(const Duration(milliseconds: 16), _scrollTick);
  }

  void _update(Offset pointer) {
    final g = _gesture;
    if (g == null) return;
    g.pointer = pointer;
    _follow(g);
  }

  /// Place la carte sous le doigt et recalcule la grille.
  void _follow(_Gesture g) {
    final m = _metrics;
    final box = _renderBox;
    if (m == null || box == null) return;
    final local = box.globalToLocal(g.pointer);
    final item = widget.items[g.id]!;
    final Rect rect;
    final Map<String, GridSlot> next;
    if (g.mode == _Mode.move) {
      final topLeft = local - g.grab;
      rect =
          Offset(
            topLeft.dx.clamp(0, math.max(0, m.width - g.start.width)),
            math.max(0, topLeft.dy),
          ) &
          g.start.size;
      final (x, y) = m.cellAt(rect.topLeft);
      next = moveItem(g.base, item, x, y, m.columns);
    } else {
      final corner = local + g.grab;
      final minW = math.min(item.minW, m.columns) * m.colUnit - kGridGutter;
      final minH = item.minH * _Metrics.rowUnit - kGridGutter;
      rect = Rect.fromLTRB(
        g.start.left,
        g.start.top,
        corner.dx.clamp(g.start.left + minW, m.width),
        math.max(corner.dy, g.start.top + minH),
      );
      final (w, h) = m.spanOf(rect.size);
      next = resizeItem(g.base, item, w, h, m.columns);
    }
    setState(() {
      g.rect = rect;
      _preview = next;
    });
  }

  void _end() {
    final g = _gesture;
    if (g == null) return;
    _autoScroll?.cancel();
    _autoScroll = null;
    final next = _preview;
    setState(() {
      _gesture = null;
      if (next == null || mapEquals(next, widget.layout)) _preview = null;
    });
    if (next != null && !mapEquals(next, widget.layout)) widget.onChanged(next);
  }

  /// Près du haut ou du bas de la zone visible, la page défile sous la carte
  /// tenue : sans ça, une carte ne pourrait pas quitter l'écran.
  void _scrollTick(Timer _) {
    final g = _gesture;
    final scrollable = Scrollable.maybeOf(context);
    if (g == null || scrollable == null) return;
    if (axisDirectionToAxis(scrollable.axisDirection) != Axis.vertical) return;
    final viewport = scrollable.context.findRenderObject() as RenderBox?;
    if (viewport == null) return;
    const edge = 72.0;
    const maxStep = 14.0;
    final top = viewport.localToGlobal(Offset.zero).dy;
    final bottom = top + viewport.size.height;
    final y = g.pointer.dy;
    final step = y < top + edge
        ? -maxStep * ((top + edge - y) / edge).clamp(0, 1)
        : y > bottom - edge
        ? maxStep * ((y - bottom + edge) / edge).clamp(0, 1)
        : 0.0;
    if (step == 0) return;
    final pos = scrollable.position;
    final to = (pos.pixels + step).clamp(
      pos.minScrollExtent,
      pos.maxScrollExtent,
    );
    if (to == pos.pixels) return;
    pos.jumpTo(to);
    _follow(g);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final m = _metrics = _Metrics(constraints.maxWidth, widget.columns);
        final layout = _preview ?? widget.layout;
        final g = _gesture;
        var rows = layoutRows(layout.values);
        if (widget.editing) rows += _kSpareRows;
        if (g != null) {
          rows = math.max(rows, (g.rect.bottom / _Metrics.rowUnit).ceil() + 1);
        }
        // La carte tenue passe au-dessus des autres.
        final order = [
          for (final id in layout.keys)
            if (id != g?.id) id,
          ?g?.id,
        ];

        return SizedBox(
          key: _box,
          height: m.height(rows),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (widget.editing)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CellsPainter(
                      metrics: m,
                      rows: rows,
                      color: context.glance.line,
                    ),
                  ),
                ),
              if (g != null)
                AnimatedPositioned.fromRect(
                  duration: kMotionFast,
                  curve: kCurveOut,
                  rect: m.rect(layout[g.id]!),
                  child: const GridLanding(),
                ),
              for (final id in order)
                AnimatedPositioned.fromRect(
                  key: ValueKey(id),
                  // Sous le doigt, la carte suit sans retard ; au lâcher, elle
                  // glisse jusqu'à sa place.
                  duration: id == g?.id ? Duration.zero : kMotionBase,
                  curve: kCurveOutCubic,
                  rect: id == g?.id ? g!.rect : m.rect(layout[id]!),
                  child: widget.editing
                      ? EditableGridCard(
                          lifted: id == g?.id,
                          onMoveStart: (p) => _start(id, _Mode.move, p),
                          onResizeStart: (p) => _start(id, _Mode.resize, p),
                          onUpdate: _update,
                          onEnd: _end,
                          child: widget.cardBuilder(id),
                        )
                      : widget.cardBuilder(id),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Les cellules de la grille, en mode « Organiser ».
class _CellsPainter extends CustomPainter {
  _CellsPainter({
    required this.metrics,
    required this.rows,
    required this.color,
  });

  final _Metrics metrics;
  final int rows;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < metrics.columns; x++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            metrics.rect(GridSlot(x, y, 1, 1)),
            const Radius.circular(8),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CellsPainter old) =>
      old.rows != rows ||
      old.color != color ||
      old.metrics.width != metrics.width ||
      old.metrics.columns != metrics.columns;
}
