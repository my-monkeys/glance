import 'package:flutter/material.dart';

import '../../theme/motion.dart';

/// Swap fondu + léger glissement vertical entre deux sous-arbres.
/// L'enfant doit porter une [Key] différente par état (`ValueKey(état)`)
/// pour déclencher la transition — sinon simple rebuild en place.
class GlanceSwap extends StatelessWidget {
  const GlanceSwap({
    super.key,
    required this.child,
    this.duration = kMotionBase,
    this.dy = 6.0,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final Duration duration;

  /// Décalage d'entrée en px logiques (0 = fondu pur). En px fixes plutôt
  /// qu'en fraction : l'amplitude ne doit pas dépendre de la hauteur de
  /// l'enfant (un message d'erreur et un écran entier bougent pareil).
  final double dy;

  /// Ancre des enfants pendant la transition. topCenter par défaut : le
  /// défaut d'AnimatedSwitcher (center) fait « sauter » le contenu quand les
  /// deux enfants n'ont pas la même hauteur.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: kCurveOutCubic,
      switchOutCurve: kCurveOut,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: dy == 0
            ? child
            : AnimatedBuilder(
                animation: anim,
                builder: (_, c) => Transform.translate(
                  offset: Offset(0, (1 - anim.value) * dy),
                  child: c,
                ),
                child: child,
              ),
      ),
      layoutBuilder: (current, previous) => Stack(
        clipBehavior: Clip.none,
        alignment: alignment,
        children: [...previous, ?current],
      ),
      child: child,
    );
  }
}

/// Remplaçant animé d'[IndexedStack] : tous les enfants restent montés
/// (scroll, timers, état local préservés), les inactifs sont en [Offstage]
/// (ni layout ni paint), [TickerMode] coupe leurs animations, [IgnorePointer]
/// leurs interactions, [ExcludeSemantics] leur lecture d'écran.
///
/// Le crossfade est piloté par un contrôleur du PARENT, hors de la portée du
/// TickerMode des enfants : des animations implicites dans le sous-arbre
/// seraient gelées net quand son TickerMode se coupe → l'écran sortant
/// resterait affiché en surimpression.
class GlanceFadeIndexedStack extends StatefulWidget {
  const GlanceFadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = kMotionBase,
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

  @override
  State<GlanceFadeIndexedStack> createState() => _GlanceFadeIndexedStackState();
}

class _GlanceFadeIndexedStackState extends State<GlanceFadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration, value: 1);
  late final CurvedAnimation _in =
      CurvedAnimation(parent: _controller, curve: kCurveOut);
  late final Animation<Offset> _slide =
      Tween(begin: const Offset(0, 0.006), end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: kCurveOutCubic));

  /// Onglet sortant, encore peint (en fondu inverse) tant que ça anime.
  int? _leaving;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _leaving != null) {
        setState(() => _leaving = null);
      }
    });
  }

  @override
  void didUpdateWidget(GlanceFadeIndexedStack old) {
    super.didUpdateWidget(old);
    if (widget.index != old.index) {
      _leaving = old.index;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _in.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _wrap(i, widget.children[i]),
      ],
    );
  }

  Widget _wrap(int i, Widget child) {
    final active = i == widget.index;
    final leaving = i == _leaving;
    final shown = ExcludeSemantics(
      excluding: !active,
      child: IgnorePointer(
        ignoring: !active,
        child: TickerMode(enabled: active, child: child),
      ),
    );
    if (active) {
      return SlideTransition(
        position: _slide,
        child: FadeTransition(opacity: _in, child: shown),
      );
    }
    if (leaving) {
      return FadeTransition(opacity: ReverseAnimation(_in), child: shown);
    }
    return Offstage(child: shown);
  }
}

/// Apparition/disparition d'une section conditionnelle : la hauteur s'ouvre
/// pendant que le contenu fond. Les espacements conditionnels (SizedBox
/// au-dessus/en-dessous) doivent vivre DANS [child], sinon ils sautent sec à
/// côté de la section animée.
class GlanceReveal extends StatelessWidget {
  const GlanceReveal({
    super.key,
    required this.show,
    required this.child,
    this.duration = kMotionBase,
  });

  final bool show;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    // ClipRect : pas de débordement peint pendant l'animation de taille.
    return ClipRect(
      child: AnimatedSize(
        duration: duration,
        curve: kCurveOutCubic,
        // La section grandit vers le bas depuis son bord haut.
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: duration,
          switchInCurve: kCurveOut,
          switchOutCurve: kCurveOut,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, ?current],
          ),
          // Replié = largeur pleine, hauteur 0 : avec SizedBox.shrink(), la
          // largeur s'animerait aussi → grossissement « en diagonale » dans
          // une Column stretch.
          child: show
              ? KeyedSubtree(key: const ValueKey(true), child: child)
              : const SizedBox(key: ValueKey(false), width: double.infinity),
        ),
      ),
    );
  }
}
