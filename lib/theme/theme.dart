import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'palette.dart';
import 'type.dart';

ThemeData glanceTheme(Brightness brightness) {
  final p = brightness == Brightness.dark
      ? GlancePalette.dark
      : GlancePalette.light;

  final base = ThemeData(brightness: brightness, useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: p.bg,
    extensions: [p],
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    // iOS : slide natif + swipe-back (explicité). Android/macOS : fondu
    // glissé M3, plus doux que le zoom par défaut (et que le slide plein
    // écran Cupertino sur desktop).
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
    }),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
      titleTextStyle: GT.body(17, weight: 700, color: p.fg),
      contentTextStyle: GT.body(13.5, color: p.fg2),
    ),
    colorScheme: base.colorScheme.copyWith(
      brightness: brightness,
      primary: p.accent,
      onPrimary: p.accentInk,
      surface: p.surface,
      onSurface: p.fg,
      error: p.neg,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: 'Geist',
      bodyColor: p.fg,
      displayColor: p.fg,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.accent,
      selectionColor: p.accentSoft,
      selectionHandleColor: p.accent,
    ),
    // Style texte par défaut pour l'app.
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Geist'),
  ).copyWith(
    // Applique la couleur de premier plan par défaut aux widgets Text nus.
    textTheme: base.textTheme
        .apply(fontFamily: 'Geist', bodyColor: p.fg, displayColor: p.fg)
        .copyWith(bodyMedium: GT.body(15, color: p.fg)),
  );
}
