import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/indicator.dart';
import '../../../data/models/models.dart';
import '../../../state/indicators.dart';
import '../../../theme/palette.dart';
import '../../../theme/type.dart';
import '../../widgets/chip.dart';
import '../../widgets/field.dart';
import '../../widgets/motion.dart';
import 'pickers.dart';

/// Nombre de valeurs suggérées pour un filtre : les plus fréquentes suffisent,
/// le champ libre couvre le reste.
const int kValueSuggestions = 8;

/// Édite une [EventQuery] : l'événement, puis ses filtres. [allowedOps] borne
/// les opérateurs offerts (l'entonnoir n'en accepte que quatre).
class QueryEditor extends StatefulWidget {
  const QueryEditor({
    super.key,
    required this.site,
    required this.query,
    required this.onChanged,
    this.label,
    this.allowedOps,
  });

  final Site site;
  final EventQuery query;
  final ValueChanged<EventQuery> onChanged;
  final String? label;
  final Set<FilterOp>? allowedOps;

  @override
  State<QueryEditor> createState() => _QueryEditorState();
}

class _QueryEditorState extends State<QueryEditor> {
  bool _adding = false;

  Future<void> _pickEvent() async {
    final event = await pickEvent(context, widget.site);
    if (event == null || !mounted || event == widget.query.event) return;
    // Les filtres portent sur les propriétés de l'ancien événement : sur un
    // autre, ils ne voudraient plus rien dire (ou filtreraient tout).
    setState(() => _adding = false);
    widget.onChanged(EventQuery(event));
  }

  void _addFilter(EventFilter f) {
    setState(() => _adding = false);
    widget.onChanged(widget.query.copyWith(filters: [...widget.query.filters, f]));
  }

  void _removeFilter(int i) => widget.onChanged(
        widget.query.copyWith(
          filters: [
            for (var j = 0; j < widget.query.filters.length; j++)
              if (j != i) widget.query.filters[j],
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final q = widget.query;
    final hasEvent = q.event.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PickerField(
          label: widget.label ?? 'Événement',
          placeholder: 'Choisir un événement',
          value: q.event,
          onTap: _pickEvent,
        ),
        for (var i = 0; i < q.filters.length; i++)
          _FilterRow(filter: q.filters[i], onRemove: () => _removeFilter(i)),
        const SizedBox(height: 10),
        GlanceReveal(
          show: _adding && hasEvent,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FilterForm(
              site: widget.site,
              event: q.event,
              allowedOps: widget.allowedOps,
              onAdd: _addFilter,
              onCancel: () => setState(() => _adding = false),
            ),
          ),
        ),
        if (!_adding)
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: hasEvent ? () => setState(() => _adding = true) : null,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Ajouter un filtre',
                  style: GT.body(
                    13.5,
                    weight: 600,
                    color: hasEvent ? p.accent : p.fg3,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.filter, required this.onRemove});
  final EventFilter filter;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
        decoration: BoxDecoration(
          color: p.chip,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${filter.property} ${filter.op.label} ${filter.value}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GT.mono(12.5, color: p.fg),
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.close_rounded,
                    size: 16, color: p.fg2, semanticLabel: 'Retirer le filtre'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Propriété, opérateur, valeur : un filtre en trois temps, validé par « Ajouter ».
class _FilterForm extends ConsumerStatefulWidget {
  const _FilterForm({
    required this.site,
    required this.event,
    required this.allowedOps,
    required this.onAdd,
    required this.onCancel,
  });

  final Site site;
  final String event;
  final Set<FilterOp>? allowedOps;
  final ValueChanged<EventFilter> onAdd;
  final VoidCallback onCancel;

  @override
  ConsumerState<_FilterForm> createState() => _FilterFormState();
}

class _FilterFormState extends ConsumerState<_FilterForm> {
  final _value = TextEditingController();
  String? _property;
  PropertyType _type = PropertyType.string;
  FilterOp _op = FilterOp.eq;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  List<FilterOp> get _ops => [
        for (final o in FilterOp.forType(_type))
          if (widget.allowedOps?.contains(o) ?? true) o,
      ];

  Future<void> _pickProperty() async {
    final prop = await pickProperty(context, widget.site, widget.event);
    if (prop == null || !mounted) return;
    setState(() {
      _property = prop.name;
      _type = prop.type;
      _op = _ops.first;
      _value.clear();
    });
  }

  bool get _valid {
    final v = _value.text.trim();
    if (_property == null || v.isEmpty) return false;
    return _type != PropertyType.number || num.tryParse(v) != null;
  }

  void _submit() => widget.onAdd(EventFilter(
        property: _property!,
        type: _type,
        op: _op,
        value: _value.text.trim(),
      ));

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PickerField(
            label: 'Propriété',
            placeholder: 'Choisir une propriété',
            value: _property,
            onTap: _pickProperty,
          ),
          GlanceReveal(
            show: _property != null,
            child: _property == null ? const SizedBox.shrink() : _valueStep(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GlanceButtonOutline(label: 'Annuler', onTap: widget.onCancel),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlanceButton(
                  label: 'Ajouter',
                  onTap: _valid ? _submit : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _valueStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          ChipRow(
            children: [
              for (final o in _ops)
                GlanceChip(
                  label: o.label,
                  selected: o == _op,
                  onTap: () => setState(() => _op = o),
                ),
            ],
          ),
          const SizedBox(height: 14),
          switch (_type) {
            PropertyType.boolean => ChipRow(
                children: [
                  for (final v in const ['true', 'false'])
                    GlanceChip(
                      label: v == 'true' ? 'vrai' : 'faux',
                      selected: _value.text == v,
                      onTap: () => setState(() => _value.text = v),
                    ),
                ],
              ),
            PropertyType.number => _valueField(number: true),
            PropertyType.string => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_suggestions(), _valueField()],
              ),
          },
        ],
      );

  Widget _valueField({bool number = false}) => GlanceField(
        label: 'Valeur',
        controller: _value,
        mono: true,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true, signed: true)
            : null,
        onChanged: (_) => setState(() {}),
      );

  /// Valeurs les plus fréquentes de la propriété ; en échec ou vide (Plausible),
  /// le champ libre suffit, on n'affiche rien.
  Widget _suggestions() {
    final rows = ref
            .watch(propertyValuesProvider((widget.site, widget.event, _property!)))
            .value ??
        const [];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ChipRow(
        children: [
          for (final r in rows.take(kValueSuggestions))
            GlanceChip(
              label: r.label,
              selected: _value.text == r.label,
              onTap: () => setState(() => _value.text = r.label),
            ),
        ],
      ),
    );
  }
}
