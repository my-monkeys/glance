import 'package:flutter/material.dart';

import '../../theme/palette.dart';
import '../../theme/type.dart';

/// Point « live » avec anneau qui pulse (comme la maquette).
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, this.size = 9, this.color});
  final double size;
  final Color? color;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.glance.accent;
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

/// Pastille « N live » avec point pulsant.
class LivePill extends StatelessWidget {
  const LivePill({super.key, required this.label, this.big = false});
  final String label;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: p.accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PulseDot(),
          const SizedBox(width: 6),
          Text(label, style: GT.mono(12, weight: 600, color: p.accent)),
        ],
      ),
    );
  }
}
