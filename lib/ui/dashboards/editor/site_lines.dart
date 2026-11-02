import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/indicator.dart';
import '../../../data/models/models.dart';
import '../../../data/models/workspace.dart';
import '../../../l10n/l10n.dart';
import '../../../state/providers.dart';
import '../../../theme/palette.dart';
import '../../../theme/type.dart';
import '../../widgets/chip.dart';
import '../../widgets/field.dart';
import 'draft.dart';
import 'pickers.dart';

String _modeLabel(AppLocalizations l10n, ReferrerMode m) => switch (m) {
      ReferrerMode.all => l10n.editorModeAll,
      ReferrerMode.only => l10n.editorModeOnly,
      ReferrerMode.except => l10n.editorModeExcept,
    };

/// Les lignes d'un tableau « Sites » : un site, son libellé, et un filtre de
/// référent facultatif (« geography sauf alldle.net »).
class SiteLinesEditor extends ConsumerStatefulWidget {
  const SiteLinesEditor({
    super.key,
    required this.lines,
    required this.onChanged,
  });

  final List<SiteLine> lines;
  final ValueChanged<List<SiteLine>> onChanged;

  @override
  ConsumerState<SiteLinesEditor> createState() => _SiteLinesEditorState();
}

class _SiteLinesEditorState extends ConsumerState<SiteLinesEditor> {
  /// Libellé et référent de chaque ligne, dans l'ordre des lignes.
  final List<(TextEditingController, TextEditingController)> _fields = [];

  @override
  void initState() {
    super.initState();
    for (final l in widget.lines) {
      _fields.add(_fieldsOf(l));
    }
  }

  @override
  void dispose() {
    for (final (label, referrer) in _fields) {
      label.dispose();
      referrer.dispose();
    }
    super.dispose();
  }

  static (TextEditingController, TextEditingController) _fieldsOf(SiteLine l) =>
      (TextEditingController(text: l.label), TextEditingController(text: l.referrer));

  List<SiteLine> get _lines => widget.lines;

  void _replace(int i, SiteLine l) =>
      widget.onChanged([for (final (j, x) in _lines.indexed) j == i ? l : x]);

  void _add() {
    _fields.add(_fieldsOf(kEmptySiteLine));
    widget.onChanged([..._lines, kEmptySiteLine]);
  }

  void _remove(int i) {
    final (label, referrer) = _fields.removeAt(i);
    label.dispose();
    referrer.dispose();
    widget.onChanged([
      for (final (j, x) in _lines.indexed)
        if (j != i) x,
    ]);
  }

  Future<void> _pick(int i) async {
    final site = await pickSite(context);
    if (site == null || !mounted) return;
    final line = _lines[i];
    // Le nom du site sert de libellé tant qu'aucun n'a été saisi.
    final label = line.label.trim().isEmpty ? site.name : line.label;
    _fields[i].$1.text = label;
    _replace(i, line.copyWith(site: SiteRef.of(site), label: label));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final l10n = context.l10n;
    final names = {
      for (final s in ref.watch(sitesProvider).value ?? const <Site>[])
        SiteRef.of(s): s.name,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, line) in _lines.indexed) ...[
          if (i > 0) const SizedBox(height: 12),
          _LineCard(
            index: i,
            onRemove: _lines.length > 1 ? () => _remove(i) : null,
            children: [
              PickerField(
                label: l10n.editorSiteLabel,
                placeholder: l10n.editorLineSitePlaceholder,
                value: names[line.site] ?? '',
                onTap: () => _pick(i),
              ),
              const SizedBox(height: 12),
              GlanceField(
                label: l10n.editorLineLabel,
                controller: _fields[i].$1,
                onChanged: (v) => _replace(i, line.copyWith(label: v)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in ReferrerMode.values)
                    GlanceChip(
                      label: _modeLabel(l10n, m),
                      selected: line.mode == m,
                      onTap: () => _replace(i, line.copyWith(mode: m)),
                    ),
                ],
              ),
              if (line.mode != ReferrerMode.all) ...[
                const SizedBox(height: 12),
                GlanceField(
                  label: l10n.editorLineReferrer,
                  controller: _fields[i].$2,
                  hint: 'alldle.net',
                  url: true,
                  mono: true,
                  onChanged: (v) => _replace(i, line.copyWith(referrer: v)),
                ),
              ],
            ],
          ),
        ],
        if (_lines.length < kSiteLinesMax) ...[
          const SizedBox(height: 12),
          GlanceButtonOutline(
            label: l10n.editorLineAdd,
            leading: Icon(Icons.add_rounded, size: 18, color: p.fg),
            onTap: _add,
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(left: 3, top: 10),
          child: Text(
            l10n.editorLinesHint,
            style: GT.body(12.5, color: p.fg3),
          ),
        ),
      ],
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    required this.index,
    required this.onRemove,
    required this.children,
  });

  final int index;
  final VoidCallback? onRemove;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 14),
      decoration: BoxDecoration(
        color: p.chip,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(l10n.editorLineTitle(index + 1), style: GT.label(color: p.fg2)),
              const Spacer(),
              Tooltip(
                message: l10n.editorLineRemove,
                child: GestureDetector(
                  onTap: onRemove,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: onRemove == null ? p.fg3.withValues(alpha: 0.4) : p.fg2,
                      semanticLabel: l10n.editorLineRemove,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
