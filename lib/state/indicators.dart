import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/external_metrics.dart';
import '../core/indicator_math.dart';
import '../core/timezone.dart';
import '../data/models/dimension.dart';
import '../data/models/indicator.dart';
import '../data/models/indicator_result.dart';
import '../data/models/metrics_source.dart';
import '../data/models/models.dart';
import '../data/models/period.dart';
import '../data/models/workspace.dart';
import '../data/providers/metrics_api.dart';
import 'metrics_sources.dart';
import 'providers.dart';

/// Indicateurs personnalisés, par site (persistés en clair : des noms
/// d'événements et des seuils, rien de sensible).
class IndicatorsNotifier extends Notifier<List<SiteIndicators>> {
  static const _key = 'glance.indicators';

  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  @override
  List<SiteIndicators> build() => SiteIndicators.decodeList(_p.getString(_key));

  Future<void> _save(List<SiteIndicators> next) async {
    await _p.setString(_key, SiteIndicators.encodeList(next));
    state = next;
  }

  List<Indicator> forSite(Site site) {
    for (final s in state) {
      if (s.site.matches(site)) return s.indicators;
    }
    return const [];
  }

  /// Remplace la liste d'un site (la crée au besoin) ; vide = on l'oublie.
  Future<void> _setFor(SiteRef ref, List<Indicator> list) {
    final others = state.where((s) => s.site != ref);
    return _save([...others, if (list.isNotEmpty) SiteIndicators(ref, list)]);
  }

  Future<void> add(Site site, Indicator i) =>
      _setFor(SiteRef.of(site), [...forSite(site), i]);

  Future<void> update(Site site, Indicator i) => _setFor(SiteRef.of(site), [
        for (final e in forSite(site)) if (e.id == i.id) i else e,
      ]);

  Future<void> remove(Site site, String id) => _setFor(
        SiteRef.of(site),
        forSite(site).where((e) => e.id != id).toList(),
      );

  /// Même convention que `ReorderableListView.onReorder` : [newIndex] est
  /// donné avant retrait de l'élément déplacé.
  Future<void> reorder(Site site, int oldIndex, int newIndex) {
    final list = [...forSite(site)];
    if (newIndex > oldIndex) newIndex -= 1;
    list.insert(newIndex, list.removeAt(oldIndex));
    return _setFor(SiteRef.of(site), list);
  }

  /// Fusionne des indicateurs venus d'un autre appareil : par site, à id égal
  /// l'entrant gagne → réimporter le même transfert ne duplique pas.
  Future<void> upsertAll(List<SiteIndicators> incoming) {
    final bySite = {for (final s in state) s.site: [...s.indicators]};
    for (final inc in incoming) {
      final list = bySite.putIfAbsent(inc.site, () => []);
      for (final i in inc.indicators) {
        final at = list.indexWhere((e) => e.id == i.id);
        if (at >= 0) {
          list[at] = i;
        } else {
          list.add(i);
        }
      }
    }
    return _save([
      for (final e in bySite.entries)
        if (e.value.isNotEmpty) SiteIndicators(e.key, e.value),
    ]);
  }

  static String newId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}

final indicatorsProvider =
    NotifierProvider<IndicatorsNotifier, List<SiteIndicators>>(
  IndicatorsNotifier.new,
);

final siteIndicatorsProvider = Provider.family<List<Indicator>, Site>(
  (ref, site) => ref.watch(indicatorsProvider.select(
    (all) => all
        .firstWhere(
          (s) => s.site.matches(site),
          orElse: () => SiteIndicators(SiteRef.of(site), const []),
        )
        .indicators,
  )),
);

