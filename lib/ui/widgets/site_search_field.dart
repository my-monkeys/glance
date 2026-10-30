import 'package:flutter/material.dart';

import '../../theme/motion.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';

/// Barre de recherche de sites : loupe, saisie, croix pour effacer.
/// Sans label au-dessus (contrairement à `GlanceField`) : elle se pose
/// au-dessus d'une liste, pas dans un formulaire.
class SiteSearchField extends StatelessWidget {
  const SiteSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.dense = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  /// Barre latérale du bureau : plus basse, texte plus petit.
  final bool dense;

  void _clear() {
    controller.clear();
    onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final fontSize = dense ? 13.0 : 15.0;
    return Container(
      height: dense ? 38 : 46,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(dense ? 11 : 14),
        border: Border.all(color: p.line),
      ),
      padding: const EdgeInsets.only(left: 12, right: 4),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: dense ? 17 : 19, color: p.fg3),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.search,
              cursorColor: p.accent,
              style: GT.body(fontSize, color: p.fg),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: 'Rechercher un site',
                hintStyle: GT.body(fontSize, color: p.fg3),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => AnimatedOpacity(
              duration: kMotionFast,
              curve: kCurveOut,
              opacity: value.text.isEmpty ? 0 : 1,
              child: IgnorePointer(
                ignoring: value.text.isEmpty,
                child: IconButton(
                  tooltip: 'Effacer',
                  visualDensity: VisualDensity.compact,
                  iconSize: dense ? 16 : 18,
                  color: p.fg2,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _clear,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aucun site ne correspond : le dire, plutôt qu'une liste vide muette.
class NoSiteMatch extends StatelessWidget {
  const NoSiteMatch(this.query, {super.key});
  final String query;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 4),
      child: Text(
        'Aucun site ne correspond à « ${query.trim()} ».',
        style: GT.body(14, color: p.fg2),
      ),
    );
  }
}
