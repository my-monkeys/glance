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
}
