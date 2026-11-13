import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../data/models/indicator.dart';
import '../../data/models/period.dart';
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

/// Sous-titre d'un compteur qui montre le dernier bucket (agrégation
/// « dernier ») : « Semaine du 9 nov. · en cours », « 13 nov. », « novembre 2026 ».
String latestLabel(
  AppLocalizations l10n,
  ({DateTime t, bool ongoing}) latest,
  TimeUnit unit, {
  required bool weekly,
}) {
  final (:t, :ongoing) = latest;
  if (weekly) {
    return ongoing
        ? l10n.chartWeekOfOngoing(fmtDay(t))
        : l10n.chartWeekOf(fmtDay(t));
  }
  final day = unit == TimeUnit.month ? DateFormat.yMMMM().format(t) : fmtDay(t);
  return ongoing ? l10n.dashboardsOngoing(day) : day;
}
