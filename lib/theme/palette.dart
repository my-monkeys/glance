import 'package:flutter/material.dart';

/// Tokens de couleur Glance (Direction A). Exposé via [ThemeExtension] pour être
/// lu depuis n'importe quel widget : `context.glance`.
@immutable
class GlancePalette extends ThemeExtension<GlancePalette> {
  const GlancePalette({
    required this.bg,
    required this.surface,
    required this.fg,
    required this.fg2,
    required this.fg3,
    required this.line,
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
    required this.neg,
    required this.chip,
    required this.shadow,
  });

  final Color bg;
  final Color surface;
  final Color fg;
  final Color fg2;
  final Color fg3;
  final Color line;
  final Color accent;
  final Color accentInk;
  final Color accentSoft;
  final Color neg;
  final Color chip;
  final List<BoxShadow> shadow;

  /// Direction A — palette claire (crème + vert forêt).
  static const light = GlancePalette(
    bg: Color(0xFFF7F5F1),
    surface: Color(0xFFFFFFFF),
    fg: Color(0xFF211E19),
    fg2: Color(0xFF8C857A),
    fg3: Color(0xFFB4ADA1),
    line: Color(0x171E190F), // rgba(30,25,15,.09)
    accent: Color(0xFF3B7A5A),
    accentInk: Color(0xFFFFFFFF),
    accentSoft: Color(0x1F3B7A5A), // rgba(59,122,90,.12)
    neg: Color(0xFFB15A42),
    chip: Color(0xFFF0EDE7),
    shadow: [
      BoxShadow(color: Color(0x0A282319), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x0D282319), blurRadius: 20, offset: Offset(0, 6)),
    ],
  );

  /// Palette sombre pensée dans le même registre chaud/éditorial.
  static const dark = GlancePalette(
    bg: Color(0xFF16140F),
    surface: Color(0xFF201D16),
    fg: Color(0xFFF3F0E9),
    fg2: Color(0xFFA69F91),
    fg3: Color(0xFF6E685C),
    line: Color(0x14FAF5EB), // rgba(250,245,235,.08)
    accent: Color(0xFF5AA57E),
    accentInk: Color(0xFF0E1A12),
    accentSoft: Color(0x1F5AA57E),
    neg: Color(0xFFCF7A5F),
    chip: Color(0xFF2A271E),
    shadow: [
      BoxShadow(color: Color(0x33000000), blurRadius: 22, offset: Offset(0, 8)),
    ],
  );

  @override
  GlancePalette copyWith({
    Color? bg,
    Color? surface,
    Color? fg,
    Color? fg2,
    Color? fg3,
    Color? line,
    Color? accent,
    Color? accentInk,
    Color? accentSoft,
    Color? neg,
    Color? chip,
    List<BoxShadow>? shadow,
  }) {
    return GlancePalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      fg: fg ?? this.fg,
      fg2: fg2 ?? this.fg2,
      fg3: fg3 ?? this.fg3,
      line: line ?? this.line,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      accentSoft: accentSoft ?? this.accentSoft,
      neg: neg ?? this.neg,
      chip: chip ?? this.chip,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  GlancePalette lerp(ThemeExtension<GlancePalette>? other, double t) {
    if (other is! GlancePalette) return this;
    return GlancePalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      fg: Color.lerp(fg, other.fg, t)!,
      fg2: Color.lerp(fg2, other.fg2, t)!,
      fg3: Color.lerp(fg3, other.fg3, t)!,
      line: Color.lerp(line, other.line, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      neg: Color.lerp(neg, other.neg, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      shadow: t < 0.5 ? shadow : other.shadow,
    );
  }
}

extension GlanceThemeX on BuildContext {
  GlancePalette get glance => Theme.of(this).extension<GlancePalette>()!;
}

/// Rayon de coin standard de la maquette.
const double kRadius = 22.0;
const double kRadiusSm = 15.0;
