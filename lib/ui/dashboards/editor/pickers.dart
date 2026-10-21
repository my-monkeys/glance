import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/indicator.dart';
import '../../../data/models/indicator_result.dart';
import '../../../data/models/models.dart';
import '../../../state/indicators.dart';
import '../../../theme/palette.dart';
import '../../../theme/type.dart';
import '../../widgets/field.dart';

/// Au-delà, une liste de suggestions se cherche plus qu'elle ne se parcourt.
const int kSearchThreshold = 8;

/// Feuille du bas, au même gabarit que la feuille « Affichage ».
Future<T?> showGlanceSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.glance.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: builder,
    );

/// Champ qui s'ouvre au tap (choix d'un événement, d'une propriété) : même
/// habillage que [GlanceField], sans saisie.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.onTap,
    this.value,
    this.enabled = true,
  });

  final String label;
  final String placeholder;
  final String? value;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final filled = value != null && value!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 3, bottom: 7),
          child: Text(label.toUpperCase(), style: GT.label(color: p.fg2)),
        ),
        GestureDetector(
          onTap: enabled ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    filled ? value! : placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: filled
                        ? GT.mono(14, color: p.fg)
                        : GT.body(15, color: p.fg3),
                  ),
                ),
                Icon(Icons.unfold_more_rounded, size: 18, color: p.fg3),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Une ligne de [_SearchSheet].
class _Option {
  const _Option(this.value, {this.hint});
  final String value;
  final String? hint;
}

/// Choisit un événement parmi ceux vus sur 30 jours, ou en saisit un à la main
/// (Plausible n'en liste pas toujours, et un événement pas encore reçu n'a
/// aucune suggestion).
Future<String?> pickEvent(BuildContext context, Site site) =>
    showGlanceSheet<String>(
      context,
      (_) => Consumer(
        builder: (context, ref, _) => _SearchSheet(
          title: 'Événement',
          freeTextHint: 'Saisir un nom d\'événement',
          options: ref.watch(eventNamesProvider(site)).whenData(
                (names) => [for (final n in names) _Option(n)],
              ),
        ),
      ),
    );

String propertyTypeHint(PropertyType t) => switch (t) {
      PropertyType.string => 'texte',
      PropertyType.number => 'nombre',
      PropertyType.boolean => 'oui-non',
    };

/// Choisit une propriété de [event]. Sans liste (Plausible), le nom saisi à la
/// main vaut du texte : c'est le seul type qu'on puisse supposer.
Future<EventProperty?> pickProperty(
  BuildContext context,
  Site site,
  String event,
) async {
  final known = <String, EventProperty>{};
  final name = await showGlanceSheet<String>(
    context,
    (_) => Consumer(
      builder: (context, ref, _) => _SearchSheet(
        title: 'Propriété',
        freeTextHint: 'Saisir un nom de propriété',
        options: ref.watch(eventPropertiesProvider((site, event))).whenData(
          (props) {
            for (final p in props) {
              known[p.name] = p;
            }
            return [
              for (final p in props)
                _Option(p.name, hint: propertyTypeHint(p.type)),
            ];
          },
        ),
      ),
    ),
  );
  if (name == null) return null;
  return known[name] ?? EventProperty(name, PropertyType.string);
}

/// Liste filtrable, avec saisie libre quand la liste est vide, en échec, ou
/// trop longue pour être parcourue.
class _SearchSheet extends StatefulWidget {
  const _SearchSheet({
    required this.title,
    required this.options,
    required this.freeTextHint,
  });

  final String title;
  final AsyncValue<List<_Option>> options;
  final String freeTextHint;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final options = widget.options.value ?? const <_Option>[];
    final settled = !widget.options.isLoading;
    // Sans liste exploitable, le champ est la seule issue : on l'offre.
    final searchable = settled && (options.length > kSearchThreshold || options.isEmpty);
    final q = _query.text.trim();
    final shown = [
      for (final o in options)
        if (q.isEmpty || o.value.toLowerCase().contains(q.toLowerCase())) o,
    ];
    final typedIsNew = q.isNotEmpty && !options.any((o) => o.value == q);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: GT.display(22, color: p.fg)),
              const SizedBox(height: 14),
              if (searchable) ...[
                GlanceField(
                  label: options.isEmpty ? 'Nom' : 'Rechercher',
                  hint: options.isEmpty ? widget.freeTextHint : null,
                  controller: _query,
                  mono: true,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) Navigator.of(context).pop(v.trim());
                  },
                ),
                const SizedBox(height: 10),
              ],
              Flexible(child: _body(context, shown, typedIsNew ? q : null)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, List<_Option> shown, String? typed) {
    final p = context.glance;
    if (widget.options.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: CircularProgressIndicator(color: p.accent, strokeWidth: 2.4),
        ),
      );
    }
    final failed = widget.options.hasError;
    return ListView(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      children: [
        if (typed != null)
          _Row(
            label: 'Utiliser « $typed »',
            accent: true,
            onTap: () => Navigator.of(context).pop(typed),
          ),
        for (final o in shown)
          _Row(
            label: o.value,
            hint: o.hint,
            onTap: () => Navigator.of(context).pop(o.value),
          ),
        if (failed || (shown.isEmpty && typed == null))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              failed
                  ? 'Liste indisponible — saisissez le nom à la main.'
                  : 'Rien de vu sur 30 jours — saisissez le nom à la main.',
              style: GT.body(13, color: p.fg3),
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.onTap,
    this.hint,
    this.accent = false,
  });

  final String label;
  final String? hint;
  final bool accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: accent
                    ? GT.body(15, weight: 600, color: p.accent)
                    : GT.mono(14, color: p.fg),
              ),
            ),
            if (hint != null) Text(hint!, style: GT.mono(11, color: p.fg3)),
          ],
        ),
      ),
    );
  }
}
