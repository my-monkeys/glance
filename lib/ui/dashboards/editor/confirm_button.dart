import 'package:flutter/material.dart';

import '../../../theme/motion.dart';
import '../../../theme/palette.dart';
import '../../../theme/type.dart';

/// Action destructive en deux taps, sans boîte de dialogue : le premier arme
/// le bouton (qui change de libellé), le second exécute. Évite un dialogue
/// système par-dessus une feuille ou une modale.
class ConfirmButton extends StatefulWidget {
  const ConfirmButton({
    super.key,
    required this.label,
    required this.confirmLabel,
    required this.onConfirmed,
  });

  final String label;
  final String confirmLabel;
  final VoidCallback onConfirmed;

  @override
  State<ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<ConfirmButton> {
  bool _armed = false;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _armed ? widget.onConfirmed : () => setState(() => _armed = true),
            child: AnimatedContainer(
              duration: kMotionFast,
              curve: kCurveOut,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _armed ? p.neg : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: p.neg),
              ),
              child: Text(
                _armed ? widget.confirmLabel : widget.label,
                style: GT.body(15, weight: 600, color: _armed ? p.accentInk : p.neg),
              ),
            ),
          ),
        ),
        if (_armed) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _armed = false),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text('Annuler', style: GT.body(14, color: p.fg2)),
            ),
          ),
        ],
      ],
    );
  }
}
