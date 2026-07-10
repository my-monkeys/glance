import '../models/models.dart';
import '../models/period.dart';
import 'analytics_provider.dart';

/// Emplacement réservé pour Fathom. L'interface est prête ; l'implémentation
/// sera branchée quand on aura une instance à tester.
class FathomProvider extends AnalyticsProvider {
  FathomProvider(super.account, super.creds);

  Never _todo() => throw UnimplementedError('Fathom arrive bientôt.');

  @override
  Future<int> verify() => _todo();
  @override
  Future<List<Site>> listSites() => _todo();
  @override
  Future<StatsSummary> summary(Site site, DateWindow w) => _todo();
  @override
  Future<List<SeriesPoint>> series(Site site, DateWindow w) => _todo();
  @override
  Future<int> active(Site site) => _todo();
  @override
  Future<List<MetricRow>> metric(Site site, DateWindow w, MetricType type,
          {int limit = 8}) =>
      _todo();
  @override
  Future<List<LivePage>> livePages(Site site) => _todo();
  @override
  Future<List<EventSeries>> eventSeries(Site site, DateWindow w) => _todo();
}
