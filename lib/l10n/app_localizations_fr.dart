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

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonAdd => 'Ajouter';

  @override
  String get commonSearch => 'Rechercher';

  @override
  String get editorNameFallback => 'Sans titre';

  @override
  String editorNameBy(String a, String b) {
    return '$a par $b';
  }

  @override
  String get editorErrChooseEvent => 'Choisissez un événement';

  @override
  String get editorErrChooseCountEvent => 'Choisissez l\'événement à compter';

  @override
  String get editorErrChooseRefEvent => 'Choisissez l\'événement de référence';

  @override
  String get editorErrChooseProperty => 'Choisissez une propriété';

  @override
  String get editorErrChooseMetric => 'Choisissez une métrique';

  @override
  String get editorErrAddSite => 'Ajoutez au moins un site';

  @override
  String editorErrSitesMax(int max) {
    return 'Un tableau compte au plus $max sites';
  }

  @override
  String get editorErrChooseLineSite => 'Choisissez le site de chaque ligne';

  @override
  String get editorErrNameLines => 'Nommez chaque ligne';

  @override
  String get editorErrReferrer => 'Indiquez le domaine du référent';

  @override
  String editorErrFunnelMin(int min) {
    return 'Un entonnoir compte au moins $min étapes';
  }

  @override
  String editorErrFunnelMax(int max) {
    return 'Un entonnoir compte au plus $max étapes';
  }

  @override
  String editorErrStepEvent(int n) {
    return 'Choisissez l\'événement de l\'étape $n';
  }

  @override
  String get editorErrFunnelNumeric =>
      'Un entonnoir ne compare pas les nombres : retirez ce filtre';

  @override
  String get editorErrWindow => 'Délai invalide';

  @override
  String get editorErrFilterValueMissing => 'Valeur du filtre manquante';

  @override
  String get editorErrFilterNotNumber => 'Valeur de filtre non numérique';

  @override
  String get editorTitleEdit => 'Modifier le tableau';

  @override
  String get editorFieldName => 'Nom';

  @override
  String get editorHeadingType => 'Type';

  @override
  String get editorHeadingPreview => 'Aperçu';

  @override
  String get editorPreviewEmpty =>
      'L\'aperçu apparaît dès que le tableau est complet.';

  @override
  String get editorCreated => 'Tableau créé';

  @override
  String get editorSaved => 'Tableau enregistré';

  @override
  String get editorDelete => 'Supprimer ce tableau';

  @override
  String get editorCreate => 'Créer';

  @override
  String get editorCountLabel => 'Ce qu\'on compte';

  @override
  String get editorRatioOf => 'Rapporté à';

  @override
  String get editorGapsLabel => 'Laisser un trou quand rien ne s\'est passé';

  @override
  String get editorGapsHint => 'Sinon, ces jours-là comptent pour 0 %.';

  @override
  String get editorOverTimeLabel => 'Évolution dans le temps';

  @override
  String get editorOverTimeHint =>
      'Une courbe par valeur, sur toute la largeur';

  @override
  String get editorMetricLabel => 'Métrique';

  @override
  String get editorMetricPlaceholder => 'Choisir une métrique';

  @override
  String get editorMetricNone => 'Cette source ne propose aucun indicateur.';

  @override
  String get editorMetricAdjusts => 's\'ajuste à la période';

  @override
  String get editorEventLabel => 'Événement';

  @override
  String get editorEventPlaceholder => 'Choisir un événement';

  @override
  String get editorPropertyLabel => 'Propriété';

  @override
  String get editorPropertyPlaceholder => 'Choisir une propriété';

  @override
  String get editorKindExternal => 'Métrique du site';

  @override
  String get editorKindHintCounter => 'Combien de fois un événement arrive';

  @override
  String get editorKindHintRatio => 'Un événement rapporté à un autre';

  @override
  String get editorKindHintFunnel => 'Le parcours étape par étape';

  @override
  String get editorKindHintBreakdown => 'Les valeurs d\'une propriété';

  @override
  String get editorKindHintExternal => 'Un indicateur fourni par votre API';

  @override
  String get editorKindHintSites => 'Les visiteurs de plusieurs sites';

  @override
  String get editorFunnelAddStep => 'Ajouter une étape';

  @override
  String get editorFunnelWindowLabel => 'Délai maximum entre deux étapes';

  @override
  String editorFunnelWindowHint(int min, int max) {
    return 'En minutes (de $min à $max) : un visiteur qui met plus de temps à passer d\'une étape à la suivante n\'est plus compté.';
  }

  @override
  String editorFunnelStep(int n) {
    return 'ÉTAPE $n';
  }

  @override
  String get editorFunnelMoveUp => 'Monter l\'étape';

  @override
  String get editorFunnelMoveDown => 'Descendre l\'étape';

  @override
  String get editorFunnelRemove => 'Retirer l\'étape';

  @override
  String get editorTypeText => 'texte';

  @override
  String get editorTypeNumber => 'nombre';

  @override
  String get editorTypeBoolean => 'oui-non';

  @override
  String get editorFreeEvent => 'Saisir un nom d\'événement';

  @override
  String get editorFreeProperty => 'Saisir un nom de propriété';

  @override
  String get editorSiteLabel => 'Site';

  @override
  String editorUseTyped(String value) {
    return 'Utiliser « $value »';
  }

  @override
  String get editorListUnavailable =>
      'Liste indisponible — saisissez le nom à la main.';

  @override
  String get editorListEmpty =>
      'Rien de vu sur 30 jours — saisissez le nom à la main.';

  @override
  String get editorAddFilter => 'Ajouter un filtre';

  @override
  String get editorRemoveFilter => 'Retirer le filtre';

  @override
  String get editorFilterValue => 'Valeur';

  @override
  String get editorTrue => 'vrai';

  @override
  String get editorFalse => 'faux';

  @override
  String get editorModeAll => 'Tous';

  @override
  String get editorModeOnly => 'Venus de';

  @override
  String get editorModeExcept => 'Sauf venus de';

  @override
  String get editorLineSitePlaceholder => 'Choisir un site';

  @override
  String get editorLineLabel => 'Libellé';

  @override
  String get editorLineReferrer => 'Domaine du référent';

  @override
  String get editorLineAdd => 'Ajouter un site';

  @override
  String get editorLinesHint =>
      'Visiteurs uniques de chaque ligne. « Sauf venus de » retire ceux que le site a reçus de ce domaine.';

  @override
  String editorLineTitle(int n) {
    return 'LIGNE $n';
  }

  @override
  String get editorLineRemove => 'Retirer la ligne';

  @override
  String commonSiteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites',
      one: '1 site',
      zero: '0 site',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsGroupAccount => 'Compte';

  @override
  String get settingsGroupSites => 'Sites';

  @override
  String get settingsGroupSync => 'Synchronisation';

  @override
  String get settingsGroupTransfer => 'Transfert';

  @override
  String get settingsGroupAppearance => 'Apparence';

  @override
  String get settingsGroupData => 'Données';

  @override
  String get settingsGroupApp => 'Application';

  @override
  String get settingsAccountBadAuth => 'Identifiants ou clé API refusés';

  @override
  String get settingsAccountUnreachable => 'Instance injoignable';

  @override
  String settingsAccountSubtitle(String provider, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites',
      one: '1 site',
      zero: '0 site',
    );
    return '$provider · $_temp0';
  }

  @override
  String get settingsAddSource => 'Ajouter une source';

  @override
  String get settingsGroupsTitle => 'Groupes';

  @override
  String get settingsGroupsHint => 'Lire une partie de vos sites à part';

  @override
  String get settingsSyncConnected => 'Connecté';

  @override
  String get settingsSyncPitch => 'Sauvegarder et synchroniser (chiffré)';

  @override
  String get settingsTransferShow => 'Afficher un QR de transfert';

  @override
  String get settingsTransferNone => 'Aucun compte à transférer';

  @override
  String get settingsTransferContents => 'Comptes, identifiants et groupes';

  @override
  String get settingsTransferImport => 'Importer depuis un autre appareil';

  @override
  String get settingsTransferScan => 'Scanner un QR de transfert';

  @override
  String get settingsThemeTitle => 'Thème';

  @override
  String get settingsThemeAuto => 'Auto';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsChartsTitle => 'Graphiques';

  @override
  String get settingsChartsHint => 'Courbe lissée ou barres';

  @override
  String get settingsChartCurve => 'Courbe';

  @override
  String get settingsChartBars => 'Barres';

  @override
  String get settingsDefaultPeriod => 'Période par défaut';

  @override
  String get settingsDefaultPeriodHint => 'À l\'ouverture de l\'application';

  @override
  String get settingsRefresh => 'Actualisation auto';

  @override
  String settingsRefreshSeconds(int count) {
    return '$count s';
  }

  @override
  String settingsRefreshMinutes(int count) {
    return '$count min';
  }

  @override
  String get settingsCheckUpdates => 'Rechercher des mises à jour';

  @override
  String get accountMenuConnectionOk => 'Connexion réussie';

  @override
  String accountMenuConnectionOkSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Connexion réussie · $count sites',
      one: 'Connexion réussie · 1 site',
    );
    return '$_temp0';
  }

  @override
  String get accountMenuTest => 'Tester la connexion';

  @override
  String get accountMenuEdit => 'Modifier la source';

  @override
  String get accountMenuEditHint => 'URL, identifiants, clé API…';

  @override
  String get accountMenuChooseSites => 'Choisir les sites';

  @override
  String get accountMenuDelete => 'Supprimer ce compte';

  @override
  String get accountMenuDeleted => 'Source supprimée';

  @override
  String get accountMenuSelectionSaved => 'Sélection enregistrée';

  @override
  String get accountSelectionAll => 'tous les sites';

  @override
  String accountSelectionAllExcept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tous sauf $count sites',
      one: 'tous sauf 1 site',
    );
    return '$_temp0';
  }

  @override
  String get accountSelectionNone => 'aucun site';

  @override
  String get syncSubtitle =>
      'Vos comptes et groupes, synchronisés et chiffrés.';

  @override
  String get syncEmail => 'E-mail';

  @override
  String get syncEmailHint => 'vous@exemple.fr';

  @override
  String get syncPassword => 'Mot de passe';

  @override
  String syncPasswordHint(int count) {
    return '$count caractères minimum';
  }

  @override
  String get syncCreateAccount => 'Créer un compte';

  @override
  String get syncCreateAccountButton => 'Créer le compte';

  @override
  String get syncSignIn => 'Se connecter';

  @override
  String get syncHaveAccount => 'J\'ai déjà un compte';

  @override
  String get syncEncryptedNote =>
      'Votre config est chiffrée sur l\'appareil avant l\'envoi : le serveur ne peut pas la lire. Mot de passe oublié = sync irrécupérable.';

  @override
  String get syncToastCreated => 'Compte créé';

  @override
  String get syncToastSignedIn => 'Connecté';

  @override
  String get syncToastSignedOut => 'Déconnecté';

  @override
  String get syncToastSynced => 'Synchronisé';

  @override
  String get syncToastDeleted => 'Compte supprimé';

  @override
  String get syncToastUnlocked => 'Glance Sync débloqué';

  @override
  String get syncToastRestored => 'Achat restauré';

  @override
  String get syncNever => 'Jamais synchronisé';

  @override
  String syncLastSync(String date) {
    return 'Sync $date';
  }

  @override
  String get syncNow => 'Synchroniser maintenant';

  @override
  String get syncSignOut => 'Se déconnecter';

  @override
  String get syncDeleteAccount => 'Supprimer mon compte';

  @override
  String get syncDeleteTitle => 'Supprimer le compte ?';

  @override
  String get syncDeleteBody =>
      'Votre compte Glance Sync et toute la configuration synchronisée seront définitivement supprimés du serveur. Action irréversible. Vos sources analytics restent sur cet appareil.';

  @override
  String get syncUnlockTitle => 'Débloquez Glance Sync';

  @override
  String get syncUnlockBuy =>
      'Sauvegardez et synchronisez vos comptes et groupes sur tous vos appareils. Achat unique.';

  @override
  String get syncUnlockElsewhere =>
      'Achat unique depuis l\'app mobile (iOS/Android). Une fois débloqué, connectez-vous ici avec le même compte : la sync suit automatiquement.';

  @override
  String get syncUnlockButton => 'Débloquer';

  @override
  String get syncRestore => 'Restaurer un achat';

  @override
  String get syncSoon => 'Bientôt disponible';

  @override
  String get transferExportTitle => 'Transférer';

  @override
  String get transferExportSubtitle =>
      'Scannez ce code depuis l\'autre appareil.';

  @override
  String transferExpiresIn(String time) {
    return 'Expire dans $time';
  }

  @override
  String get transferCodeLabel => 'Code à saisir sur l\'autre appareil';

  @override
  String get transferWarning =>
      'Ce code contient vos identifiants. Ne le photographiez pas et ne le partagez pas : le QR seul ne suffit pas, mais avec le code à 4 chiffres il donne accès à vos comptes.';

  @override
  String get transferExpiredTitle => 'Code expiré';

  @override
  String get transferExpiredBody =>
      'Un transfert ne reste valable que quelques minutes.';

  @override
  String get transferRegenerate => 'Régénérer';

  @override
  String get transferTooLargeTitle => 'Config trop grosse';

  @override
  String transferTooLargeBody(int size, int max) {
    return 'Elle ne tient pas dans un QR code ($size caractères pour $max au maximum). Suivez « tous les sites » sur vos comptes plutôt qu\'une sélection, puis réessayez.';
  }

  @override
  String get transferFailedTitle => 'Transfert impossible';

  @override
  String get transferFailedBody => 'Impossible de préparer le transfert.';

  @override
  String get transferImportTitle => 'Importer';

  @override
  String get transferImportScanHint =>
      'Visez le QR affiché sur l\'autre appareil.';

  @override
  String get transferImportCodeHint =>
      'Saisissez le code affiché à côté du QR.';

  @override
  String get transferScanned => 'Code scanné';

  @override
  String get transferCodeField => 'Code à 4 chiffres';

  @override
  String get transferImportButton => 'Importer';

  @override
  String get transferRescan => 'Scanner à nouveau';

  @override
  String transferImported(int accounts, int groups) {
    String _temp0 = intl.Intl.pluralLogic(
      accounts,
      locale: localeName,
      other: '$accounts comptes',
      one: '1 compte',
    );
    String _temp1 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups groupes',
      one: '1 groupe',
      zero: '0 groupe',
    );
    return '$_temp0 et $_temp1 importés';
  }

  @override
  String get transferErrExpired =>
      'Ce code a expiré. Régénérez-le sur l\'autre appareil.';

  @override
  String get transferErrBadCode => 'Code incorrect.';

  @override
  String get transferErrFailed => 'Import impossible.';

  @override
  String get transferCameraDenied => 'Caméra refusée';

  @override
  String get transferCameraUnavailable => 'Caméra indisponible';

  @override
  String get transferCameraDeniedBody =>
      'Autorisez l\'accès à la caméra dans les réglages du système pour scanner un transfert.';

  @override
  String get transferCameraUnavailableBody =>
      'Aucune caméra utilisable sur cet appareil.';

  @override
  String get groupsSubtitle =>
      'Un périmètre de lecture : totaux et courbe ne comptent que ses sites.';

  @override
  String get groupsEmptyTitle => 'Aucun groupe';

  @override
  String get groupsEmptyBody =>
      'Regroupez vos sites — par exemple « Jeux » ou « Clients » — pour lire leurs statistiques à part, sans le reste.';

  @override
  String get groupsCreate => 'Créer un groupe';

  @override
  String get groupEditEditTitle => 'Modifier le groupe';

  @override
  String get groupEditName => 'Nom';

  @override
  String get groupEditNameHint => 'Jeux, Clients, Perso…';

  @override
  String get groupEditSitesLabel => 'Sites du groupe';

  @override
  String get groupEditAddSourceHint => 'ses sites entrent ici';

  @override
  String get groupEditNoSites =>
      'Aucun site suivi pour l\'instant — ajoutez une source ci-dessus pour remplir ce groupe.';

  @override
  String get groupEditCreateButton => 'Créer le groupe';

  @override
  String get groupEditCreated => 'Groupe créé';

  @override
  String get groupEditSaved => 'Groupe enregistré';

  @override
  String get groupEditDeleted => 'Groupe supprimé';

  @override
  String get groupEditDeleteTitle => 'Supprimer ce groupe ?';

  @override
  String get groupEditDeleteBody =>
      'Les sites et leurs statistiques ne sont pas touchés — seul le regroupement disparaît.';

  @override
  String get addSourceNewTitle => 'Nouvelle source';

  @override
  String get addSourceProvider => 'FOURNISSEUR';

  @override
  String get addSourceName => 'Étiquette (optionnelle)';

  @override
  String get addSourceNameHint => 'Perso, Pro…';

  @override
  String get addSourceTest => 'Tester la configuration';

  @override
  String get addSourceContinue => 'Continuer';

  @override
  String get addSourceMissingFields => 'Renseigne les champs obligatoires.';

  @override
  String get addSourceTestOk => 'Connexion réussie.';

  @override
  String addSourceTestOkSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Connexion réussie · $count sites détectés',
      one: 'Connexion réussie · 1 site détecté',
    );
    return '$_temp0';
  }

  @override
  String get addSourceNoSitesPlausible =>
      'Aucun site listé automatiquement : votre instance n\'expose pas l\'API de listing (Plausible Community Edition). Renseignez le domaine à suivre ci-dessus.';

  @override
  String get addSourceNoSites => 'Aucun site trouvé pour ce compte.';

  @override
  String get addSourceKeyRejected =>
      'Clé API refusée (accès aux stats). Vérifiez la clé API.';

  @override
  String get addSourceCredsRejected => 'Identifiants refusés.';

  @override
  String get addSourceUmamiHosting => 'HÉBERGEMENT';

  @override
  String get addSourceUmamiSelfHosted => 'Auto-hébergé';

  @override
  String get addSourceUmamiCloudUseKey =>
      'Umami Cloud se connecte avec une clé API : choisissez « Umami Cloud » ci-dessus.';

  @override
  String get addSourceAdded => 'Source ajoutée';

  @override
  String get addSourceEdited => 'Source modifiée';

  @override
  String get sitePickerTitle => 'Choix des sites';

  @override
  String sitePickerDetected(String provider, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites détectés',
      one: '1 site détecté',
    );
    return '$provider · $_temp0';
  }

  @override
  String get sitePickerFollowNew => 'Afficher les nouveaux sites';

  @override
  String get sitePickerFollowNewHint =>
      'Un site créé plus tard apparaît tout seul';

  @override
  String get sitePickerCurrent => 'Sites actuels';

  @override
  String sitePickerShownOf(int shown, int total) {
    return '$shown sur $total';
  }

  @override
  String get sitePickerCheckAll => 'Tout cocher';

  @override
  String get sitePickerUncheckAll => 'Tout décocher';

  @override
  String get sitePickerFollowAll => 'Suivre tous les sites';

  @override
  String sitePickerFollowAndNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Suivre $count sites et les nouveaux',
      one: 'Suivre 1 site et les nouveaux',
      zero: 'Suivre 0 site et les nouveaux',
    );
    return '$_temp0';
  }

  @override
  String sitePickerFollow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Suivre $count sites',
      one: 'Suivre 1 site',
      zero: 'Suivre 0 site',
    );
    return '$_temp0';
  }

  @override
  String get sitePickerShowNone => 'N\'afficher aucun site';

  @override
  String get commonVisitors => 'Visiteurs';

  @override
  String get commonPageviews => 'Pages vues';

  @override
  String get commonNoData => 'Aucune donnée';

  @override
  String desktopSitesHeader(int count) {
    return 'Sites ($count)';
  }

  @override
  String desktopHiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count masqués',
      one: '$count masqué',
    );
    return '$_temp0';
  }

  @override
  String get desktopShowAllSites => 'Afficher tous les sites';

  @override
  String get desktopHideEmptySites => 'Masquer les sites sans visiteur';

  @override
  String get desktopLiveNobody => 'Personne en ce moment.';

  @override
  String get desktopKpiSites => 'Sites';

  @override
  String desktopNoSitesGroupBody(String name) {
    return '« $name » ne contient aucun site. Choisissez ceux qui en font partie.';
  }

  @override
  String get desktopNoSitesBody =>
      'Vos comptes ne suivent aucun site pour le moment. Choisissez les sites à afficher depuis les réglages.';

  @override
  String get chartLegendForecast => 'Prévision';

  @override
  String get chartLegendPrevious => 'Période précédente';

  @override
  String get chartTooltipVisitors => 'visiteurs';

  @override
  String get chartTooltipPageviews => 'pages vues';

  @override
  String get chartTooltipForecast => 'prévision';

  @override
  String get chartTooltipPrevious => 'période précédente';

  @override
  String get chartNoSeries => 'Aucune série sélectionnée';

  @override
  String chartHour(String hour) {
    return '${hour}h';
  }

  @override
  String get periodControlsDisplay => 'Affichage';

  @override
  String get periodControlsSplit => 'Découpage';

  @override
  String get periodControlsChart => 'Graphique';

  @override
  String get periodUnitHour => 'Heure';

  @override
  String get periodUnitDay => 'Jour';

  @override
  String get periodUnitMonth => 'Mois';

  @override
  String get errorsAuthRefused => 'Identifiants refusés.';

  @override
  String get errorsRequestRefused => 'Requête refusée par le serveur.';

  @override
  String get errorsNotFound => 'Instance ou API introuvable.';

  @override
  String get errorsTimeout => 'Délai dépassé — instance lente ou injoignable.';

  @override
  String get errorsUnreachable => 'Instance injoignable. Vérifie l\'URL.';

  @override
  String errorsServerCode(int code) {
    return 'Erreur $code du serveur.';
  }

  @override
  String get errorsConnectionFailed => 'Connexion impossible.';

  @override
  String errorsGeneric(String detail) {
    return 'Erreur : $detail';
  }

  @override
  String get errUnsupportedIndicators => 'Indicateurs non pris en charge';

  @override
  String get errUnsupportedSiteTables => 'Tableaux de sites non pris en charge';

  @override
  String get errUnsupportedFunnels => 'Entonnoirs non pris en charge';

  @override
  String get errUnsupportedBreakdowns => 'Répartitions non prises en charge';

  @override
  String errOperatorUmamiFunnel(String op) {
    return 'Opérateur « $op » indisponible dans un entonnoir Umami';
  }

  @override
  String errOperatorPlausible(String op) {
    return 'Opérateur « $op » indisponible chez Plausible (propriétés en texte seulement)';
  }

  @override
  String get errFathomSoon => 'Fathom arrive bientôt.';

  @override
  String get errPlausibleNeedsSite =>
      'Renseignez un domaine, ou email + mot de passe pour lister vos sites automatiquement.';

  @override
  String get errUmamiLoginUnexpected => 'Réponse de login Umami inattendue';

  @override
  String errBucketsTooFine(int count) {
    return 'Découpage trop fin : plus de $count points sur la période.';
  }

  @override
  String get errMetricsNotConfigured => 'Source non configurée sur le serveur';

  @override
  String get errMetricsBadToken => 'Jeton refusé';

  @override
  String errMetricsBadRequest(String code) {
    return 'Requête refusée ($code)';
  }

  @override
  String get errMetricsUnsupportedVersion =>
      'Version d\'API non prise en charge';

  @override
  String get errMetricsUnexpected => 'Réponse inattendue du serveur';

  @override
  String get syncMsgUnreachable => 'Serveur injoignable. Réessayez.';

  @override
  String get syncMsgSessionExpired =>
      'Session expirée. Reconnectez-vous puis réessayez.';

  @override
  String get syncMsgPurchaseFailed => 'Achat impossible. Réessayez.';

  @override
  String get syncMsgPurchasePending =>
      'Achat validé — activation en cours, réessayez la sync dans un instant.';

  @override
  String get syncMsgNothingToRestore => 'Aucun achat à restaurer.';

  @override
  String get syncMsgRestorePending => 'Achat restauré — activation en cours…';

  @override
  String get syncMsgCannotDecrypt =>
      'Impossible de déchiffrer la config distante.';

  @override
  String get syncMsgProRequired => 'Sync réservée à Glance Sync (Pro).';

  @override
  String get syncMsgBadCredentials => 'E-mail ou mot de passe incorrect.';

  @override
  String syncMsgPasswordTooShort(int count) {
    return 'Mot de passe trop court : $count caractères minimum.';
  }

  @override
  String get syncMsgPasswordTooLong => 'Mot de passe trop long.';

  @override
  String get syncMsgInvalidEmail => 'Adresse e-mail invalide.';

  @override
  String get syncMsgAccountExists =>
      'Cet e-mail a déjà un compte : connectez-vous.';

  @override
  String get syncMsgSignUpFailed => 'Impossible de créer le compte.';

  @override
  String get periodToday => 'Aujourd\'hui';

  @override
  String get period24h => '24 h';

  @override
  String get period7d => '7 jours';

  @override
  String get period30d => '30 j';

  @override
  String get periodThisMonth => 'Ce mois-ci';

  @override
  String get period12m => '12 m';

  @override
  String get periodThisYear => 'Cette année';

  @override
  String get periodAllTime => 'Tout';

  @override
  String get periodCustom => 'Perso';

  @override
  String get metricTypePages => 'Chemins';

  @override
  String get metricTypeEntry => 'Entrée';

  @override
  String get metricTypeExit => 'Sortie';

  @override
  String get metricTypeTitle => 'Titre';

  @override
  String get metricTypeReferrers => 'Référents';

  @override
  String get metricTypeChannels => 'Canaux';

  @override
  String get metricTypeQueries => 'Requêtes';

  @override
  String get metricTypeBrowsers => 'Navigateurs';

  @override
  String get metricTypeOs => 'OS';

  @override
  String get metricTypeDevices => 'Appareils';

  @override
  String get metricTypeScreens => 'Écrans';

  @override
  String get metricTypeCountries => 'Pays';

  @override
  String get metricTypeRegions => 'Régions';

  @override
  String get metricTypeCities => 'Villes';

  @override
  String get metricTypeLanguages => 'Langues';

  @override
  String get metricTypeEvents => 'Événements';

  @override
  String get metricSectionPages => 'Pages';

  @override
  String get metricSectionSources => 'Sources';

  @override
  String get metricSectionEnvironment => 'Environnement';

  @override
  String get metricSectionLocation => 'Emplacement';

  @override
  String get filterOpContains => 'contient';

  @override
  String get filterOpNotContains => 'ne contient pas';

  @override
  String get entityUnknown => 'Inconnu';

  @override
  String get entityReferrerDirect => 'Accès direct';

  @override
  String get entityBrowserSearchBot => 'Robot d\'indexation';

  @override
  String get entityDeviceDesktop => 'Ordinateur';

  @override
  String get entityDeviceLaptop => 'Portable';

  @override
  String get entityDeviceTablet => 'Tablette';

  @override
  String get entityDeviceMobile => 'Mobile';

  @override
  String get entityDeviceWearable => 'Montre';

  @override
  String get entityDeviceConsole => 'Console';

  @override
  String get entityDeviceTv => 'Téléviseur';

  @override
  String get channelDirect => 'Direct';

  @override
  String get channelReferral => 'Référent';

  @override
  String get channelAffiliate => 'Affiliation';

  @override
  String get channelEmail => 'E-mail';

  @override
  String get channelOrganicSearch => 'Recherche organique';

  @override
  String get channelOrganicSocial => 'Réseaux sociaux';

  @override
  String get channelOrganicShopping => 'Achat organique';

  @override
  String get channelOrganicVideo => 'Vidéo organique';

  @override
  String get channelPaidAds => 'Publicité payante';

  @override
  String get channelPaidSearch => 'Recherche payante';

  @override
  String get channelPaidSocial => 'Réseaux sociaux payants';

  @override
  String get channelPaidShopping => 'Achat payant';

  @override
  String get channelPaidVideo => 'Vidéo payante';

  @override
  String get credInstanceUrl => 'URL de l\'instance';

  @override
  String get credUmamiUrlPlaceholder => 'analytics.mondomaine.fr';

  @override
  String get credUsername => 'Nom d\'utilisateur';

  @override
  String get credPassword => 'Mot de passe';

  @override
  String get credApiKey => 'Clé API';

  @override
  String get credUmamiCloudKeyHint =>
      'Créez-la dans Umami Cloud : Settings → API keys. L\'accès à l\'API demande un plan Pro.';

  @override
  String get credEmailOptional => 'Email du compte (facultatif)';

  @override
  String get credEmailPlaceholder => 'vous@exemple.fr';

  @override
  String get credEmailHint =>
      'Email + mot de passe : Glance liste vos sites automatiquement. Sinon, laissez vide et renseignez un domaine ci-dessous.';

  @override
  String get credPasswordOptional => 'Mot de passe (facultatif)';

  @override
  String get credDomainFallback => 'Domaine (si pas d\'email/mot de passe)';

  @override
  String get credDomainPlaceholder => 'mondomaine.fr';
}
