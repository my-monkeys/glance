// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get settingsLanguageTitle => 'Langue';

  @override
  String get settingsLanguageAuto => 'Automatique';

  @override
  String dayRange(String from, String to) {
    return 'du $from au $to';
  }
}
