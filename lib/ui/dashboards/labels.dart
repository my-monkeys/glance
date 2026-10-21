import '../../data/models/indicator.dart';
import '../../data/providers/metrics_api.dart';

/// `part est 25, issue est complet` — vide sans filtre.
String filtersSummary(List<EventFilter> filters) => filters
    .map((f) => '${f.property} ${f.op.label} ${f.value}')
    .join(', ');

/// `partie_terminee · issue est complet`, ou le seul nom sans filtre.
String queryLabel(EventQuery q) => q.filters.isEmpty
    ? q.event
    : '${q.event} · ${filtersSummary(q.filters)}';

/// Message affiché pour un échec de la source de métriques : ceux de l'API
/// sont déjà lisibles, le reste (réseau, serveur) reste générique.
String metricsErrorMessage(Object e) =>
    e is MetricsApiException ? e.message : 'Chargement impossible.';
