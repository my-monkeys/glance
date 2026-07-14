import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import 'home_data.dart';

/// Publie les données de l'accueil vers les widgets d'écran d'accueil (iOS +
/// Android + macOS) via un conteneur partagé.
///
/// iOS / Android passent par le plugin `home_widget` (App Group / SharedPreferences).
/// **macOS n'est pas supporté par `home_widget`** : on écrit alors nous-mêmes
/// dans l'App Group via un MethodChannel natif (cf. `MainFlutterWindow.swift`).
///
/// On écrit des valeurs simples (nombres + chaînes) : les sparklines voyagent
/// en CSV et sont dessinées nativement (SwiftUI / Canvas).
class WidgetPublisher {
  static const appGroupId = 'group.fr.mymonkey.glance';

  /// Canal natif pour macOS (home_widget n'a pas d'impl macOS).
  static const _macChannel = MethodChannel('fr.mymonkey.glance/widget');

  /// Nombre de sites embarqués dans le widget multi-sites.
  static const _maxSites = 6;

  static bool get _viaHomeWidget => Platform.isIOS || Platform.isAndroid;
  static bool get _supported => _viaHomeWidget || Platform.isMacOS;

  static Future<void> init() async {
    if (!_viaHomeWidget) return; // macOS : rien à initialiser côté plugin.
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

    // Construit une fois l'ensemble des clés (source unique), puis dispatche
    // selon la plateforme. Une valeur nulle = clé absente (pas de delta, etc.).
    final values = <String, Object?>{};
    values['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    values['period_label'] = periodLabel;
    values['total_visitors'] = data.totalVisitors;
    values['total_pageviews'] = data.totalPageviews;
    values['total_visits'] = data.totalVisits;
    values['total_sites'] = data.cards.length;
    values['total_delta'] = data.totalDeltaPct; // double? — absent si null
    values['total_spark'] =
        _spark(data.totalSeries.map((e) => e.visitors).toList());

    final top = [...data.cards]
      ..sort((a, b) => b.summary.visitors.compareTo(a.summary.visitors));

    // Top sites (widget « Aperçu » moyen/grand).
    final n = math.min(_maxSites, top.length);
    values['site_count'] = n;
    for (var i = 0; i < n; i++) {
      final c = top[i];
      values['site_${i}_name'] = c.site.name;
      values['site_${i}_domain'] = c.site.domain;
      values['site_${i}_value'] = c.summary.visitors;
      values['site_${i}_delta'] = c.summary.visitorsDeltaPct;
      values['site_${i}_spark'] =
          _spark(c.series.map((e) => e.visitors).toList());
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
    values['all_sites'] = jsonEncode(all);

    if (_viaHomeWidget) {
      await _publishViaHomeWidget(values);
    } else {
      await _publishViaMac(values);
    }
  }

  static Future<void> _publishViaHomeWidget(Map<String, Object?> values) async {
    for (final entry in values.entries) {
      if (entry.value != null) {
        await HomeWidget.saveWidgetData(entry.key, entry.value);
      }
    }
    // Recharge les timelines des widgets (iOSName = `kind`, androidName = provider).
    await HomeWidget.updateWidget(
      iOSName: 'GlanceOverviewWidget',
      androidName: 'GlanceOverviewWidgetProvider',
    );
    await HomeWidget.updateWidget(
      iOSName: 'GlanceSiteWidget',
      androidName: 'GlanceSiteWidgetProvider',
    );
  }

  static Future<void> _publishViaMac(Map<String, Object?> values) async {
    // Le natif écrit chaque clé dans l'App Group (null → clé retirée) puis
    // recharge toutes les timelines WidgetKit.
    await _macChannel.invokeMethod('saveData', values);
    await _macChannel.invokeMethod('reload');
  }
}
