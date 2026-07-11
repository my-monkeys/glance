import 'package:flutter/material.dart';

import '../../theme/palette.dart';
import '../../theme/type.dart';

/// Point « live » avec anneau qui pulse (comme la maquette).
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, this.size = 9, this.color, this.pulse = true});
  final double size;
  final Color? color;
  final bool pulse;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  // Toujours créé dans initState (jamais en lazy) : sinon un `late` non initialisé
  // se construirait au dispose() sur un élément désactivé → crash Ticker.
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
    if (widget.pulse) _c.repeat();
  }

  @override
  void didUpdateWidget(PulseDot old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.pulse && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.glance.accent;
    if (!widget.pulse) {
      return _dot(color);
    }
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_c.value);
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.scale(
                scale: 1 + t * 2.4,
                child: Opacity(
                  opacity: (0.55 * (1 - t)).clamp(0.0, 1.0),
                  child: _dot(color),
                ),
              ),
              _dot(color),
            ],
          );
        },
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: widget.size,
    height: widget.size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Pastille « N live ». Verte + pulse quand il y a des visiteurs en direct,
/// grisée et immobile quand il n'y a personne (count == 0).
class LivePill extends StatelessWidget {
  const LivePill({super.key, required this.count, this.text});
  final int count;

  /// Texte affiché ; défaut « N live ». Passer un libellé fixe (ex. « en ce
  /// moment ») quand le nombre est déjà montré ailleurs.
  final String? text;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final live = count > 0;
    final fg = live ? p.accent : p.fg3;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: live ? p.accentSoft : p.chip,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulseDot(pulse: live, color: fg),
          const SizedBox(width: 6),
          Text(text ?? '$count live', style: GT.mono(12, weight: 600, color: fg)),
        ],
      ),
    );
  }
}
