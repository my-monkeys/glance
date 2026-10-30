import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/palette.dart';
import '../../theme/type.dart';
import 'indicator_chart.dart';

/// Grand chiffre, ligne de contexte, puis le détail de l'indicateur.
class CardStat extends StatelessWidget {
  const CardStat({
    super.key,
    required this.big,
    required this.fill,
    this.sub,
    this.child,
    this.detail,
    this.notes = const [],
  });
  final String big;

  /// Mentions discrètes sous la ligne de contexte (cohortes, membre retenu).
  final List<String> notes;
  final String? sub;
  final String? detail;

  /// Absent : la carte ne montre que son chiffre.
  final Widget? child;

  /// La carte a une taille imposée par la grille (cf. `IndicatorCard.fill`).
  final bool fill;

  static const double _gap = 14;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final head = <Widget>[
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        // Fredoka n'a pas l'espace fine insécable (U+202F) que `intl` met
        // entre les milliers : le groupe disparaissait (« 1994 »).
        child: Text(
          big.replaceAll('\u202f', '\u00a0'),
          style: GT.stat(40, color: p.fg),
        ),
      ),
      if (sub != null) ...[
        const SizedBox(height: 4),
        Text(
          sub!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GT.mono(11.5, color: p.fg2),
        ),
      ],
      for (final n in notes)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(n, style: GT.mono(10.5, color: p.fg3)),
        ),
      if (detail != null)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            detail!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GT.mono(10.5, color: p.fg3),
          ),
        ),
    ];
    if (!fill) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...head,
          if (child != null) ...[const SizedBox(height: _gap), child!],
        ],
      );
    }
    return CustomMultiChildLayout(
      delegate: _StatLayout(gap: _gap, stretch: child is IndicatorChart),
      children: [
        LayoutId(
          id: _StatPart.head,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: head,
          ),
        ),
        if (child != null)
          LayoutId(
            id: _StatPart.body,
            child: child is IndicatorChart ? _ChartRoom(child: child!) : child!,
          ),
      ],
    );
  }
}

enum _StatPart { head, body }

/// Le chiffre en haut à sa hauteur naturelle, le détail dessous : une courbe
/// ([stretch]) prend toute la hauteur qui reste, une liste (entonnoir,
/// répartition) garde la sienne et la carte la coupe. Une `Column` signalerait
/// un débordement là où la grille coupe volontairement.
class _StatLayout extends MultiChildLayoutDelegate {
  _StatLayout({required this.gap, required this.stretch});

  final double gap;
  final bool stretch;

  @override
  void performLayout(Size size) {
    final head = layoutChild(
      _StatPart.head,
      BoxConstraints(maxWidth: size.width),
    );
    positionChild(_StatPart.head, Offset.zero);
    if (!hasChild(_StatPart.body)) return;
    final top = head.height + gap;
    layoutChild(
      _StatPart.body,
      stretch
          ? BoxConstraints.tightFor(
              width: size.width,
              height: math.max(0, size.height - top),
            )
          : BoxConstraints.tightFor(width: size.width),
    );
    positionChild(_StatPart.body, Offset(0, top));
  }

  @override
  bool shouldRelayout(_StatLayout old) =>
      old.gap != gap || old.stretch != stretch;
}

/// Une courbe écrasée sous quelques dizaines de pixels n'est plus lisible :
/// la carte garde alors son chiffre seul.
class _ChartRoom extends StatelessWidget {
  const _ChartRoom({required this.child});
  final Widget child;

  static const double _minHeight = 48;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) =>
        c.maxHeight < _minHeight ? const SizedBox.shrink() : child,
  );
}

/// Contenu à sa hauteur naturelle dans une carte de taille imposée : ce qui
/// dépasse est coupé par la carte, sans signaler de débordement.
class CardLoose extends StatelessWidget {
  const CardLoose({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => OverflowBox(
    alignment: Alignment.topLeft,
    minHeight: 0,
    maxHeight: double.infinity,
    child: child,
  );
}

