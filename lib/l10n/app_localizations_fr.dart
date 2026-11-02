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

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonClear => 'Effacer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get tabSites => 'Sites';

  @override
  String get tabDirect => 'Direct';

  @override
  String get tabSettings => 'Réglages';

  @override
  String get siteSearchHint => 'Rechercher un site';

  @override
  String siteSearchNoMatch(String query) {
    return 'Aucun site ne correspond à « $query ».';
  }

  @override
  String get navToday => 'Aujourd\'hui';

  @override
  String get navYesterday => 'Hier';

  @override
  String get navDayBeforeYesterday => 'Avant-hier';

  @override
  String get navThisMonth => 'Ce mois-ci';

  @override
  String get navLastMonth => 'Mois dernier';

  @override
  String get navThisYear => 'Cette année';

  @override
  String get navLastYear => 'Année dernière';

  @override
  String get workspaceSheetTitle => 'Périmètre';

  @override
  String get workspaceAllSites => 'Tous les sites';

  @override
  String workspaceTrackedSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites suivis',
      one: '1 site suivi',
      zero: '0 site suivi',
    );
    return '$_temp0';
  }

  @override
  String workspaceSiteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites',
      one: '1 site',
      zero: 'Aucun site',
    );
    return '$_temp0';
  }

  @override
  String get workspaceNewGroup => 'Nouveau groupe';

  @override
  String get workspaceManageGroups => 'Gérer les groupes';

  @override
  String get homeTitleDefault => 'Mes sites';

  @override
  String get homeLoadFailed => 'Chargement impossible.';

  @override
  String get homeInternalTitle => 'Entre vos sites';

  @override
  String homeTotalVisitors(String name) {
    return 'Visiteurs · $name';
  }

  @override
  String get homeTotalVisitorsAll => 'Visiteurs · tous les sites';

  @override
  String get homeVsPrevious => 'vs période préc.';

  @override
  String homeLiveCount(int count) {
    return '$count live';
  }

  @override
  String get homeEmptyTitle => 'Aucun site affiché';

  @override
  String get homeEmptyBody =>
      'Aucun site suivi pour le moment. Choisis ceux à afficher.';

  @override
  String get homeEmptyChooseSites => 'Choisir les sites';

  @override
  String get homeEmptyAddSource => '+ Ajouter une source';

  @override
  String get homeEmptyGroupTitle => 'Groupe vide';

  @override
  String homeEmptyGroupBody(String name) {
    return '« $name » ne contient aucun site.';
  }

  @override
  String get homeEmptyGroupChoose => 'Choisir ses sites';

  @override
  String get homeEmptyGroupSeeAll => 'Voir tous les sites';

  @override
  String get homeWelcomeTagline => 'Vos statistiques, en un clin d\'œil.';

  @override
  String get homeWelcomeTitle => 'Connectez votre premier outil';

  @override
  String get homeWelcomeBody =>
      'Umami, Plausible… ajoutez une source puis choisissez les sites à suivre.';

  @override
  String get homeWelcomeAddSource => 'Ajouter une source';

  @override
  String get homeWelcomeFootnote =>
      'Clé en lecture seule · vos données restent chez vous';

  @override
  String get homeSiteUnavailable => 'Indisponible';

  @override
  String get detailVisitorsUnique => 'Visiteurs uniques';

  @override
  String get detailKpiVisits => 'Visites';

  @override
  String get detailKpiAvgDuration => 'Durée moy.';

  @override
  String get detailKpiBounce => 'Rebond';

  @override
  String get detailLiveNow => 'En direct maintenant';

  @override
  String get detailLiveNobody => 'Personne pour l\'instant.';

  @override
  String get detailTabOverview => 'Vue d\'ensemble';

  @override
  String get detailTabEvents => 'Événements';

  @override
  String get detailTabDashboards => 'Tableaux';

  @override
  String get detailEventsEmpty => 'Aucun événement sur cette période';

  @override
  String get detailEventsTriggered => 'Événements déclenchés';

  @override
  String get detailEventsByEvent => 'Par événement';

  @override
  String detailSectionViewAll(int count) {
    return 'Voir les $count lignes';
  }

  @override
  String get detailBadgeInternal => 'INTERNE';

  @override
  String get directEyebrow => 'Temps réel';

  @override
  String get directTitle => 'En direct';

  @override
  String get directNow => 'en ce moment';

  @override
  String get directVisitorsAll => 'visiteurs sur l\'ensemble de vos sites';

  @override
  String directVisitorsGroup(String name) {
    return 'visiteurs sur le groupe « $name »';
  }

  @override
  String get directBySite => 'Par site';

  @override
  String get directOnlyActive => 'Actifs seulement';

  @override
  String get directNoneLive => 'Aucun visiteur en direct pour l\'instant.';

  @override
  String get directNoSites => 'Aucun site.';

  @override
  String directHiddenSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites sans visiteur masqués',
      one: '1 site sans visiteur masqué',
    );
    return '$_temp0';
  }

  @override
  String networkExchanged(String period) {
    return 'Visiteurs échangés · $period';
  }

  @override
  String networkPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites en cours…',
      one: '1 site en cours…',
    );
    return '$_temp0';
  }

  @override
  String get networkExplainer =>
      'Visiteurs arrivés sur un de vos sites depuis un autre de vos sites.';

  @override
  String get networkEmpty => 'Aucune navigation interne sur cette période.';

  @override
  String get networkSenders => 'Qui envoie';

  @override
  String get networkReceivers => 'Qui reçoit';

  @override
  String get networkFlows => 'Flux';

  @override
  String get commonEdit => 'Modifier';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get dashboardsKindCounter => 'Compteur';

  @override
  String get dashboardsKindRatio => 'Taux';

  @override
  String get dashboardsKindFunnel => 'Entonnoir';

  @override
  String get dashboardsKindBreakdown => 'Répartition';

  @override
  String get dashboardsKindExternal => 'Métrique';

  @override
  String get dashboardsKindSites => 'Sites';

  @override
  String get dashboardsMoveCard => 'Déplacer le tableau';

  @override
  String get dashboardsCardOptions => 'Options du tableau';

  @override
  String get dashboardsResizeCard => 'Redimensionner le tableau';

  @override
  String get dashboardsLoadFailed => 'Chargement impossible.';

  @override
  String get dashboardsNoData => 'Aucune donnée sur la période';

  @override
  String get dashboardsNoEvents => 'Aucun événement sur la période';

  @override
  String dashboardsUnpublished(String date) {
    return 'Pas encore publiées : données jusqu\'au $date';
  }

  @override
  String get dashboardsPendingNow => 'Pas encore mesurable sur cette période';

  @override
  String dashboardsPendingDelay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pas encore mesurable : il faut $count jours de recul',
      one: 'Pas encore mesurable : il faut 1 jour de recul',
    );
    return '$_temp0';
  }

  @override
  String dashboardsCohortOne(String date) {
    return 'Mesurée sur la cohorte du $date';
  }

  @override
  String dashboardsCohortRange(String range) {
    return 'Mesurée sur les cohortes $range';
  }

  @override
  String dashboardsFamilyMember(String member) {
    return '$member · s\'ajuste à la période';
  }

  @override
  String dashboardsDataUntil(String date) {
    return 'Données jusqu\'au $date';
  }

  @override
  String dashboardsFunnelVisitors(String last, String first) {
    return '$last / $first visiteurs';
  }

  @override
  String dashboardsCohortTooltip(String date, String cohort) {
    return '$date · cohorte du $cohort';
  }

  @override
  String get dashboardsTotal => 'Total';

  @override
  String dashboardsSegmentEstimated(String label) {
    return '$label · estimé';
  }

  @override
  String get dashboardsDeleted => 'Tableau supprimé';

  @override
  String get dashboardsConfirmDelete => 'Confirmer la suppression';

  @override
  String get dashboardsAllHidden =>
      'Aucun tableau n\'a de données sur cette période';

  @override
  String dashboardsHiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tableaux sans données sur cette période',
      one: '1 tableau sans données sur cette période',
    );
    return '$_temp0';
  }

  @override
  String get dashboardsShow => 'Afficher';

  @override
  String get dashboardsArrangeHint =>
      'Maintenez une carte pour la déplacer, tirez son coin pour la redimensionner.';

  @override
  String get dashboardsArrange => 'Organiser';

  @override
  String get dashboardsArrangeDone => 'Terminé';

  @override
  String get dashboardsNew => 'Nouveau tableau';

  @override
  String get dashboardsEmptyTitle => 'Aucun tableau';

  @override
  String get dashboardsEmptyBody =>
      'Suivez un taux, un entonnoir ou une répartition construits sur vos événements.';

  @override
  String get dashboardsCreate => 'Créer un tableau';

  @override
  String get dashboardsMetricsSource => 'Source de métriques';

  @override
  String get dashboardsMetricsIntro =>
      'Une petite API de votre site qui fournit des indicateurs calculés sur sa base (rétention, comptes…) : un catalogue et des séries, protégés par un jeton.';

  @override
  String get dashboardsMetricsHowItWorks => 'Comment ça marche ?';

  @override
  String get dashboardsMetricsUrlLabel => 'Adresse de l\'API';

  @override
  String get dashboardsMetricsUrlHint =>
      'https://exemple.fr/api/interne/metriques/';

  @override
  String get dashboardsMetricsToken => 'Jeton';

  @override
  String get dashboardsMetricsTest => 'Tester';

  @override
  String dashboardsMetricsAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count indicateurs disponibles',
      one: '1 indicateur disponible',
    );
    return '$_temp0';
  }

  @override
  String get dashboardsMetricsSaved => 'Source enregistrée';

  @override
  String get dashboardsMetricsRemove => 'Retirer la source';

  @override
  String dashboardsMetricsRemoveWithCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tableaux',
      one: '1 tableau',
    );
    return 'Retirer la source et $_temp0';
  }

  @override
  String get dashboardsMetricsRemoved => 'Source retirée';

  @override
  String dashboardsMetricsRemovedWithCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tableaux supprimés',
      one: '1 tableau supprimé',
    );
    return 'Source retirée, $_temp0';
  }
}
