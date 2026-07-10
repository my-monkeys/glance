import 'package:flutter/material.dart';

/// Fabriques de styles typographiques Glance.
///
/// Les 3 familles sont des fonts variables : le poids est appliqué via
/// [FontVariation] (`wght`) plutôt que `fontWeight`, ce qui garantit le rendu
/// exact du poids demandé sur toute la plage de l'axe.
class GT {
  const GT._();

  static const _fredoka = 'Fredoka';
  static const _geist = 'Geist';
  static const _mono = 'JetBrainsMono';

  static const _tnum = [FontFeature.tabularFigures()];

  /// Titres — Fredoka (display).
  static TextStyle display(double size, {double weight = 600, Color? color}) {
    return TextStyle(
      fontFamily: _fredoka,
      fontSize: size,
      height: 1.04,
      letterSpacing: -0.3,
      color: color,
      fontVariations: [
        FontVariation('wght', weight),
        FontVariation('wdth', 100),
      ],
    );
  }

  /// Grands chiffres — Fredoka, chiffres tabulaires.
  static TextStyle stat(double size, {double weight = 600, Color? color}) {
    return TextStyle(
      fontFamily: _fredoka,
      fontSize: size,
      height: 1.0,
      color: color,
      fontFeatures: _tnum,
      fontVariations: [
        FontVariation('wght', weight),
        FontVariation('wdth', 100),
      ],
    );
  }

  /// Corps de texte — Geist.
  static TextStyle body(
    double size, {
    double weight = 400,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: _geist,
      fontSize: size,
      height: height,
      color: color,
      fontVariations: [FontVariation('wght', weight)],
    );
  }

  /// Mono — JetBrains Mono, chiffres tabulaires.
  static TextStyle mono(
    double size, {
    double weight = 400,
    Color? color,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: _mono,
      fontSize: size,
      color: color,
      letterSpacing: letterSpacing,
      fontFeatures: _tnum,
      fontVariations: [FontVariation('wght', weight)],
    );
  }

  /// Label : mono 10px, très espacé, à passer en MAJUSCULES côté appelant.
  static TextStyle label({Color? color}) {
    return mono(10, weight: 500, color: color, letterSpacing: 1.6);
  }
}
