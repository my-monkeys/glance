import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app_localizations.dart';
import 'display_names.dart';

export 'app_localizations.dart';

/// Langue de repli quand le système n'est dans aucune langue prise en charge.
const kFallbackLocale = Locale('en');

extension GlanceL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Pose `Intl.defaultLocale` et charge les symboles de date avant que l'arbre
/// ne se reconstruise dans la nouvelle langue : les fonctions de `core/format`
/// n'ont pas de BuildContext et lisent ce défaut.
class _Formats {
  const _Formats();
}

class _FormatsDelegate extends LocalizationsDelegate<_Formats> {
  const _FormatsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<_Formats> load(Locale locale) {
    final tag = Intl.canonicalizedLocale(locale.toString());
    Intl.defaultLocale = tag;
    // Les données de date locales sont déjà en mémoire : le chargement est
    // synchrone en pratique, ce qui évite un premier cadre vide.
    initializeDateFormatting(tag);
    return SynchronousFuture(const _Formats());
  }

  @override
  bool shouldReload(_FormatsDelegate old) => false;
}

const glanceLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  _FormatsDelegate(),
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Première langue du système que l'app sait afficher (région ou script
/// compris si on les traduit à part : `pt_BR`, `zh_Hans`), sinon l'anglais.
Locale resolveGlanceLocale(
  List<Locale>? requested,
  Iterable<Locale> supported,
) {
  for (final want in requested ?? const <Locale>[]) {
    final exact = supported.where(
      (s) =>
          s.languageCode == want.languageCode &&
          (s.scriptCode == null || s.scriptCode == want.scriptCode) &&
          (s.countryCode == null || s.countryCode == want.countryCode),
    );
    if (exact.isNotEmpty) return exact.first;
    final sameLanguage = supported.where(
      (s) => s.languageCode == want.languageCode,
    );
    if (sameLanguage.isNotEmpty) return sameLanguage.first;
  }
  return kFallbackLocale;
}

/// Étiquette BCP 47 à la mode CLDR (`pt-BR`, `zh-Hans`), celle des tables
/// générées et des réglages.
String localeTag(Locale l) => l.toLanguageTag();

Locale? parseLocaleTag(String? tag) {
  if (tag == null || tag.isEmpty) return null;
  final parts = tag.split('-');
  return switch (parts.length) {
    1 => Locale(parts[0]),
    _ when parts[1].length == 4 => Locale.fromSubtags(
      languageCode: parts[0],
      scriptCode: parts[1],
    ),
    _ => Locale(parts[0], parts[1]),
  };
}

/// Nom d'une langue de l'app dans cette même langue (« Français », « English »).
String nativeLanguageName(Locale l) {
  final tag = localeTag(l);
  final name = kLanguageNames[tag]?[tag] ?? kLanguageNames[tag]?[l.languageCode];
  return toBeginningOfSentenceCase(name ?? tag, tag) ?? tag;
}

/// Table CLDR de la langue active, avec repli sur la langue seule puis l'anglais.
String? lookupDisplayName(
  Map<String, Map<String, String>> tables,
  String code,
) {
  final tag = Intl.defaultLocale ?? kFallbackLocale.languageCode;
  final lang = tag.split(RegExp('[-_]')).first;
  for (final key in [
    tag.replaceAll('_', '-'),
    ...tables.keys.where((k) => k.startsWith('$lang-') || k == lang),
    'en',
  ]) {
    final name = tables[key]?[code];
    if (name != null) return name;
  }
  return null;
}
