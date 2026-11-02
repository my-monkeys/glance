import '../../l10n/l10n.dart';
import '../../state/settings.dart';

extension ThemeChoiceLabel on ThemeChoice {
  String localized(AppLocalizations l10n) => switch (this) {
    ThemeChoice.auto => l10n.settingsThemeAuto,
    ThemeChoice.clair => l10n.settingsThemeLight,
    ThemeChoice.sombre => l10n.settingsThemeDark,
  };
}

extension ChartStyleLabel on ChartStyle {
  String localized(AppLocalizations l10n) => switch (this) {
    ChartStyle.curve => l10n.settingsChartCurve,
    ChartStyle.bars => l10n.settingsChartBars,
  };
}
