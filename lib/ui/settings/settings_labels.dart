import '../../core/predict.dart';
import '../../data/models/period.dart';
import '../../l10n/l10n.dart';
import '../../state/settings.dart';

extension ThemeChoiceLabel on ThemeChoice {
  String localized(AppLocalizations l10n) => switch (this) {
    ThemeChoice.auto => l10n.settingsThemeAuto,
    ThemeChoice.clair => l10n.settingsThemeLight,
    ThemeChoice.sombre => l10n.settingsThemeDark,
  };
}

extension CompareBaseLabel on CompareBase {
  String localized(AppLocalizations l10n) => switch (this) {
    CompareBase.dayBefore => l10n.compareBaseDayBefore,
    CompareBase.weekBefore => l10n.compareBaseWeekBefore,
  };
}

/// Nom de la courbe comparée sur [w] : « 7 jours avant » pour une journée
/// comparée à la semaine d'avant, sinon null (« Période précédente »).
String? compareLabelFor(AppLocalizations l10n, DateWindow w, CompareBase base) =>
    compareBaseApplies(w) && base == CompareBase.weekBefore
        ? l10n.compareBaseWeekBefore
        : null;

extension WeekStartLabel on WeekStart {
  String localized(AppLocalizations l10n) => switch (this) {
    WeekStart.monday => l10n.weekStartMonday,
    WeekStart.sunday => l10n.weekStartSunday,
  };
}

extension ChartStyleLabel on ChartStyle {
  String localized(AppLocalizations l10n) => switch (this) {
    ChartStyle.curve => l10n.settingsChartCurve,
    ChartStyle.bars => l10n.settingsChartBars,
  };
}
