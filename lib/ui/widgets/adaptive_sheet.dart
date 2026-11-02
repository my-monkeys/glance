import 'package:flutter/material.dart';

import '../../theme/motion.dart';
import '../../theme/palette.dart';
import '../desktop/desktop_shell.dart' show kDesktopBreakpoint;

/// Rayon des coins d'une feuille et d'un pop-up (celui des modales du bureau).
const double kSheetRadius = 22;

/// Largeur d'un pop-up de réglage : un menu, pas un écran.
const double kPopupWidth = 400;

/// Même critère que `showGlanceModal` : à cette largeur, le shell bureau est affiché.
bool isDesktopWidth(BuildContext context) =>
    MediaQuery.of(context).size.width >= kDesktopBreakpoint;

/// Fondu + échelle des modales du bureau, partagés par [showGlanceSheet] et
/// `showGlanceModal`.
Widget glanceDialogTransition(
  BuildContext context,
  Animation<double> anim,
  Animation<double> secondary,
  Widget child,
) {
  final t = CurvedAnimation(parent: anim, curve: kCurveOutCubic);
  return FadeTransition(
    opacity: t,
    child: ScaleTransition(
      scale: Tween(begin: 0.96, end: 1.0).animate(t),
      child: child,
    ),
  );
}

/// Choix et menus : feuille du bas sur téléphone, **pop-up centré** sur le
/// bureau (la feuille du bas y est démesurée et loin du curseur). Le contenu est
/// le même : [builder] ne doit ni poser de poignée ni compter sur un `SafeArea`
/// (cf. [isDesktopWidth]) et rend une colonne qui se contente de sa hauteur.
Future<T?> showGlanceSheet<T>(BuildContext context, WidgetBuilder builder) {
  final p = context.glance;
  if (!isDesktopWidth(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kSheetRadius)),
      ),
      builder: builder,
    );
  }
  final nested = ModalRoute.of(context) is RawDialogRoute;
  final maxHeight = MediaQuery.of(context).size.height * 0.8;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer',
    barrierColor: Colors.black.withValues(alpha: nested ? 0.15 : 0.62),
    transitionDuration: kMotionSlow,
    transitionBuilder: glanceDialogTransition,
    pageBuilder: (ctx, _, _) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: kPopupWidth, maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kSheetRadius),
          child: Material(color: p.surface, child: builder(ctx)),
        ),
      ),
    ),
  );
}
