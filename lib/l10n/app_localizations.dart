import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
    Locale('zh'),
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

  /// No description provided for @detailVisitorsUnique.
  ///
  /// In fr, this message translates to:
  /// **'Visiteurs uniques'**
  String get detailVisitorsUnique;

  /// Carte KPI : nombre de visites
  ///
  /// In fr, this message translates to:
  /// **'Visites'**
  String get detailKpiVisits;

  /// Carte KPI : durée moyenne d'une visite, libellé très court
  ///
  /// In fr, this message translates to:
  /// **'Durée moy.'**
  String get detailKpiAvgDuration;

  /// Carte KPI : taux de rebond, libellé très court
  ///
  /// In fr, this message translates to:
  /// **'Rebond'**
  String get detailKpiBounce;

  /// No description provided for @detailLiveNow.
  ///
  /// In fr, this message translates to:
  /// **'En direct maintenant'**
  String get detailLiveNow;

  /// No description provided for @detailLiveNobody.
  ///
  /// In fr, this message translates to:
  /// **'Personne pour l\'instant.'**
  String get detailLiveNobody;

  /// Onglet du détail d'un site ; trois onglets partagent une ligne étroite
  ///
  /// In fr, this message translates to:
  /// **'Vue d\'ensemble'**
  String get detailTabOverview;

  /// Onglet du détail d'un site
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get detailTabEvents;

  /// Onglet du détail d'un site : indicateurs composés par l'utilisateur
  ///
  /// In fr, this message translates to:
  /// **'Tableaux'**
  String get detailTabDashboards;

  /// No description provided for @detailEventsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement sur cette période'**
  String get detailEventsEmpty;

  /// No description provided for @detailEventsTriggered.
  ///
  /// In fr, this message translates to:
  /// **'Événements déclenchés'**
  String get detailEventsTriggered;

  /// No description provided for @detailEventsByEvent.
  ///
  /// In fr, this message translates to:
  /// **'Par événement'**
  String get detailEventsByEvent;

  /// No description provided for @detailSectionViewAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir les {count} lignes'**
  String detailSectionViewAll(int count);

  /// Badge sur un référent qui est l'un des sites suivis par l'utilisateur
  ///
  /// In fr, this message translates to:
  /// **'INTERNE'**
  String get detailBadgeInternal;

  /// Petit titre au-dessus de « En direct »
  ///
  /// In fr, this message translates to:
  /// **'Temps réel'**
  String get directEyebrow;

  /// No description provided for @directTitle.
  ///
  /// In fr, this message translates to:
  /// **'En direct'**
  String get directTitle;

  /// Texte de la pastille live, à côté du nombre de visiteurs
  ///
  /// In fr, this message translates to:
  /// **'en ce moment'**
  String get directNow;

  /// No description provided for @directVisitorsAll.
  ///
  /// In fr, this message translates to:
  /// **'visiteurs sur l\'ensemble de vos sites'**
  String get directVisitorsAll;

  /// No description provided for @directVisitorsGroup.
  ///
  /// In fr, this message translates to:
  /// **'visiteurs sur le groupe « {name} »'**
  String directVisitorsGroup(String name);

  /// No description provided for @directBySite.
  ///
  /// In fr, this message translates to:
  /// **'Par site'**
  String get directBySite;

  /// Interrupteur : masquer les sites sans visiteur en direct
  ///
  /// In fr, this message translates to:
  /// **'Actifs seulement'**
  String get directOnlyActive;

  /// No description provided for @directNoneLive.
  ///
  /// In fr, this message translates to:
  /// **'Aucun visiteur en direct pour l\'instant.'**
  String get directNoneLive;

  /// No description provided for @directNoSites.
  ///
  /// In fr, this message translates to:
  /// **'Aucun site.'**
  String get directNoSites;

  /// No description provided for @directHiddenSites.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 site sans visiteur masqué} other{{count} sites sans visiteur masqués}}'**
  String directHiddenSites(int count);

  /// No description provided for @networkExchanged.
  ///
  /// In fr, this message translates to:
  /// **'Visiteurs échangés · {period}'**
  String networkExchanged(String period);

  /// No description provided for @networkPending.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 site en cours…} other{{count} sites en cours…}}'**
  String networkPending(int count);

  /// No description provided for @networkExplainer.
  ///
  /// In fr, this message translates to:
  /// **'Visiteurs arrivés sur un de vos sites depuis un autre de vos sites.'**
  String get networkExplainer;

  /// No description provided for @networkEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune navigation interne sur cette période.'**
  String get networkEmpty;

  /// Carte : sites qui envoient des visiteurs vers d'autres sites
  ///
  /// In fr, this message translates to:
  /// **'Qui envoie'**
  String get networkSenders;

  /// Carte : sites qui reçoivent des visiteurs d'autres sites
  ///
  /// In fr, this message translates to:
  /// **'Qui reçoit'**
  String get networkReceivers;

  /// Carte : liste des paires site source → site destination
  ///
  /// In fr, this message translates to:
  /// **'Flux'**
  String get networkFlows;

  /// No description provided for @commonEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get commonEdit;

  /// No description provided for @commonDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get commonDelete;

  /// No description provided for @commonSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get commonSave;

  /// Genre d'une carte de tableau, en petites capitales dans l'en-tête
  ///
  /// In fr, this message translates to:
  /// **'Compteur'**
  String get dashboardsKindCounter;

  /// Genre d'une carte de tableau : deux compteurs divisés
  ///
  /// In fr, this message translates to:
  /// **'Taux'**
  String get dashboardsKindRatio;

  /// Genre d'une carte de tableau
  ///
  /// In fr, this message translates to:
  /// **'Entonnoir'**
  String get dashboardsKindFunnel;

  /// Genre d'une carte de tableau : les valeurs d'une propriété
  ///
  /// In fr, this message translates to:
  /// **'Répartition'**
  String get dashboardsKindBreakdown;

  /// Genre d'une carte de tableau : indicateur fourni par la source de métriques du site
  ///
  /// In fr, this message translates to:
  /// **'Métrique'**
  String get dashboardsKindExternal;

  /// Genre d'une carte de tableau : plusieurs sites côte à côte
  ///
  /// In fr, this message translates to:
  /// **'Sites'**
  String get dashboardsKindSites;

  /// Libellé d'accessibilité de la poignée de déplacement d'une carte
  ///
  /// In fr, this message translates to:
  /// **'Déplacer le tableau'**
  String get dashboardsMoveCard;

  /// Libellé d'accessibilité du menu ⋯ d'une carte
  ///
  /// In fr, this message translates to:
  /// **'Options du tableau'**
  String get dashboardsCardOptions;

  /// Libellé d'accessibilité du coin de redimensionnement d'une carte
  ///
  /// In fr, this message translates to:
  /// **'Redimensionner le tableau'**
  String get dashboardsResizeCard;

  /// No description provided for @dashboardsLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Chargement impossible.'**
  String get dashboardsLoadFailed;

  /// No description provided for @dashboardsNoData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée sur la période'**
  String get dashboardsNoData;

  /// No description provided for @dashboardsNoEvents.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement sur la période'**
  String get dashboardsNoEvents;

  /// No description provided for @dashboardsUnpublished.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore publiées : données jusqu\'au {date}'**
  String dashboardsUnpublished(String date);

  /// No description provided for @dashboardsPendingNow.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore mesurable sur cette période'**
  String get dashboardsPendingNow;

  /// Métrique à délai (J1, J7…) : la cohorte n'est pas encore terminée
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Pas encore mesurable : il faut 1 jour de recul} other{Pas encore mesurable : il faut {count} jours de recul}}'**
  String dashboardsPendingDelay(int count);

  /// Note sous le chiffre d'une métrique à délai
  ///
  /// In fr, this message translates to:
  /// **'Mesurée sur la cohorte du {date}'**
  String dashboardsCohortOne(String date);

  /// {range} est une plage de jours déjà formatée (« du 8 au 14 oct. »)
  ///
  /// In fr, this message translates to:
  /// **'Mesurée sur les cohortes {range}'**
  String dashboardsCohortRange(String range);

  /// Famille de métriques : {member} est le membre retenu (J1, J7, J30)
  ///
  /// In fr, this message translates to:
  /// **'{member} · s\'ajuste à la période'**
  String dashboardsFamilyMember(String member);

  /// Dernier jour publié par la source
  ///
  /// In fr, this message translates to:
  /// **'Données jusqu\'au {date}'**
  String dashboardsDataUntil(String date);

  /// Entonnoir : visiteurs de la dernière étape sur ceux de la première
  ///
  /// In fr, this message translates to:
  /// **'{last} / {first} visiteurs'**
  String dashboardsFunnelVisitors(String last, String first);

  /// Infobulle du graphique d'une métrique à délai ; {date} est la date de mesure
  ///
  /// In fr, this message translates to:
  /// **'{date} · cohorte du {cohort}'**
  String dashboardsCohortTooltip(String date, String cohort);

  /// Légende : la courbe de la somme des parts d'un compteur découpé
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get dashboardsTotal;

  /// Part (plateforme) dont la valeur est une estimation
  ///
  /// In fr, this message translates to:
  /// **'{label} · estimé'**
  String dashboardsSegmentEstimated(String label);

  /// No description provided for @dashboardsDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Tableau supprimé'**
  String get dashboardsDeleted;

  /// No description provided for @dashboardsConfirmDelete.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la suppression'**
  String get dashboardsConfirmDelete;

  /// No description provided for @dashboardsAllHidden.
  ///
  /// In fr, this message translates to:
  /// **'Aucun tableau n\'a de données sur cette période'**
  String get dashboardsAllHidden;

  /// Suivi d'un « · Afficher »
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 tableau sans données sur cette période} other{{count} tableaux sans données sur cette période}}'**
  String dashboardsHiddenCount(int count);

  /// Lien qui réaffiche les tableaux sans données
  ///
  /// In fr, this message translates to:
  /// **'Afficher'**
  String get dashboardsShow;

  /// No description provided for @dashboardsArrangeHint.
  ///
  /// In fr, this message translates to:
  /// **'Maintenez une carte pour la déplacer, tirez son coin pour la redimensionner.'**
  String get dashboardsArrangeHint;

  /// Bouton qui passe la grille en mode déplacement/redimensionnement
  ///
  /// In fr, this message translates to:
  /// **'Organiser'**
  String get dashboardsArrange;

  /// Bouton qui quitte le mode Organiser
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get dashboardsArrangeDone;

  /// No description provided for @dashboardsNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau tableau'**
  String get dashboardsNew;

  /// No description provided for @dashboardsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun tableau'**
  String get dashboardsEmptyTitle;

  /// No description provided for @dashboardsEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Suivez un taux, un entonnoir ou une répartition construits sur vos événements.'**
  String get dashboardsEmptyBody;

  /// No description provided for @dashboardsCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer un tableau'**
  String get dashboardsCreate;

  /// No description provided for @dashboardsMetricsSource.
  ///
  /// In fr, this message translates to:
  /// **'Source de métriques'**
  String get dashboardsMetricsSource;

  /// No description provided for @dashboardsMetricsIntro.
  ///
  /// In fr, this message translates to:
  /// **'Une petite API de votre site qui fournit des indicateurs calculés sur sa base (rétention, comptes…) : un catalogue et des séries, protégés par un jeton.'**
  String get dashboardsMetricsIntro;

  /// Lien vers la documentation de la source de métriques
  ///
  /// In fr, this message translates to:
  /// **'Comment ça marche ?'**
  String get dashboardsMetricsHowItWorks;

  /// No description provided for @dashboardsMetricsUrlLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse de l\'API'**
  String get dashboardsMetricsUrlLabel;

  /// Exemple d'adresse, en placeholder
  ///
  /// In fr, this message translates to:
  /// **'https://exemple.fr/api/interne/metriques/'**
  String get dashboardsMetricsUrlHint;

  /// No description provided for @dashboardsMetricsToken.
  ///
  /// In fr, this message translates to:
  /// **'Jeton'**
  String get dashboardsMetricsToken;

  /// No description provided for @dashboardsMetricsTest.
  ///
  /// In fr, this message translates to:
  /// **'Tester'**
  String get dashboardsMetricsTest;

  /// Résultat positif du test de la source
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 indicateur disponible} other{{count} indicateurs disponibles}}'**
  String dashboardsMetricsAvailable(int count);

  /// No description provided for @dashboardsMetricsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Source enregistrée'**
  String get dashboardsMetricsSaved;

  /// No description provided for @dashboardsMetricsRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la source'**
  String get dashboardsMetricsRemove;

  /// Confirmation : les cartes « Métrique » partent avec la source
  ///
  /// In fr, this message translates to:
  /// **'Retirer la source et {count, plural, =1{1 tableau} other{{count} tableaux}}'**
  String dashboardsMetricsRemoveWithCards(int count);

  /// No description provided for @dashboardsMetricsRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Source retirée'**
  String get dashboardsMetricsRemoved;

  /// No description provided for @dashboardsMetricsRemovedWithCards.
  ///
  /// In fr, this message translates to:
  /// **'Source retirée, {count, plural, =1{1 tableau supprimé} other{{count} tableaux supprimés}}'**
  String dashboardsMetricsRemovedWithCards(int count);

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// No description provided for @commonAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get commonAdd;

  /// No description provided for @commonSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get commonSearch;

  /// Nom proposé quand rien n'est encore choisi
  ///
  /// In fr, this message translates to:
  /// **'Sans titre'**
  String get editorNameFallback;

  /// Nom proposé : une répartition « événement par propriété »
  ///
  /// In fr, this message translates to:
  /// **'{a} par {b}'**
  String editorNameBy(String a, String b);

  /// Raison de validation affichée sous l'éditeur
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un événement'**
  String get editorErrChooseEvent;

  /// No description provided for @editorErrChooseCountEvent.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez l\'événement à compter'**
  String get editorErrChooseCountEvent;

  /// Dénominateur d'un taux
  ///
  /// In fr, this message translates to:
  /// **'Choisissez l\'événement de référence'**
  String get editorErrChooseRefEvent;

  /// No description provided for @editorErrChooseProperty.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une propriété'**
  String get editorErrChooseProperty;

  /// No description provided for @editorErrChooseMetric.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une métrique'**
  String get editorErrChooseMetric;

  /// No description provided for @editorErrAddSite.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez au moins un site'**
  String get editorErrAddSite;

  /// No description provided for @editorErrSitesMax.
  ///
  /// In fr, this message translates to:
  /// **'Un tableau compte au plus {max} sites'**
  String editorErrSitesMax(int max);

  /// No description provided for @editorErrChooseLineSite.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le site de chaque ligne'**
  String get editorErrChooseLineSite;

  /// No description provided for @editorErrNameLines.
  ///
  /// In fr, this message translates to:
  /// **'Nommez chaque ligne'**
  String get editorErrNameLines;

  /// No description provided for @editorErrReferrer.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez le domaine du référent'**
  String get editorErrReferrer;

  /// No description provided for @editorErrFunnelMin.
  ///
  /// In fr, this message translates to:
  /// **'Un entonnoir compte au moins {min} étapes'**
  String editorErrFunnelMin(int min);

  /// No description provided for @editorErrFunnelMax.
  ///
  /// In fr, this message translates to:
  /// **'Un entonnoir compte au plus {max} étapes'**
  String editorErrFunnelMax(int max);

  /// No description provided for @editorErrStepEvent.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez l\'événement de l\'étape {n}'**
  String editorErrStepEvent(int n);

  /// No description provided for @editorErrFunnelNumeric.
  ///
  /// In fr, this message translates to:
  /// **'Un entonnoir ne compare pas les nombres : retirez ce filtre'**
  String get editorErrFunnelNumeric;

  /// Délai maximum entre deux étapes d'un entonnoir
  ///
  /// In fr, this message translates to:
  /// **'Délai invalide'**
  String get editorErrWindow;

  /// No description provided for @editorErrFilterValueMissing.
  ///
  /// In fr, this message translates to:
  /// **'Valeur du filtre manquante'**
  String get editorErrFilterValueMissing;

  /// No description provided for @editorErrFilterNotNumber.
  ///
  /// In fr, this message translates to:
  /// **'Valeur de filtre non numérique'**
  String get editorErrFilterNotNumber;

  /// No description provided for @editorTitleEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le tableau'**
  String get editorTitleEdit;

  /// No description provided for @editorFieldName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get editorFieldName;

  /// Titre de section : genre du tableau (compteur, taux…)
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get editorHeadingType;

  /// No description provided for @editorHeadingPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get editorHeadingPreview;

  /// No description provided for @editorPreviewEmpty.
  ///
  /// In fr, this message translates to:
  /// **'L\'aperçu apparaît dès que le tableau est complet.'**
  String get editorPreviewEmpty;

  /// No description provided for @editorCreated.
  ///
  /// In fr, this message translates to:
  /// **'Tableau créé'**
  String get editorCreated;

  /// No description provided for @editorSaved.
  ///
  /// In fr, this message translates to:
  /// **'Tableau enregistré'**
  String get editorSaved;

  /// No description provided for @editorDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce tableau'**
  String get editorDelete;

  /// No description provided for @editorCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get editorCreate;

  /// Numérateur d'un taux
  ///
  /// In fr, this message translates to:
  /// **'Ce qu\'on compte'**
  String get editorCountLabel;

  /// Dénominateur d'un taux
  ///
  /// In fr, this message translates to:
  /// **'Rapporté à'**
  String get editorRatioOf;

  /// No description provided for @editorGapsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Laisser un trou quand rien ne s\'est passé'**
  String get editorGapsLabel;

  /// No description provided for @editorGapsHint.
  ///
  /// In fr, this message translates to:
  /// **'Sinon, ces jours-là comptent pour 0 %.'**
  String get editorGapsHint;

  /// No description provided for @editorOverTimeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Évolution dans le temps'**
  String get editorOverTimeLabel;

  /// No description provided for @editorOverTimeHint.
  ///
  /// In fr, this message translates to:
  /// **'Une courbe par valeur, sur toute la largeur'**
  String get editorOverTimeHint;

  /// No description provided for @editorMetricLabel.
  ///
  /// In fr, this message translates to:
  /// **'Métrique'**
  String get editorMetricLabel;

  /// No description provided for @editorMetricPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une métrique'**
  String get editorMetricPlaceholder;

  /// No description provided for @editorMetricNone.
  ///
  /// In fr, this message translates to:
  /// **'Cette source ne propose aucun indicateur.'**
  String get editorMetricNone;

  /// Sous le nom d'une famille de métriques (J1, J7, J30)
  ///
  /// In fr, this message translates to:
  /// **'s\'ajuste à la période'**
  String get editorMetricAdjusts;

  /// No description provided for @editorEventLabel.
  ///
  /// In fr, this message translates to:
  /// **'Événement'**
  String get editorEventLabel;

  /// No description provided for @editorEventPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un événement'**
  String get editorEventPlaceholder;

  /// Propriété d'un événement
  ///
  /// In fr, this message translates to:
  /// **'Propriété'**
  String get editorPropertyLabel;

  /// No description provided for @editorPropertyPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une propriété'**
  String get editorPropertyPlaceholder;

  /// No description provided for @editorKindExternal.
  ///
  /// In fr, this message translates to:
  /// **'Métrique du site'**
  String get editorKindExternal;

  /// No description provided for @editorKindHintCounter.
  ///
  /// In fr, this message translates to:
  /// **'Combien de fois un événement arrive'**
  String get editorKindHintCounter;

  /// No description provided for @editorKindHintRatio.
  ///
  /// In fr, this message translates to:
  /// **'Un événement rapporté à un autre'**
  String get editorKindHintRatio;

  /// No description provided for @editorKindHintFunnel.
  ///
  /// In fr, this message translates to:
  /// **'Le parcours étape par étape'**
  String get editorKindHintFunnel;

  /// No description provided for @editorKindHintBreakdown.
  ///
  /// In fr, this message translates to:
  /// **'Les valeurs d\'une propriété'**
  String get editorKindHintBreakdown;

  /// No description provided for @editorKindHintExternal.
  ///
  /// In fr, this message translates to:
  /// **'Un indicateur fourni par votre API'**
  String get editorKindHintExternal;

  /// No description provided for @editorKindHintSites.
  ///
  /// In fr, this message translates to:
  /// **'Les visiteurs de plusieurs sites'**
  String get editorKindHintSites;

  /// No description provided for @editorFunnelAddStep.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une étape'**
  String get editorFunnelAddStep;

  /// No description provided for @editorFunnelWindowLabel.
  ///
  /// In fr, this message translates to:
  /// **'Délai maximum entre deux étapes'**
  String get editorFunnelWindowLabel;

  /// No description provided for @editorFunnelWindowHint.
  ///
  /// In fr, this message translates to:
  /// **'En minutes (de {min} à {max}) : un visiteur qui met plus de temps à passer d\'une étape à la suivante n\'est plus compté.'**
  String editorFunnelWindowHint(int min, int max);

  /// Titre d'une carte d'étape, en capitales
  ///
  /// In fr, this message translates to:
  /// **'ÉTAPE {n}'**
  String editorFunnelStep(int n);

  /// No description provided for @editorFunnelMoveUp.
  ///
  /// In fr, this message translates to:
  /// **'Monter l\'étape'**
  String get editorFunnelMoveUp;

  /// No description provided for @editorFunnelMoveDown.
  ///
  /// In fr, this message translates to:
  /// **'Descendre l\'étape'**
  String get editorFunnelMoveDown;

  /// No description provided for @editorFunnelRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer l\'étape'**
  String get editorFunnelRemove;

  /// Type d'une propriété, en petit à droite d'une ligne
  ///
  /// In fr, this message translates to:
  /// **'texte'**
  String get editorTypeText;

  /// No description provided for @editorTypeNumber.
  ///
  /// In fr, this message translates to:
  /// **'nombre'**
  String get editorTypeNumber;

  /// No description provided for @editorTypeBoolean.
  ///
  /// In fr, this message translates to:
  /// **'oui-non'**
  String get editorTypeBoolean;

  /// No description provided for @editorFreeEvent.
  ///
  /// In fr, this message translates to:
  /// **'Saisir un nom d\'événement'**
  String get editorFreeEvent;

  /// No description provided for @editorFreeProperty.
  ///
  /// In fr, this message translates to:
  /// **'Saisir un nom de propriété'**
  String get editorFreeProperty;

  /// No description provided for @editorSiteLabel.
  ///
  /// In fr, this message translates to:
  /// **'Site'**
  String get editorSiteLabel;

  /// Ligne qui valide le texte saisi à la main
  ///
  /// In fr, this message translates to:
  /// **'Utiliser « {value} »'**
  String editorUseTyped(String value);

  /// No description provided for @editorListUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Liste indisponible — saisissez le nom à la main.'**
  String get editorListUnavailable;

  /// No description provided for @editorListEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Rien de vu sur 30 jours — saisissez le nom à la main.'**
  String get editorListEmpty;

  /// No description provided for @editorAddFilter.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un filtre'**
  String get editorAddFilter;

  /// No description provided for @editorRemoveFilter.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le filtre'**
  String get editorRemoveFilter;

  /// No description provided for @editorFilterValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur'**
  String get editorFilterValue;

  /// Valeur booléenne d'un filtre
  ///
  /// In fr, this message translates to:
  /// **'vrai'**
  String get editorTrue;

  /// No description provided for @editorFalse.
  ///
  /// In fr, this message translates to:
  /// **'faux'**
  String get editorFalse;

  /// Filtre de référent d'une ligne : aucun filtre
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get editorModeAll;

  /// Filtre de référent : seulement les visiteurs venus d'un domaine
  ///
  /// In fr, this message translates to:
  /// **'Venus de'**
  String get editorModeOnly;

  /// Filtre de référent : tous sauf ceux venus d'un domaine
  ///
  /// In fr, this message translates to:
  /// **'Sauf venus de'**
  String get editorModeExcept;

  /// No description provided for @editorLineSitePlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un site'**
  String get editorLineSitePlaceholder;

  /// Nom court d'une ligne du tableau Sites
  ///
  /// In fr, this message translates to:
  /// **'Libellé'**
  String get editorLineLabel;

  /// No description provided for @editorLineReferrer.
  ///
  /// In fr, this message translates to:
  /// **'Domaine du référent'**
  String get editorLineReferrer;

  /// No description provided for @editorLineAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un site'**
  String get editorLineAdd;

  /// No description provided for @editorLinesHint.
  ///
  /// In fr, this message translates to:
  /// **'Visiteurs uniques de chaque ligne. « Sauf venus de » retire ceux que le site a reçus de ce domaine.'**
  String get editorLinesHint;

  /// Titre d'une carte de ligne, en capitales
  ///
  /// In fr, this message translates to:
  /// **'LIGNE {n}'**
  String editorLineTitle(int n);

  /// No description provided for @editorLineRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la ligne'**
  String get editorLineRemove;

  /// No description provided for @commonSiteCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 site} =1{1 site} other{{count} sites}}'**
  String commonSiteCount(int count);

  /// Titre de l'écran Réglages
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsTitle;

  /// Intitulé de groupe dans Réglages : les sources analytics
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get settingsGroupAccount;

  /// Intitulé de groupe dans Réglages
  ///
  /// In fr, this message translates to:
  /// **'Sites'**
  String get settingsGroupSites;

  /// Intitulé de groupe dans Réglages
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation'**
  String get settingsGroupSync;

  /// Intitulé de groupe dans Réglages : transfert vers un autre appareil
  ///
  /// In fr, this message translates to:
  /// **'Transfert'**
  String get settingsGroupTransfer;

  /// Intitulé de groupe dans Réglages
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get settingsGroupAppearance;

  /// Intitulé de groupe dans Réglages
  ///
  /// In fr, this message translates to:
  /// **'Données'**
  String get settingsGroupData;

  /// Intitulé de groupe dans Réglages (bureau uniquement)
  ///
  /// In fr, this message translates to:
  /// **'Application'**
  String get settingsGroupApp;

  /// No description provided for @settingsAccountBadAuth.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants ou clé API refusés'**
  String get settingsAccountBadAuth;

  /// No description provided for @settingsAccountUnreachable.
  ///
  /// In fr, this message translates to:
  /// **'Instance injoignable'**
  String get settingsAccountUnreachable;

  /// Sous-titre d'un compte : fournisseur (Umami…) puis nombre de sites
  ///
  /// In fr, this message translates to:
  /// **'{provider} · {count, plural, =0{0 site} =1{1 site} other{{count} sites}}'**
  String settingsAccountSubtitle(String provider, int count);

  /// No description provided for @settingsAddSource.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une source'**
  String get settingsAddSource;

  /// Ligne de Réglages et titre de l'écran des groupes de sites
  ///
  /// In fr, this message translates to:
  /// **'Groupes'**
  String get settingsGroupsTitle;

  /// No description provided for @settingsGroupsHint.
  ///
  /// In fr, this message translates to:
  /// **'Lire une partie de vos sites à part'**
  String get settingsGroupsHint;

  /// No description provided for @settingsSyncConnected.
  ///
  /// In fr, this message translates to:
  /// **'Connecté'**
  String get settingsSyncConnected;

  /// No description provided for @settingsSyncPitch.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder et synchroniser (chiffré)'**
  String get settingsSyncPitch;

  /// No description provided for @settingsTransferShow.
  ///
  /// In fr, this message translates to:
  /// **'Afficher un QR de transfert'**
  String get settingsTransferShow;

  /// No description provided for @settingsTransferNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte à transférer'**
  String get settingsTransferNone;

  /// No description provided for @settingsTransferContents.
  ///
  /// In fr, this message translates to:
  /// **'Comptes, identifiants et groupes'**
  String get settingsTransferContents;

  /// No description provided for @settingsTransferImport.
  ///
  /// In fr, this message translates to:
  /// **'Importer depuis un autre appareil'**
  String get settingsTransferImport;

  /// No description provided for @settingsTransferScan.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un QR de transfert'**
  String get settingsTransferScan;

  /// No description provided for @settingsThemeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get settingsThemeTitle;

  /// Thème de l'app : suit le système
  ///
  /// In fr, this message translates to:
  /// **'Auto'**
  String get settingsThemeAuto;

  /// No description provided for @settingsThemeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get settingsThemeDark;

  /// No description provided for @settingsChartsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Graphiques'**
  String get settingsChartsTitle;

  /// No description provided for @settingsChartsHint.
  ///
  /// In fr, this message translates to:
  /// **'Courbe lissée ou barres'**
  String get settingsChartsHint;

  /// No description provided for @settingsChartCurve.
  ///
  /// In fr, this message translates to:
  /// **'Courbe'**
  String get settingsChartCurve;

  /// No description provided for @settingsChartBars.
  ///
  /// In fr, this message translates to:
  /// **'Barres'**
  String get settingsChartBars;

  /// No description provided for @settingsDefaultPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période par défaut'**
  String get settingsDefaultPeriod;

  /// No description provided for @settingsDefaultPeriodHint.
  ///
  /// In fr, this message translates to:
  /// **'À l\'ouverture de l\'application'**
  String get settingsDefaultPeriodHint;

  /// No description provided for @settingsRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualisation auto'**
  String get settingsRefresh;

  /// Durée d'actualisation en secondes
  ///
  /// In fr, this message translates to:
  /// **'{count} s'**
  String settingsRefreshSeconds(int count);

  /// Durée d'actualisation en minutes
  ///
  /// In fr, this message translates to:
  /// **'{count} min'**
  String settingsRefreshMinutes(int count);

  /// No description provided for @settingsCheckUpdates.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher des mises à jour'**
  String get settingsCheckUpdates;

  /// No description provided for @accountMenuConnectionOk.
  ///
  /// In fr, this message translates to:
  /// **'Connexion réussie'**
  String get accountMenuConnectionOk;

  /// No description provided for @accountMenuConnectionOkSites.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Connexion réussie · 1 site} other{Connexion réussie · {count} sites}}'**
  String accountMenuConnectionOkSites(int count);

  /// No description provided for @accountMenuTest.
  ///
  /// In fr, this message translates to:
  /// **'Tester la connexion'**
  String get accountMenuTest;

  /// No description provided for @accountMenuEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la source'**
  String get accountMenuEdit;

  /// No description provided for @accountMenuEditHint.
  ///
  /// In fr, this message translates to:
  /// **'URL, identifiants, clé API…'**
  String get accountMenuEditHint;

  /// No description provided for @accountMenuChooseSites.
  ///
  /// In fr, this message translates to:
  /// **'Choisir les sites'**
  String get accountMenuChooseSites;

  /// No description provided for @accountMenuDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce compte'**
  String get accountMenuDelete;

  /// No description provided for @accountMenuDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Source supprimée'**
  String get accountMenuDeleted;

  /// No description provided for @accountMenuSelectionSaved.
  ///
  /// In fr, this message translates to:
  /// **'Sélection enregistrée'**
  String get accountMenuSelectionSaved;

  /// Résumé de la sélection de sites d'un compte, en minuscules après « Umami · »
  ///
  /// In fr, this message translates to:
  /// **'tous les sites'**
  String get accountSelectionAll;

  /// Résumé de la sélection de sites d'un compte
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{tous sauf 1 site} other{tous sauf {count} sites}}'**
  String accountSelectionAllExcept(int count);

  /// Résumé de la sélection de sites d'un compte
  ///
  /// In fr, this message translates to:
  /// **'aucun site'**
  String get accountSelectionNone;

  /// No description provided for @syncSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos comptes et groupes, synchronisés et chiffrés.'**
  String get syncSubtitle;

  /// No description provided for @syncEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get syncEmail;

  /// No description provided for @syncEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'vous@exemple.fr'**
  String get syncEmailHint;

  /// No description provided for @syncPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get syncPassword;

  /// No description provided for @syncPasswordHint.
  ///
  /// In fr, this message translates to:
  /// **'{count} caractères minimum'**
  String syncPasswordHint(int count);

  /// No description provided for @syncCreateAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get syncCreateAccount;

  /// No description provided for @syncCreateAccountButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer le compte'**
  String get syncCreateAccountButton;

  /// No description provided for @syncSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get syncSignIn;

  /// No description provided for @syncHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai déjà un compte'**
  String get syncHaveAccount;

  /// No description provided for @syncEncryptedNote.
  ///
  /// In fr, this message translates to:
  /// **'Votre config est chiffrée sur l\'appareil avant l\'envoi : le serveur ne peut pas la lire. Mot de passe oublié = sync irrécupérable.'**
  String get syncEncryptedNote;

  /// No description provided for @syncToastCreated.
  ///
  /// In fr, this message translates to:
  /// **'Compte créé'**
  String get syncToastCreated;

  /// No description provided for @syncToastSignedIn.
  ///
  /// In fr, this message translates to:
  /// **'Connecté'**
  String get syncToastSignedIn;

  /// No description provided for @syncToastSignedOut.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecté'**
  String get syncToastSignedOut;

  /// No description provided for @syncToastSynced.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisé'**
  String get syncToastSynced;

  /// No description provided for @syncToastDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Compte supprimé'**
  String get syncToastDeleted;

  /// No description provided for @syncToastUnlocked.
  ///
  /// In fr, this message translates to:
  /// **'Glance Sync débloqué'**
  String get syncToastUnlocked;

  /// No description provided for @syncToastRestored.
  ///
  /// In fr, this message translates to:
  /// **'Achat restauré'**
  String get syncToastRestored;

  /// No description provided for @syncNever.
  ///
  /// In fr, this message translates to:
  /// **'Jamais synchronisé'**
  String get syncNever;

  /// Date et heure de la dernière synchronisation, déjà formatées
  ///
  /// In fr, this message translates to:
  /// **'Sync {date}'**
  String syncLastSync(String date);

  /// No description provided for @syncNow.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser maintenant'**
  String get syncNow;

  /// No description provided for @syncSignOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get syncSignOut;

  /// No description provided for @syncDeleteAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get syncDeleteAccount;

  /// No description provided for @syncDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte ?'**
  String get syncDeleteTitle;

  /// No description provided for @syncDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte Glance Sync et toute la configuration synchronisée seront définitivement supprimés du serveur. Action irréversible. Vos sources analytics restent sur cet appareil.'**
  String get syncDeleteBody;

  /// No description provided for @syncUnlockTitle.
  ///
  /// In fr, this message translates to:
  /// **'Débloquez Glance Sync'**
  String get syncUnlockTitle;

  /// No description provided for @syncUnlockBuy.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegardez et synchronisez vos comptes et groupes sur tous vos appareils. Achat unique.'**
  String get syncUnlockBuy;

  /// No description provided for @syncUnlockElsewhere.
  ///
  /// In fr, this message translates to:
  /// **'Achat unique depuis l\'app mobile (iOS/Android). Une fois débloqué, connectez-vous ici avec le même compte : la sync suit automatiquement.'**
  String get syncUnlockElsewhere;

  /// No description provided for @syncUnlockButton.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer'**
  String get syncUnlockButton;

  /// No description provided for @syncRestore.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer un achat'**
  String get syncRestore;

  /// No description provided for @syncSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get syncSoon;

  /// No description provided for @transferExportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Transférer'**
  String get transferExportTitle;

  /// No description provided for @transferExportSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Scannez ce code depuis l\'autre appareil.'**
  String get transferExportSubtitle;

  /// Compte à rebours déjà formaté (m:ss)
  ///
  /// In fr, this message translates to:
  /// **'Expire dans {time}'**
  String transferExpiresIn(String time);

  /// Petit titre en majuscules au-dessus des 4 chiffres
  ///
  /// In fr, this message translates to:
  /// **'Code à saisir sur l\'autre appareil'**
  String get transferCodeLabel;

  /// No description provided for @transferWarning.
  ///
  /// In fr, this message translates to:
  /// **'Ce code contient vos identifiants. Ne le photographiez pas et ne le partagez pas : le QR seul ne suffit pas, mais avec le code à 4 chiffres il donne accès à vos comptes.'**
  String get transferWarning;

  /// No description provided for @transferExpiredTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code expiré'**
  String get transferExpiredTitle;

  /// No description provided for @transferExpiredBody.
  ///
  /// In fr, this message translates to:
  /// **'Un transfert ne reste valable que quelques minutes.'**
  String get transferExpiredBody;

  /// No description provided for @transferRegenerate.
  ///
  /// In fr, this message translates to:
  /// **'Régénérer'**
  String get transferRegenerate;

  /// No description provided for @transferTooLargeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Config trop grosse'**
  String get transferTooLargeTitle;

  /// No description provided for @transferTooLargeBody.
  ///
  /// In fr, this message translates to:
  /// **'Elle ne tient pas dans un QR code ({size} caractères pour {max} au maximum). Suivez « tous les sites » sur vos comptes plutôt qu\'une sélection, puis réessayez.'**
  String transferTooLargeBody(int size, int max);

  /// No description provided for @transferFailedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Transfert impossible'**
  String get transferFailedTitle;

  /// No description provided for @transferFailedBody.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de préparer le transfert.'**
  String get transferFailedBody;

  /// Titre de l'écran d'import par QR
  ///
  /// In fr, this message translates to:
  /// **'Importer'**
  String get transferImportTitle;

  /// No description provided for @transferImportScanHint.
  ///
  /// In fr, this message translates to:
  /// **'Visez le QR affiché sur l\'autre appareil.'**
  String get transferImportScanHint;

  /// No description provided for @transferImportCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code affiché à côté du QR.'**
  String get transferImportCodeHint;

  /// No description provided for @transferScanned.
  ///
  /// In fr, this message translates to:
  /// **'Code scanné'**
  String get transferScanned;

  /// No description provided for @transferCodeField.
  ///
  /// In fr, this message translates to:
  /// **'Code à 4 chiffres'**
  String get transferCodeField;

  /// Bouton de validation de l'import
  ///
  /// In fr, this message translates to:
  /// **'Importer'**
  String get transferImportButton;

  /// No description provided for @transferRescan.
  ///
  /// In fr, this message translates to:
  /// **'Scanner à nouveau'**
  String get transferRescan;

  /// Toast après l'import d'une config
  ///
  /// In fr, this message translates to:
  /// **'{accounts, plural, =1{1 compte} other{{accounts} comptes}} et {groups, plural, =0{0 groupe} =1{1 groupe} other{{groups} groupes}} importés'**
  String transferImported(int accounts, int groups);

  /// No description provided for @transferErrExpired.
  ///
  /// In fr, this message translates to:
  /// **'Ce code a expiré. Régénérez-le sur l\'autre appareil.'**
  String get transferErrExpired;

  /// No description provided for @transferErrBadCode.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect.'**
  String get transferErrBadCode;

  /// No description provided for @transferErrFailed.
  ///
  /// In fr, this message translates to:
  /// **'Import impossible.'**
  String get transferErrFailed;

  /// No description provided for @transferCameraDenied.
  ///
  /// In fr, this message translates to:
  /// **'Caméra refusée'**
  String get transferCameraDenied;

  /// No description provided for @transferCameraUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Caméra indisponible'**
  String get transferCameraUnavailable;

  /// No description provided for @transferCameraDeniedBody.
  ///
  /// In fr, this message translates to:
  /// **'Autorisez l\'accès à la caméra dans les réglages du système pour scanner un transfert.'**
  String get transferCameraDeniedBody;

  /// No description provided for @transferCameraUnavailableBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucune caméra utilisable sur cet appareil.'**
  String get transferCameraUnavailableBody;

  /// No description provided for @groupsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Un périmètre de lecture : totaux et courbe ne comptent que ses sites.'**
  String get groupsSubtitle;

  /// No description provided for @groupsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun groupe'**
  String get groupsEmptyTitle;

  /// No description provided for @groupsEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Regroupez vos sites — par exemple « Jeux » ou « Clients » — pour lire leurs statistiques à part, sans le reste.'**
  String get groupsEmptyBody;

  /// No description provided for @groupsCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer un groupe'**
  String get groupsCreate;

  /// No description provided for @groupEditEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le groupe'**
  String get groupEditEditTitle;

  /// No description provided for @groupEditName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get groupEditName;

  /// No description provided for @groupEditNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Jeux, Clients, Perso…'**
  String get groupEditNameHint;

  /// No description provided for @groupEditSitesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sites du groupe'**
  String get groupEditSitesLabel;

  /// Petit texte à droite de « Ajouter une source » dans l'éditeur de groupe
  ///
  /// In fr, this message translates to:
  /// **'ses sites entrent ici'**
  String get groupEditAddSourceHint;

  /// No description provided for @groupEditNoSites.
  ///
  /// In fr, this message translates to:
  /// **'Aucun site suivi pour l\'instant — ajoutez une source ci-dessus pour remplir ce groupe.'**
  String get groupEditNoSites;

  /// No description provided for @groupEditCreateButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer le groupe'**
  String get groupEditCreateButton;

  /// No description provided for @groupEditCreated.
  ///
  /// In fr, this message translates to:
  /// **'Groupe créé'**
  String get groupEditCreated;

  /// No description provided for @groupEditSaved.
  ///
  /// In fr, this message translates to:
  /// **'Groupe enregistré'**
  String get groupEditSaved;

  /// No description provided for @groupEditDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Groupe supprimé'**
  String get groupEditDeleted;

  /// No description provided for @groupEditDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce groupe ?'**
  String get groupEditDeleteTitle;

  /// No description provided for @groupEditDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Les sites et leurs statistiques ne sont pas touchés — seul le regroupement disparaît.'**
  String get groupEditDeleteBody;

  /// No description provided for @addSourceNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle source'**
  String get addSourceNewTitle;

  /// Petit titre en majuscules au-dessus du choix Umami / Plausible / Fathom
  ///
  /// In fr, this message translates to:
  /// **'FOURNISSEUR'**
  String get addSourceProvider;

  /// No description provided for @addSourceName.
  ///
  /// In fr, this message translates to:
  /// **'Nom (optionnel)'**
  String get addSourceName;

  /// No description provided for @addSourceNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Mon domaine'**
  String get addSourceNameHint;

  /// No description provided for @addSourceTest.
  ///
  /// In fr, this message translates to:
  /// **'Tester la configuration'**
  String get addSourceTest;

  /// No description provided for @addSourceContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get addSourceContinue;

  /// No description provided for @addSourceMissingFields.
  ///
  /// In fr, this message translates to:
  /// **'Renseigne les champs obligatoires.'**
  String get addSourceMissingFields;

  /// No description provided for @addSourceTestOk.
  ///
  /// In fr, this message translates to:
  /// **'Connexion réussie.'**
  String get addSourceTestOk;

  /// No description provided for @addSourceTestOkSites.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Connexion réussie · 1 site détecté} other{Connexion réussie · {count} sites détectés}}'**
  String addSourceTestOkSites(int count);

  /// No description provided for @addSourceNoSitesPlausible.
  ///
  /// In fr, this message translates to:
  /// **'Aucun site listé automatiquement : votre instance n\'expose pas l\'API de listing (Plausible Community Edition). Renseignez le domaine à suivre ci-dessus.'**
  String get addSourceNoSitesPlausible;

  /// No description provided for @addSourceNoSites.
  ///
  /// In fr, this message translates to:
  /// **'Aucun site trouvé pour ce compte.'**
  String get addSourceNoSites;

  /// No description provided for @addSourceKeyRejected.
  ///
  /// In fr, this message translates to:
  /// **'Clé API refusée (accès aux stats). Vérifiez la clé API.'**
  String get addSourceKeyRejected;

  /// No description provided for @addSourceCredsRejected.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants refusés.'**
  String get addSourceCredsRejected;

  /// No description provided for @addSourceAdded.
  ///
  /// In fr, this message translates to:
  /// **'Source ajoutée'**
  String get addSourceAdded;

  /// No description provided for @addSourceEdited.
  ///
  /// In fr, this message translates to:
  /// **'Source modifiée'**
  String get addSourceEdited;

  /// No description provided for @sitePickerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choix des sites'**
  String get sitePickerTitle;

  /// No description provided for @sitePickerDetected.
  ///
  /// In fr, this message translates to:
  /// **'{provider} · {count, plural, =1{1 site détecté} other{{count} sites détectés}}'**
  String sitePickerDetected(String provider, int count);

  /// No description provided for @sitePickerFollowNew.
  ///
  /// In fr, this message translates to:
  /// **'Afficher les nouveaux sites'**
  String get sitePickerFollowNew;

  /// No description provided for @sitePickerFollowNewHint.
  ///
  /// In fr, this message translates to:
  /// **'Un site créé plus tard apparaît tout seul'**
  String get sitePickerFollowNewHint;

  /// No description provided for @sitePickerCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Sites actuels'**
  String get sitePickerCurrent;

  /// Recherche de sites : nombre de sites affichés sur le total
  ///
  /// In fr, this message translates to:
  /// **'{shown} sur {total}'**
  String sitePickerShownOf(int shown, int total);

  /// No description provided for @sitePickerCheckAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout cocher'**
  String get sitePickerCheckAll;

  /// No description provided for @sitePickerUncheckAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout décocher'**
  String get sitePickerUncheckAll;

  /// No description provided for @sitePickerFollowAll.
  ///
  /// In fr, this message translates to:
  /// **'Suivre tous les sites'**
  String get sitePickerFollowAll;

  /// No description provided for @sitePickerFollowAndNew.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Suivre 0 site et les nouveaux} =1{Suivre 1 site et les nouveaux} other{Suivre {count} sites et les nouveaux}}'**
  String sitePickerFollowAndNew(int count);

  /// No description provided for @sitePickerFollow.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Suivre 0 site} =1{Suivre 1 site} other{Suivre {count} sites}}'**
  String sitePickerFollow(int count);

  /// No description provided for @sitePickerShowNone.
  ///
  /// In fr, this message translates to:
  /// **'N\'afficher aucun site'**
  String get sitePickerShowNone;

  /// No description provided for @commonVisitors.
  ///
  /// In fr, this message translates to:
  /// **'Visiteurs'**
  String get commonVisitors;

  /// No description provided for @commonPageviews.
  ///
  /// In fr, this message translates to:
  /// **'Pages vues'**
  String get commonPageviews;

  /// No description provided for @commonNoData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée'**
  String get commonNoData;

  /// En-tête de la liste de sites de la barre latérale ; count = nombre de sites
  ///
  /// In fr, this message translates to:
  /// **'Sites ({count})'**
  String desktopSitesHeader(int count);

  /// À côté de l'en-tête de la liste : sites masqués car sans visiteur
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{{count} masqué} other{{count} masqués}}'**
  String desktopHiddenCount(int count);

  /// Infobulle de l'interrupteur « ≠ 0 » quand les sites sans visiteur sont masqués
  ///
  /// In fr, this message translates to:
  /// **'Afficher tous les sites'**
  String get desktopShowAllSites;

  /// Infobulle de l'interrupteur « ≠ 0 »
  ///
  /// In fr, this message translates to:
  /// **'Masquer les sites sans visiteur'**
  String get desktopHideEmptySites;

  /// No description provided for @desktopLiveNobody.
  ///
  /// In fr, this message translates to:
  /// **'Personne en ce moment.'**
  String get desktopLiveNobody;

  /// Carte KPI de la vue d'ensemble : nombre de sites
  ///
  /// In fr, this message translates to:
  /// **'Sites'**
  String get desktopKpiSites;

  /// No description provided for @desktopNoSitesGroupBody.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » ne contient aucun site. Choisissez ceux qui en font partie.'**
  String desktopNoSitesGroupBody(String name);

  /// No description provided for @desktopNoSitesBody.
  ///
  /// In fr, this message translates to:
  /// **'Vos comptes ne suivent aucun site pour le moment. Choisissez les sites à afficher depuis les réglages.'**
  String get desktopNoSitesBody;

  /// No description provided for @chartLegendForecast.
  ///
  /// In fr, this message translates to:
  /// **'Prévision'**
  String get chartLegendForecast;

  /// No description provided for @chartLegendPrevious.
  ///
  /// In fr, this message translates to:
  /// **'Période précédente'**
  String get chartLegendPrevious;

  /// No description provided for @chartTooltipVisitors.
  ///
  /// In fr, this message translates to:
  /// **'visiteurs'**
  String get chartTooltipVisitors;

  /// No description provided for @chartTooltipPageviews.
  ///
  /// In fr, this message translates to:
  /// **'pages vues'**
  String get chartTooltipPageviews;

  /// No description provided for @chartTooltipForecast.
  ///
  /// In fr, this message translates to:
  /// **'prévision'**
  String get chartTooltipForecast;

  /// No description provided for @chartTooltipPrevious.
  ///
  /// In fr, this message translates to:
  /// **'période précédente'**
  String get chartTooltipPrevious;

  /// No description provided for @chartNoSeries.
  ///
  /// In fr, this message translates to:
  /// **'Aucune série sélectionnée'**
  String get chartNoSeries;

  /// Heure d'un point de série, sur l'axe ou dans l'infobulle ; hour = « 14 » (deux chiffres, 24 h)
  ///
  /// In fr, this message translates to:
  /// **'{hour}h'**
  String chartHour(String hour);

  /// Bouton qui ouvre le menu de réglages du graphique (découpage et style)
  ///
  /// In fr, this message translates to:
  /// **'Affichage'**
  String get periodControlsDisplay;

  /// Titre de section du menu Affichage : granularité heure / jour / mois
  ///
  /// In fr, this message translates to:
  /// **'Découpage'**
  String get periodControlsSplit;

  /// Titre de section du menu Affichage : courbe ou barres
  ///
  /// In fr, this message translates to:
  /// **'Graphique'**
  String get periodControlsChart;

  /// Granularité du graphique, libellé de puce très court
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get periodUnitHour;

  /// Granularité du graphique, libellé de puce très court
  ///
  /// In fr, this message translates to:
  /// **'Jour'**
  String get periodUnitDay;

  /// Granularité du graphique, libellé de puce très court
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get periodUnitMonth;

  /// No description provided for @errorsAuthRefused.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants refusés.'**
  String get errorsAuthRefused;

  /// No description provided for @errorsRequestRefused.
  ///
  /// In fr, this message translates to:
  /// **'Requête refusée par le serveur.'**
  String get errorsRequestRefused;

  /// No description provided for @errorsNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Instance ou API introuvable.'**
  String get errorsNotFound;

  /// No description provided for @errorsTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Délai dépassé — instance lente ou injoignable.'**
  String get errorsTimeout;

  /// No description provided for @errorsUnreachable.
  ///
  /// In fr, this message translates to:
  /// **'Instance injoignable. Vérifie l\'URL.'**
  String get errorsUnreachable;

  /// No description provided for @errorsServerCode.
  ///
  /// In fr, this message translates to:
  /// **'Erreur {code} du serveur.'**
  String errorsServerCode(int code);

  /// No description provided for @errorsConnectionFailed.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible.'**
  String get errorsConnectionFailed;

  /// No description provided for @errorsGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {detail}'**
  String errorsGeneric(String detail);

  /// No description provided for @errUnsupportedIndicators.
  ///
  /// In fr, this message translates to:
  /// **'Indicateurs non pris en charge'**
  String get errUnsupportedIndicators;

  /// No description provided for @errUnsupportedSiteTables.
  ///
  /// In fr, this message translates to:
  /// **'Tableaux de sites non pris en charge'**
  String get errUnsupportedSiteTables;

  /// No description provided for @errUnsupportedFunnels.
  ///
  /// In fr, this message translates to:
  /// **'Entonnoirs non pris en charge'**
  String get errUnsupportedFunnels;

  /// No description provided for @errUnsupportedBreakdowns.
  ///
  /// In fr, this message translates to:
  /// **'Répartitions non prises en charge'**
  String get errUnsupportedBreakdowns;

  /// No description provided for @errOperatorUmamiFunnel.
  ///
  /// In fr, this message translates to:
  /// **'Opérateur « {op} » indisponible dans un entonnoir Umami'**
  String errOperatorUmamiFunnel(String op);

  /// No description provided for @errOperatorPlausible.
  ///
  /// In fr, this message translates to:
  /// **'Opérateur « {op} » indisponible chez Plausible (propriétés en texte seulement)'**
  String errOperatorPlausible(String op);

  /// No description provided for @errFathomSoon.
  ///
  /// In fr, this message translates to:
  /// **'Fathom arrive bientôt.'**
  String get errFathomSoon;

  /// No description provided for @errPlausibleNeedsSite.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez un domaine, ou email + mot de passe pour lister vos sites automatiquement.'**
  String get errPlausibleNeedsSite;

  /// No description provided for @errUmamiLoginUnexpected.
  ///
  /// In fr, this message translates to:
  /// **'Réponse de login Umami inattendue'**
  String get errUmamiLoginUnexpected;

  /// No description provided for @errBucketsTooFine.
  ///
  /// In fr, this message translates to:
  /// **'Découpage trop fin : plus de {count} points sur la période.'**
  String errBucketsTooFine(int count);

  /// No description provided for @errMetricsNotConfigured.
  ///
  /// In fr, this message translates to:
  /// **'Source non configurée sur le serveur'**
  String get errMetricsNotConfigured;

  /// No description provided for @errMetricsBadToken.
  ///
  /// In fr, this message translates to:
  /// **'Jeton refusé'**
  String get errMetricsBadToken;

  /// No description provided for @errMetricsBadRequest.
  ///
  /// In fr, this message translates to:
  /// **'Requête refusée ({code})'**
  String errMetricsBadRequest(String code);

  /// No description provided for @errMetricsUnsupportedVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version d\'API non prise en charge'**
  String get errMetricsUnsupportedVersion;

  /// No description provided for @errMetricsUnexpected.
  ///
  /// In fr, this message translates to:
  /// **'Réponse inattendue du serveur'**
  String get errMetricsUnexpected;

  /// No description provided for @syncMsgUnreachable.
  ///
  /// In fr, this message translates to:
  /// **'Serveur injoignable. Réessayez.'**
  String get syncMsgUnreachable;

  /// No description provided for @syncMsgSessionExpired.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée. Reconnectez-vous puis réessayez.'**
  String get syncMsgSessionExpired;

  /// No description provided for @syncMsgPurchaseFailed.
  ///
  /// In fr, this message translates to:
  /// **'Achat impossible. Réessayez.'**
  String get syncMsgPurchaseFailed;

  /// No description provided for @syncMsgPurchasePending.
  ///
  /// In fr, this message translates to:
  /// **'Achat validé — activation en cours, réessayez la sync dans un instant.'**
  String get syncMsgPurchasePending;

  /// No description provided for @syncMsgNothingToRestore.
  ///
  /// In fr, this message translates to:
  /// **'Aucun achat à restaurer.'**
  String get syncMsgNothingToRestore;

  /// No description provided for @syncMsgRestorePending.
  ///
  /// In fr, this message translates to:
  /// **'Achat restauré — activation en cours…'**
  String get syncMsgRestorePending;

  /// No description provided for @syncMsgCannotDecrypt.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de déchiffrer la config distante.'**
  String get syncMsgCannotDecrypt;

  /// No description provided for @syncMsgProRequired.
  ///
  /// In fr, this message translates to:
  /// **'Sync réservée à Glance Sync (Pro).'**
  String get syncMsgProRequired;

  /// No description provided for @syncMsgBadCredentials.
  ///
  /// In fr, this message translates to:
  /// **'E-mail ou mot de passe incorrect.'**
  String get syncMsgBadCredentials;

  /// No description provided for @syncMsgPasswordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe trop court : {count} caractères minimum.'**
  String syncMsgPasswordTooShort(int count);

  /// No description provided for @syncMsgPasswordTooLong.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe trop long.'**
  String get syncMsgPasswordTooLong;

  /// No description provided for @syncMsgInvalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide.'**
  String get syncMsgInvalidEmail;

  /// No description provided for @syncMsgAccountExists.
  ///
  /// In fr, this message translates to:
  /// **'Cet e-mail a déjà un compte : connectez-vous.'**
  String get syncMsgAccountExists;

  /// No description provided for @syncMsgSignUpFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer le compte.'**
  String get syncMsgSignUpFailed;

  /// Libellé court d'une période, dans la barre de contrôles
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get periodToday;

  /// Libellé court d'une période, dans la barre de contrôles
  ///
  /// In fr, this message translates to:
  /// **'24 h'**
  String get period24h;

  /// Libellé court d'une période, dans la barre de contrôles
  ///
  /// In fr, this message translates to:
  /// **'7 jours'**
  String get period7d;

  /// Libellé court d'une période, dans la barre de contrôles
  ///
  /// In fr, this message translates to:
  /// **'30 j'**
  String get period30d;

  /// Libellé court d'une période, dans la barre de contrôles
  ///
  /// In fr, this message translates to:
  /// **'Ce mois-ci'**
  String get periodThisMonth;

  /// Libellé court d'une période, dans la barre de contrôles
  ///
  /// In fr, this message translates to:
  /// **'12 m'**
  String get period12m;

  /// Libellé court d'une période, dans la barre de contrôles
  ///
  /// In fr, this message translates to:
  /// **'Cette année'**
  String get periodThisYear;

  /// Libellé court d'une période, dans la barre de contrôles : depuis la première donnée
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get periodAllTime;

  /// Libellé court d'une période, dans la barre de contrôles : dates choisies à la main
  ///
  /// In fr, this message translates to:
  /// **'Perso'**
  String get periodCustom;

  /// Dimension de données d'un site, dans le sélecteur d'une section du détail : chemins des pages
  ///
  /// In fr, this message translates to:
  /// **'Chemins'**
  String get metricTypePages;

  /// Dimension de données d'un site, dans le sélecteur d'une section du détail : pages d'entrée
  ///
  /// In fr, this message translates to:
  /// **'Entrée'**
  String get metricTypeEntry;

  /// Dimension de données d'un site, dans le sélecteur d'une section du détail : pages de sortie
  ///
  /// In fr, this message translates to:
  /// **'Sortie'**
  String get metricTypeExit;

  /// Dimension de données d'un site, dans le sélecteur d'une section du détail : titres des pages
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get metricTypeTitle;

  /// Dimension de données d'un site, dans le sélecteur d'une section du détail
  ///
  /// In fr, this message translates to:
  /// **'Référents'**
  String get metricTypeReferrers;

  /// Dimension de données d'un site, dans le sélecteur d'une section du détail : canaux d'acquisition
  ///
  /// In fr, this message translates to:
  /// **'Canaux'**
  String get metricTypeChannels;

  /// Dimension de données d'un site, dans le sélecteur d'une section du détail : requêtes de recherche
  ///
  /// In fr, this message translates to:
  /// **'Requêtes'**
  String get metricTypeQueries;

  /// Dimension de données d'un site, dans le sélecteur d'une section du détail
  ///
  /// In fr, this message translates to:
  /// **'Navigateurs'**
  String get metricTypeBrowsers;

  /// Dimension de données d'un site, dans le sélecteur d'une section du détail : systèmes d'exploitation
  ///
  /// In fr, this message translates to:
  /// **'OS'**
  String get metricTypeOs;

  /// Dimension de données d'un site, dans le sélecteur d'une section du détail
  ///
  /// In fr, this message translates to:
  /// **'Appareils'**
  String get metricTypeDevices;

  /// Dimension de données d'un site, dans le sélecteur d'une section du détail : résolutions d'écran
  ///
  /// In fr, this message translates to:
  /// **'Écrans'**
  String get metricTypeScreens;

  /// Dimension de données d'un site, dans le sélecteur d'une section du détail
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get metricTypeCountries;

  /// Dimension de données d'un site, dans le sélecteur d'une section du détail
  ///
  /// In fr, this message translates to:
  /// **'Régions'**
  String get metricTypeRegions;

  /// Dimension de données d'un site, dans le sélecteur d'une section du détail
  ///
  /// In fr, this message translates to:
  /// **'Villes'**
  String get metricTypeCities;

  /// Dimension de données d'un site, dans le sélecteur d'une section du détail
  ///
  /// In fr, this message translates to:
  /// **'Langues'**
  String get metricTypeLanguages;

  /// Dimension de données d'un site, dans le sélecteur d'une section du détail
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get metricTypeEvents;

  /// Titre d'un des quatre panneaux de données du détail d'un site
  ///
  /// In fr, this message translates to:
  /// **'Pages'**
  String get metricSectionPages;

  /// Titre d'un des quatre panneaux de données du détail d'un site : d'où viennent les visiteurs
  ///
  /// In fr, this message translates to:
  /// **'Sources'**
  String get metricSectionSources;

  /// Titre d'un des quatre panneaux de données du détail d'un site : navigateur, système, appareil
  ///
  /// In fr, this message translates to:
  /// **'Environnement'**
  String get metricSectionEnvironment;

  /// Titre d'un des quatre panneaux de données du détail d'un site : pays, régions, villes, langues
  ///
  /// In fr, this message translates to:
  /// **'Emplacement'**
  String get metricSectionLocation;

  /// Opérateur de filtre, lu dans « propriété contient valeur »
  ///
  /// In fr, this message translates to:
  /// **'contient'**
  String get filterOpContains;

  /// Opérateur de filtre, lu dans « propriété ne contient pas valeur »
  ///
  /// In fr, this message translates to:
  /// **'ne contient pas'**
  String get filterOpNotContains;

  /// Valeur absente (navigateur, appareil, langue…)
  ///
  /// In fr, this message translates to:
  /// **'Inconnu'**
  String get entityUnknown;

  /// Source d'une visite sans référent
  ///
  /// In fr, this message translates to:
  /// **'Accès direct'**
  String get entityReferrerDirect;

  /// Navigateur : robot des moteurs de recherche
  ///
  /// In fr, this message translates to:
  /// **'Robot d\'indexation'**
  String get entityBrowserSearchBot;

  /// Type d'appareil
  ///
  /// In fr, this message translates to:
  /// **'Ordinateur'**
  String get entityDeviceDesktop;

  /// Type d'appareil
  ///
  /// In fr, this message translates to:
  /// **'Portable'**
  String get entityDeviceLaptop;

  /// Type d'appareil
  ///
  /// In fr, this message translates to:
  /// **'Tablette'**
  String get entityDeviceTablet;

  /// Type d'appareil
  ///
  /// In fr, this message translates to:
  /// **'Mobile'**
  String get entityDeviceMobile;

  /// Type d'appareil
  ///
  /// In fr, this message translates to:
  /// **'Montre'**
  String get entityDeviceWearable;

  /// Type d'appareil
  ///
  /// In fr, this message translates to:
  /// **'Console'**
  String get entityDeviceConsole;

  /// Type d'appareil
  ///
  /// In fr, this message translates to:
  /// **'Téléviseur'**
  String get entityDeviceTv;

  /// Canal d'acquisition de trafic : visite sans référent
  ///
  /// In fr, this message translates to:
  /// **'Direct'**
  String get channelDirect;

  /// Canal d'acquisition de trafic : lien depuis un autre site
  ///
  /// In fr, this message translates to:
  /// **'Référent'**
  String get channelReferral;

  /// Canal d'acquisition de trafic
  ///
  /// In fr, this message translates to:
  /// **'Affiliation'**
  String get channelAffiliate;

  /// Canal d'acquisition de trafic
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get channelEmail;

  /// Canal d'acquisition de trafic
  ///
  /// In fr, this message translates to:
  /// **'Recherche organique'**
  String get channelOrganicSearch;

  /// Canal d'acquisition de trafic
  ///
  /// In fr, this message translates to:
  /// **'Réseaux sociaux'**
  String get channelOrganicSocial;

  /// Canal d'acquisition de trafic
  ///
  /// In fr, this message translates to:
  /// **'Achat organique'**
  String get channelOrganicShopping;

  /// Canal d'acquisition de trafic
  ///
  /// In fr, this message translates to:
  /// **'Vidéo organique'**
  String get channelOrganicVideo;

  /// Canal d'acquisition de trafic
  ///
  /// In fr, this message translates to:
  /// **'Publicité payante'**
  String get channelPaidAds;

  /// Canal d'acquisition de trafic
  ///
  /// In fr, this message translates to:
  /// **'Recherche payante'**
  String get channelPaidSearch;

  /// Canal d'acquisition de trafic
  ///
  /// In fr, this message translates to:
  /// **'Réseaux sociaux payants'**
  String get channelPaidSocial;

  /// Canal d'acquisition de trafic
  ///
  /// In fr, this message translates to:
  /// **'Achat payant'**
  String get channelPaidShopping;

  /// Canal d'acquisition de trafic
  ///
  /// In fr, this message translates to:
  /// **'Vidéo payante'**
  String get channelPaidVideo;

  /// No description provided for @credInstanceUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL de l\'instance'**
  String get credInstanceUrl;

  /// Exemple d'adresse d'instance Umami
  ///
  /// In fr, this message translates to:
  /// **'analytics.mondomaine.fr'**
  String get credUmamiUrlPlaceholder;

  /// No description provided for @credUsername.
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'utilisateur'**
  String get credUsername;

  /// No description provided for @credPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get credPassword;

  /// No description provided for @credApiKey.
  ///
  /// In fr, this message translates to:
  /// **'Clé API'**
  String get credApiKey;

  /// No description provided for @credEmailOptional.
  ///
  /// In fr, this message translates to:
  /// **'Email du compte (facultatif)'**
  String get credEmailOptional;

  /// Exemple d'adresse e-mail
  ///
  /// In fr, this message translates to:
  /// **'vous@exemple.fr'**
  String get credEmailPlaceholder;

  /// No description provided for @credEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'Email + mot de passe : Glance liste vos sites automatiquement. Sinon, laissez vide et renseignez un domaine ci-dessous.'**
  String get credEmailHint;

  /// No description provided for @credPasswordOptional.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe (facultatif)'**
  String get credPasswordOptional;

  /// No description provided for @credDomainFallback.
  ///
  /// In fr, this message translates to:
  /// **'Domaine (si pas d\'email/mot de passe)'**
  String get credDomainFallback;

  /// Exemple de nom de domaine
  ///
  /// In fr, this message translates to:
  /// **'mondomaine.fr'**
  String get credDomainPlaceholder;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'pt',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
