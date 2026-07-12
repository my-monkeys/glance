import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:home_widget/home_widget.dart';

import 'home_data.dart';

/// Publie les données de l'accueil vers les widgets d'écran d'accueil (iOS +
/// Android) via un conteneur partagé (App Group iOS / SharedPreferences Android).
///
/// On écrit des valeurs simples (nombres + chaînes) : les sparklines voyagent
/// en CSV et sont dessinées nativement (SwiftUI / Canvas), plus net et sans la
/// limite de rendu d'image en arrière-plan.
class WidgetPublisher {
  static const appGroupId = 'group.fr.mymonkey.glance';

  /// Nombre de sites embarqués dans le widget multi-sites.
  static const _maxSites = 6;

  static bool get _supported => Platform.isIOS || Platform.isAndroid;

  static Future<void> init() async {
    if (!_supported) return;
    await HomeWidget.setAppGroupId(appGroupId);
  }

  static String _spark(List<double> values) {
    if (values.isEmpty) return '';
    // Downsample doux à ~24 points max pour un CSV compact.
    const maxPts = 24;
    final step = values.length <= maxPts ? 1 : (values.length / maxPts).ceil();
    final out = <int>[];
    for (var i = 0; i < values.length; i += step) {
      out.add(values[i].round());
    }
    return out.join(',');
  }

  static Future<void> publish(HomeData data, String periodLabel) async {
    if (!_supported) return;

    Future<void> set(String k, Object? v) =>
        v == null ? Future.value() : HomeWidget.saveWidgetData(k, v);

    await set('updated_at', DateTime.now().millisecondsSinceEpoch);
    await set('period_label', periodLabel);
    await set('total_visitors', data.totalVisitors);
    await set('total_pageviews', data.totalPageviews);
    await set('total_visits', data.totalVisits);
    await set('total_sites', data.cards.length);
    await set('total_delta', data.totalDeltaPct); // double? — absent si null
    await set('total_spark',
        _spark(data.totalSeries.map((e) => e.visitors).toList()));

    final top = [...data.cards]
      ..sort((a, b) => b.summary.visitors.compareTo(a.summary.visitors));

    // Top sites (widget « Aperçu » moyen/grand).
    final n = math.min(_maxSites, top.length);
    await set('site_count', n);
    for (var i = 0; i < n; i++) {
      final c = top[i];
      await set('site_${i}_name', c.site.name);
      await set('site_${i}_domain', c.site.domain);
      await set('site_${i}_value', c.summary.visitors);
      await set('site_${i}_delta', c.summary.visitorsDeltaPct);
      await set('site_${i}_spark',
          _spark(c.series.map((e) => e.visitors).toList()));
    }

    // Tous les sites (widget « par site » configurable : sélecteur + rendu).
    final all = [
      for (final c in top)
        {
          'i': c.site.id,
          'n': c.site.name,
          'v': c.summary.visitors,
          'p': c.summary.pageviews,
          if (c.summary.visitorsDeltaPct != null)
            'd': c.summary.visitorsDeltaPct,
          's': _spark(c.series.map((e) => e.visitors).toList()),
        }
    ];
    await set('all_sites', jsonEncode(all));

    // Recharge les timelines des widgets. iOSName = `kind` du widget.
    await HomeWidget.updateWidget(iOSName: 'GlanceOverviewWidget');
    await HomeWidget.updateWidget(
      iOSName: 'GlanceSiteWidget',
      androidName: 'GlanceOverviewWidgetProvider',
    );
  }
}
