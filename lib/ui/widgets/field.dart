import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/palette.dart';
import '../../theme/type.dart';

/// Champ de saisie : label mono au-dessus + zone surface bordée arrondie.
class GlanceField extends StatelessWidget {
  const GlanceField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.url = false,
    this.mono = false,
    this.autofocus = false,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final bool url;
  final bool mono;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 3, bottom: 7),
          child: Text(label.toUpperCase(), style: GT.label(color: p.fg2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.line),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            autofocus: autofocus,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: url ? TextInputType.url : TextInputType.text,
            textInputAction: TextInputAction.next,
            onSubmitted: onSubmitted,
            cursorColor: p.accent,
            style: mono
                ? GT.mono(15, color: p.fg)
                : GT.body(15, color: p.fg),
            inputFormatters: url
                ? [FilteringTextInputFormatter.deny(RegExp(r'\s'))]
                : null,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: GT.body(15, color: p.fg3),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bouton principal plein accent.
class GlanceButton extends StatelessWidget {
  const GlanceButton({
    super.key,
    required this.label,
    required this.onTap,
    this.busy = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null ? p.accent.withValues(alpha: 0.5) : p.accent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: busy
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: p.accentInk,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: p.accentInk),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: GT.body(16, weight: 600, color: p.accentInk),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Bouton secondaire (contour).
class GlanceButtonOutline extends StatelessWidget {
  const GlanceButtonOutline({
    super.key,
    required this.label,
    required this.onTap,
    this.busy = false,
    this.leading,
  });

  final String label;
  final VoidCallback? onTap;
  final bool busy;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: p.line),
        ),
        child: busy
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: p.fg2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 8)],
                  Text(label, style: GT.body(15, weight: 500, color: p.fg)),
                ],
              ),
      ),
    );
  }
}
