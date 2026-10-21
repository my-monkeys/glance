import '../../data/models/indicator.dart';

/// `part est 25, issue est complet` — vide sans filtre.
String filtersSummary(List<EventFilter> filters) => filters
    .map((f) => '${f.property} ${f.op.label} ${f.value}')
    .join(', ');

/// `partie_terminee · issue est complet`, ou le seul nom sans filtre.
String queryLabel(EventQuery q) => q.filters.isEmpty
    ? q.event
    : '${q.event} · ${filtersSummary(q.filters)}';
