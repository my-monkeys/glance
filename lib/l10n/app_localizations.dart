import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Titre du réglage de langue dans Réglages
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageAuto.
  ///
  /// In fr, this message translates to:
  /// **'Automatique'**
  String get settingsLanguageAuto;

  /// Plage de jours : « du 7 au 13 oct. »
  ///
  /// In fr, this message translates to:
  /// **'du {from} au {to}'**
  String dayRange(String from, String to);

  /// No description provided for @commonClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get commonClose;

  /// No description provided for @commonClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get commonClear;

  /// No description provided for @commonRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get commonRetry;

  /// Onglet de la barre du bas : la liste des sites
  ///
  /// In fr, this message translates to:
  /// **'Sites'**
  String get tabSites;

  /// Onglet de la barre du bas : visiteurs en direct
  ///
  /// In fr, this message translates to:
  /// **'Direct'**
  String get tabDirect;

  /// Onglet de la barre du bas
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get tabSettings;

  /// No description provided for @siteSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un site'**
  String get siteSearchHint;

  /// No description provided for @siteSearchNoMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucun site ne correspond à « {query} ».'**
  String siteSearchNoMatch(String query);

  /// No description provided for @navToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get navToday;

  /// No description provided for @navYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get navYesterday;

  /// No description provided for @navDayBeforeYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Avant-hier'**
  String get navDayBeforeYesterday;

  /// No description provided for @navThisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois-ci'**
  String get navThisMonth;

  /// No description provided for @navLastMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois dernier'**
  String get navLastMonth;

  /// No description provided for @navThisYear.
  ///
  /// In fr, this message translates to:
  /// **'Cette année'**
  String get navThisYear;

  /// No description provided for @navLastYear.
  ///
  /// In fr, this message translates to:
  /// **'Année dernière'**
  String get navLastYear;

  /// Titre de la feuille qui liste les groupes de sites ; le périmètre = les sites affichés
  ///
  /// In fr, this message translates to:
  /// **'Périmètre'**
  String get workspaceSheetTitle;

  /// No description provided for @workspaceAllSites.
  ///
  /// In fr, this message translates to:
  /// **'Tous les sites'**
  String get workspaceAllSites;

  /// No description provided for @workspaceTrackedSites.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 site suivi} =1{1 site suivi} other{{count} sites suivis}}'**
  String workspaceTrackedSites(int count);

  /// No description provided for @workspaceSiteCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun site} =1{1 site} other{{count} sites}}'**
  String workspaceSiteCount(int count);

  /// No description provided for @workspaceNewGroup.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau groupe'**
  String get workspaceNewGroup;

  /// No description provided for @workspaceManageGroups.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les groupes'**
  String get workspaceManageGroups;

  /// Titre de l'accueil quand aucun groupe n'est actif
  ///
  /// In fr, this message translates to:
  /// **'Mes sites'**
  String get homeTitleDefault;

  /// No description provided for @homeLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Chargement impossible.'**
  String get homeLoadFailed;

  /// Carte : visiteurs que les sites suivis s'envoient entre eux
  ///
  /// In fr, this message translates to:
  /// **'Entre vos sites'**
  String get homeInternalTitle;

  /// No description provided for @homeTotalVisitors.
  ///
  /// In fr, this message translates to:
  /// **'Visiteurs · {name}'**
  String homeTotalVisitors(String name);

  /// No description provided for @homeTotalVisitorsAll.
  ///
  /// In fr, this message translates to:
  /// **'Visiteurs · tous les sites'**
  String get homeTotalVisitorsAll;

  /// No description provided for @homeVsPrevious.
  ///
  /// In fr, this message translates to:
  /// **'vs période préc.'**
  String get homeVsPrevious;

  /// No description provided for @homeLiveCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} live'**
  String homeLiveCount(int count);

  /// No description provided for @homeEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun site affiché'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucun site suivi pour le moment. Choisis ceux à afficher.'**
  String get homeEmptyBody;

  /// No description provided for @homeEmptyChooseSites.
  ///
  /// In fr, this message translates to:
  /// **'Choisir les sites'**
  String get homeEmptyChooseSites;

  /// No description provided for @homeEmptyAddSource.
  ///
  /// In fr, this message translates to:
  /// **'+ Ajouter une source'**
  String get homeEmptyAddSource;

  /// No description provided for @homeEmptyGroupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Groupe vide'**
  String get homeEmptyGroupTitle;

  /// No description provided for @homeEmptyGroupBody.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » ne contient aucun site.'**
  String homeEmptyGroupBody(String name);

  /// No description provided for @homeEmptyGroupChoose.
  ///
  /// In fr, this message translates to:
  /// **'Choisir ses sites'**
  String get homeEmptyGroupChoose;

  /// No description provided for @homeEmptyGroupSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous les sites'**
  String get homeEmptyGroupSeeAll;

  /// No description provided for @homeWelcomeTagline.
  ///
  /// In fr, this message translates to:
  /// **'Vos statistiques, en un clin d\'œil.'**
  String get homeWelcomeTagline;

  /// No description provided for @homeWelcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez votre premier outil'**
  String get homeWelcomeTitle;

  /// No description provided for @homeWelcomeBody.
  ///
  /// In fr, this message translates to:
  /// **'Umami, Plausible… ajoutez une source puis choisissez les sites à suivre.'**
  String get homeWelcomeBody;

  /// No description provided for @homeWelcomeAddSource.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une source'**
  String get homeWelcomeAddSource;

  /// No description provided for @homeWelcomeFootnote.
  ///
  /// In fr, this message translates to:
  /// **'Clé en lecture seule · vos données restent chez vous'**
  String get homeWelcomeFootnote;

  /// No description provided for @homeSiteUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Indisponible'**
  String get homeSiteUnavailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
