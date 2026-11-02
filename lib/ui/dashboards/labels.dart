import '../../data/models/indicator.dart';
import '../../data/providers/metrics_api.dart';
import '../../l10n/l10n.dart';

/// `part est 25, issue est complet` — vide sans filtre.
String filtersSummary(AppLocalizations l10n, List<EventFilter> filters) =>
    filters.map((f) => '${f.property} ${f.op.label(l10n)} ${f.value}').join(', ');

/// `partie_terminee · issue est complet`, ou le seul nom sans filtre.
String queryLabel(AppLocalizations l10n, EventQuery q) => q.filters.isEmpty
    ? q.event
    : '${q.event} · ${filtersSummary(l10n, q.filters)}';

/// Message affiché pour un échec de la source de métriques : ceux de l'API
/// sont déjà lisibles, le reste (réseau, serveur) reste générique.
String metricsErrorMessage(AppLocalizations l10n, Object e) =>
    e is MetricsApiException ? e.message(l10n) : l10n.dashboardsLoadFailed;