/// Résultat d'un indicateur sur une fenêtre. L'indicateur fait partie de la
/// clé (égalité par valeur) : le modifier relance le calcul.
final indicatorDataProvider = FutureProvider.autoDispose
    .family<IndicatorData, (Site, DateWindow, Indicator)>(
  retry: retryUnlessMetricsError,
  (ref, key) async {
    cacheFor(ref, kStatsCacheTtl);
    final (site, w, indicator) = key;
    final gate = ref.watch(fetchGateProvider);

    Future<List<SeriesPoint>> count(EventQuery q) async {
      final p = await analyticsProviderFor(ref, site);
      return gate.run(() => p.eventCountSeries(site, w, q));
    }

    switch (indicator) {
      case CounterIndicator(:final query):
        final points = await count(query);
        final total = points.fold<double>(0, (a, b) => a + b.visitors);
        return CounterData(points, total.round());
      case RatioIndicator(:final numerator, :final denominator, :final gapsWhenEmpty):
        final (num, den) = await (count(numerator), count(denominator)).wait;
        return ratioOf(num, den, gapsWhenEmpty: gapsWhenEmpty);
      case FunnelIndicator():
        final p = await analyticsProviderFor(ref, site);
        return FunnelData(await gate.run(() => p.funnel(site, w, indicator)));
      case BreakdownIndicator(:final event, :final property):
        final p = await analyticsProviderFor(ref, site);
        final rows = await gate.run(() => p.propertyValues(site, w, event, property));
        return BreakdownData(rows, rows.fold<int>(0, (a, r) => a + r.value));
      case ExternalIndicator():
        return _externalData(ref, site, w, indicator);
    }
  },
);

/// Données d'une métrique de site : le catalogue (en cache) donne le délai, et
/// pour une famille le membre qui convient à la période.
Future<IndicatorData> _externalData(
  Ref ref,
  Site site,
  DateWindow w,
  ExternalIndicator indicator,
) async {
  final api = await metricsApiFor(ref, site);
  final tz = await deviceTimezone();
  // Le serveur reste la source de vérité du délai et des familles. Catalogue en
  // échec : la métrique de repli, sans délai.
  final defs = await ref
      .read(metricsCatalogueProvider(site).future)
      .catchError((_) => const <MetricDef>[]);
  final family = indicator.familyId;
  final members = family == null
      ? const <MetricDef>[]
      : defs.where((d) => d.famille == family).toList();
  final def = members.isNotEmpty
      ? chooseFamilyMember(members, windowDays(w))
      : defs.where((d) => d.id == indicator.metricId).firstOrNull;
  final id = def?.id ?? indicator.metricId;
  final delay = def?.delaiJours ?? 0;
  final range = metricsRangeFor(w, delayDays: delay);
  final gate = ref.read(fetchGateProvider);
  final series =
      await gate.run(() => api.series(ids: [id], range: range, tz: tz));
  // ⚠️ `now` est lu ici, jamais dans une clé de `family` (cf. « Chargement
  // infini »).
  return externalDataOf(
    indicator.unit,
    w,
    series[id] ?? const [],
    delayDays: delay,
    now: DateTime.now(),
    member: members.isNotEmpty ? 'J$delay' : null,
  );
}

// Aides de l'éditeur. ⚠️ Troisième exception à « tout écran lit
// `windowProvider` » (avec `siteHasEventsProvider` et le test de connexion) :
// les suggestions portent sur 30 jours fixes, indépendants de la période
// affichée. Sinon un indicateur sur un événement rare n'aurait aucune
// suggestion sur « Aujourd'hui ».
const _editorCache = Duration(minutes: 10);

final eventNamesProvider =
    FutureProvider.autoDispose.family<List<String>, Site>((ref, site) async {
  cacheFor(ref, _editorCache);
  final gate = ref.watch(fetchGateProvider);
  final p = await analyticsProviderFor(ref, site);
  final rows = await gate.run(
    () => p.metric(site, Period.d30.window(), MetricType.events,
        limit: kMetricFetchLimit),
  );
  return [for (final r in rows) r.label];
});

final eventPropertiesProvider = FutureProvider.autoDispose
    .family<List<EventProperty>, (Site, String)>((ref, key) async {
  cacheFor(ref, _editorCache);
  final (site, event) = key;
  final gate = ref.watch(fetchGateProvider);
  final p = await analyticsProviderFor(ref, site);
  return gate.run(() => p.eventProperties(site, Period.d30.window(), event));
});

final propertyValuesProvider = FutureProvider.autoDispose
    .family<List<MetricRow>, (Site, String, String)>((ref, key) async {
  cacheFor(ref, _editorCache);
  final (site, event, property) = key;
  final gate = ref.watch(fetchGateProvider);
  final p = await analyticsProviderFor(ref, site);
  return gate.run(
    () => p.propertyValues(site, Period.d30.window(), event, property),
  );
});
