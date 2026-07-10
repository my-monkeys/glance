import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    this.spike = true,
    this.daily = true,
    this.goals = false,
    this.homeView = HomeViewMode.list,
    this.directOnlyLive = false,
  });

  final ThemeChoice theme;
  final int refreshSeconds;
  final bool spike;
  final bool daily;
  final bool goals;
  final HomeViewMode homeView;
  final bool directOnlyLive; // Direct : « Actifs seulement »

  Settings copyWith({
    ThemeChoice? theme,
    int? refreshSeconds,
    bool? spike,
    bool? daily,
    bool? goals,
    HomeViewMode? homeView,
    bool? directOnlyLive,
  }) => Settings(
    theme: theme ?? this.theme,
    refreshSeconds: refreshSeconds ?? this.refreshSeconds,
    spike: spike ?? this.spike,
    daily: daily ?? this.daily,
    goals: goals ?? this.goals,
    homeView: homeView ?? this.homeView,
    directOnlyLive: directOnlyLive ?? this.directOnlyLive,
  );
}

class SettingsNotifier extends Notifier<Settings> {
  static const _kTheme = 'glance.theme';
  static const _kRefresh = 'glance.refresh';
  static const _kSpike = 'glance.notif.spike';
  static const _kDaily = 'glance.notif.daily';
  static const _kGoals = 'glance.notif.goals';
  static const _kHomeView = 'glance.homeView';
  static const _kDirectOnlyLive = 'glance.direct.onlyLive';

  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  @override
  Settings build() {
    return Settings(
      theme: ThemeChoice.values.firstWhere(
        (t) => t.name == _p.getString(_kTheme),
        orElse: () => ThemeChoice.auto,
      ),
      refreshSeconds: _p.getInt(_kRefresh) ?? 30,
      spike: _p.getBool(_kSpike) ?? true,
      daily: _p.getBool(_kDaily) ?? true,
      goals: _p.getBool(_kGoals) ?? false,
      homeView: HomeViewMode.values.firstWhere(
        (v) => v.name == _p.getString(_kHomeView),
        orElse: () => HomeViewMode.list,
      ),
      directOnlyLive: _p.getBool(_kDirectOnlyLive) ?? false,
    );
  }

  void setHomeView(HomeViewMode v) {
    _p.setString(_kHomeView, v.name);
    state = state.copyWith(homeView: v);
  }

  void setDirectOnlyLive(bool v) {
    _p.setBool(_kDirectOnlyLive, v);
    state = state.copyWith(directOnlyLive: v);
  }

  void setTheme(ThemeChoice t) {
    _p.setString(_kTheme, t.name);
    state = state.copyWith(theme: t);
  }

  void setRefresh(int seconds) {
    _p.setInt(_kRefresh, seconds);
    state = state.copyWith(refreshSeconds: seconds);
  }

  void toggleSpike() {
    _p.setBool(_kSpike, !state.spike);
    state = state.copyWith(spike: !state.spike);
  }

  void toggleDaily() {
    _p.setBool(_kDaily, !state.daily);
    state = state.copyWith(daily: !state.daily);
  }

  void toggleGoals() {
    _p.setBool(_kGoals, !state.goals);
    state = state.copyWith(goals: !state.goals);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);
