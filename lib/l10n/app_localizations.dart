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
