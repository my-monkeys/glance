import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/period.dart';
import 'period_state.dart';
import 'providers.dart';

enum ThemeChoice {
  auto('Auto', ThemeMode.system),
  clair('Clair', ThemeMode.light),
  sombre('Sombre', ThemeMode.dark);

  const ThemeChoice(this.label, this.mode);
  final String label;
  final ThemeMode mode;
}

/// Disposition de la liste des sites sur l'accueil.
enum HomeViewMode { list, grid }

@immutable
class Settings {
  const Settings({
    this.theme = ThemeChoice.auto,
    this.refreshSeconds = 30,
    this.homeView = HomeViewMode.list,
    this.directOnlyLive = false,
    this.hiddenSeries = const {},
    this.defaultPeriod = Period.d7,
    this.hideZeroSites = false,
  });

  final ThemeChoice theme;
  final int refreshSeconds;
  final HomeViewMode homeView;
  final bool directOnlyLive; // Direct : « Actifs seulement »
  final Set<String> hiddenSeries; // séries masquées sur les gros graphes
  final Period defaultPeriod; // période affichée au lancement
  final bool hideZeroSites; // masque les sites à 0 visiteur (liste desktop)

  Settings copyWith({
    ThemeChoice? theme,
    int? refreshSeconds,
    HomeViewMode? homeView,
    bool? directOnlyLive,
    Set<String>? hiddenSeries,
    Period? defaultPeriod,
    bool? hideZeroSites,
  }) => Settings(
    theme: theme ?? this.theme,
    refreshSeconds: refreshSeconds ?? this.refreshSeconds,
    homeView: homeView ?? this.homeView,
    directOnlyLive: directOnlyLive ?? this.directOnlyLive,
    hiddenSeries: hiddenSeries ?? this.hiddenSeries,
    defaultPeriod: defaultPeriod ?? this.defaultPeriod,
    hideZeroSites: hideZeroSites ?? this.hideZeroSites,
  );
}

class SettingsNotifier extends Notifier<Settings> {
  static const _kTheme = 'glance.theme';
  static const _kRefresh = 'glance.refresh';
  static const _kHomeView = 'glance.homeView';
  static const _kDirectOnlyLive = 'glance.direct.onlyLive';
  static const _kHiddenSeries = 'glance.chart.hidden';
  static const _kDefaultPeriod = 'glance.period.default';
  static const _kHideZeroSites = 'glance.sites.hideZero';

  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  @override
  Settings build() {
    return Settings(
      theme: ThemeChoice.values.firstWhere(
        (t) => t.name == _p.getString(_kTheme),
        orElse: () => ThemeChoice.auto,
      ),
      refreshSeconds: _p.getInt(_kRefresh) ?? 30,
      homeView: HomeViewMode.values.firstWhere(
        (v) => v.name == _p.getString(_kHomeView),
        orElse: () => HomeViewMode.list,
      ),
      directOnlyLive: _p.getBool(_kDirectOnlyLive) ?? false,
      hiddenSeries:
          (_p.getStringList(_kHiddenSeries) ?? const <String>[]).toSet(),
      defaultPeriod:
          Period.fromKey(_p.getString(_kDefaultPeriod) ?? Period.d7.key),
      hideZeroSites: _p.getBool(_kHideZeroSites) ?? false,
    );
  }

  void setHomeView(HomeViewMode v) {
    _p.setString(_kHomeView, v.name);
    state = state.copyWith(homeView: v);
  }

  /// Change la période par défaut (persistée) et l'applique tout de suite.
  void setDefaultPeriod(Period period) {
    _p.setString(_kDefaultPeriod, period.key);
    state = state.copyWith(defaultPeriod: period);
    ref.read(periodProvider.notifier).set(period);
  }

  void setDirectOnlyLive(bool v) {
    _p.setBool(_kDirectOnlyLive, v);
    state = state.copyWith(directOnlyLive: v);
  }

  void setHideZeroSites(bool v) {
    _p.setBool(_kHideZeroSites, v);
    state = state.copyWith(hideZeroSites: v);
  }

  void toggleSeries(String key) {
    final next = {...state.hiddenSeries};
    if (!next.remove(key)) next.add(key);
    _p.setStringList(_kHiddenSeries, next.toList());
    state = state.copyWith(hiddenSeries: next);
  }

  void setTheme(ThemeChoice t) {
    _p.setString(_kTheme, t.name);
    state = state.copyWith(theme: t);
  }

  void setRefresh(int seconds) {
    _p.setInt(_kRefresh, seconds);
    state = state.copyWith(refreshSeconds: seconds);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);
