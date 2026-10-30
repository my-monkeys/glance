import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../theme/motion.dart';
import '../../theme/palette.dart';

/// Appui avant qu'une carte se soulève : assez long pour qu'un glissement
/// rapide fasse défiler la page, assez court pour ne pas faire attendre.
const Duration _kLiftDelay = Duration(milliseconds: 220);

/// Carte en mode « Organiser » : son contenu ne réagit plus (pas d'infobulle
/// sous le doigt), un appui long la déplace, la poignée du haut la déplace
/// tout de suite, le coin bas droit la redimensionne.
class EditableGridCard extends StatelessWidget {
  const EditableGridCard({
    super.key,
    required this.lifted,
    required this.onMoveStart,
    required this.onResizeStart,
    required this.onUpdate,
    required this.onEnd,
    required this.child,
  });

  final bool lifted;
  final ValueChanged<Offset> onMoveStart;
  final ValueChanged<Offset> onResizeStart;
  final ValueChanged<Offset> onUpdate;
  final VoidCallback onEnd;
  final Widget child;

  /// Zone de prise des poignées : plus large que leur dessin, au doigt.
  static const double _handle = 44;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return AnimatedScale(
      scale: lifted ? 1.03 : 1,
      duration: kMotionFast,
      curve: kCurveOut,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(child: child),
          _DragSurface(
            onStart: onMoveStart,
            onUpdate: onUpdate,
            onEnd: onEnd,
            child: const SizedBox.expand(),
          ),
          Positioned(
            top: 0,
            right: 0,
            width: _handle + 8,
            height: _handle,
            child: _DragSurface(
              immediate: true,
              onStart: onMoveStart,
              onUpdate: onUpdate,
              onEnd: onEnd,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            width: _handle,
            height: _handle,
            child: _DragSurface(
              immediate: true,
              onStart: onResizeStart,
              onUpdate: onUpdate,
              onEnd: onEnd,
              child: Semantics(
                label: 'Redimensionner le tableau',
                child: CustomPaint(painter: _CornerPainter(p.fg3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un geste qui démarre tout de suite ([immediate], poignées : il prend la
/// main sur le défilement de la page) ou après un appui long (carte entière :
/// un glissement rapide fait encore défiler la page).
class _DragSurface extends StatelessWidget {
  const _DragSurface({
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.child,
    this.immediate = false,
  });

  final bool immediate;
  final ValueChanged<Offset> onStart;
  final ValueChanged<Offset> onUpdate;
  final VoidCallback onEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (immediate) {
      return RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          EagerGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                EagerGestureRecognizer.new,
                (_) {},
              ),
        },
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => onStart(e.position),
          onPointerMove: (e) => onUpdate(e.position),
          onPointerUp: (_) => onEnd(),
          onPointerCancel: (_) => onEnd(),
          child: child,
        ),
      );
    }
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(duration: _kLiftDelay),
              (r) => r
                ..onLongPressStart = ((d) => onStart(d.globalPosition))
                ..onLongPressMoveUpdate = ((d) => onUpdate(d.globalPosition))
                ..onLongPressEnd = ((_) => onEnd())
                ..onLongPressCancel = onEnd,
            ),
      },
      child: child,
    );
  }
}

/// Place où la carte tenue tombera si on la lâche.
class GridLanding extends StatelessWidget {
  const GridLanding({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.accentSoft,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: p.accent, width: 1.5),
      ),
    );
  }
}

/// Coin de redimensionnement : deux traits en diagonale, en bas à droite.
class _CornerPainter extends CustomPainter {
  _CornerPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final corner = Offset(size.width - 12, size.height - 12);
    for (final d in const [8.0, 15.0]) {
      canvas.drawLine(corner.translate(-d, 0), corner.translate(0, -d), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}
