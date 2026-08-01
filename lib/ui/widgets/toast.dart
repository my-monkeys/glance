import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/motion.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';

enum ToastKind { success, info, error }

/// Clé du Navigator racine (posée sur MaterialApp) : le toast s'insère dans
/// l'overlay racine, donc au-dessus des dialogs desktop et indépendant de la
/// route appelante.
final glanceNavKey = GlobalKey<NavigatorState>();

/// Toast de confirmation éphémère, en haut de l'écran (le bas est occupé par
/// la tab bar flottante et souvent couvert par le clavier au moment des
/// confirmations). Un seul toast à la fois : un nouvel appel remplace le
/// contenu et réarme le timer. Tap = fermeture immédiate.
///
/// À appeler AVANT un éventuel `Navigator.pop` : l'entrée vit dans l'overlay
/// racine et survit à la fermeture de l'écran appelant.
void showGlanceToast(
  BuildContext context,
  String message, {
  ToastKind kind = ToastKind.success,
  IconData? icon,
  Duration duration = const Duration(milliseconds: 2600),
}) {
  final overlay =
      glanceNavKey.currentState?.overlay ?? Overlay.of(context, rootOverlay: true);
  _GlanceToast.show(overlay, _ToastData(message, kind, icon), duration);
}

class _ToastData {
  const _ToastData(this.message, this.kind, this.icon);
  final String message;
  final ToastKind kind;
  final IconData? icon;
}

/// État module-privé : une seule entrée d'overlay, réutilisée.
class _GlanceToast {
  static OverlayEntry? _entry;
  static Timer? _hideTimer;
  static Timer? _removeTimer;
  static _ToastData? _data;
  static bool _visible = false;

  static void show(OverlayState overlay, _ToastData data, Duration duration) {
    if (data.kind == ToastKind.error) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    _hideTimer?.cancel();
    _removeTimer?.cancel();
    _data = data;

    if (_entry == null) {
      _entry = OverlayEntry(builder: _build);
      overlay.insert(_entry!);
      // L'entrée naît invisible ; on déclenche l'animation d'entrée à la
      // frame suivante pour que le premier build parte de l'état replié.
      _visible = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _visible = true;
        _entry?.markNeedsBuild();
      });
    } else {
      _visible = true;
      _entry!.markNeedsBuild();
    }

    _hideTimer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    if (_entry == null) return;
    _hideTimer?.cancel();
    _visible = false;
    _entry!.markNeedsBuild();
    _removeTimer = Timer(kMotionBase + const Duration(milliseconds: 40), () {
      _entry?.remove();
      _entry = null;
      _data = null;
    });
  }

  static Widget _build(BuildContext ctx) {
    final data = _data;
    if (data == null) return const SizedBox.shrink();
    final p = ctx.glance;
    final (defaultIcon, iconColor) = switch (data.kind) {
      ToastKind.success => (Icons.check_circle_rounded, p.accent),
      ToastKind.info => (Icons.info_outline_rounded, p.fg2),
      ToastKind.error => (Icons.error_outline_rounded, p.neg),
    };

    return Positioned(
      top: MediaQuery.paddingOf(ctx).top + 10,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !_visible,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AnimatedSlide(
              offset: _visible ? Offset.zero : const Offset(0, -0.4),
              duration: _visible ? kMotionSlow : kMotionBase,
              curve: kCurveOutCubic,
              child: AnimatedOpacity(
                opacity: _visible ? 1 : 0,
                duration: _visible ? kMotionSlow : kMotionBase,
                curve: kCurveOut,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(kRadiusSm),
                        border: Border.all(color: p.line),
                        boxShadow: p.shadow,
                      ),
                      // Crossfade quand un toast en remplace un autre.
                      child: AnimatedSwitcher(
                        duration: kMotionFast,
                        switchInCurve: kCurveOut,
                        switchOutCurve: kCurveOut,
                        child: Row(
                          key: ValueKey(data.message),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(data.icon ?? defaultIcon,
                                size: 18, color: iconColor),
                            const SizedBox(width: 9),
                            Flexible(
                              child: Text(
                                data.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    GT.body(13.5, weight: 500, color: p.fg),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
