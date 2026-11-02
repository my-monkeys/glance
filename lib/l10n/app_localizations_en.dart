// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageAuto => 'Automatic';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get commonClose => 'Close';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonRetry => 'Retry';

  @override
  String get tabSites => 'Sites';

  @override
  String get tabDirect => 'Live';

  @override
  String get tabSettings => 'Settings';

  @override
  String get siteSearchHint => 'Search sites';

  @override
  String siteSearchNoMatch(String query) {
    return 'No site matches \"$query\".';
  }

  @override
  String get navToday => 'Today';

  @override
  String get navYesterday => 'Yesterday';

  @override
  String get navDayBeforeYesterday => '2 days ago';

  @override
  String get navThisMonth => 'This month';

  @override
  String get navLastMonth => 'Last month';

  @override
  String get navThisYear => 'This year';

  @override
  String get navLastYear => 'Last year';

  @override
  String get workspaceSheetTitle => 'Scope';

  @override
  String get workspaceAllSites => 'All sites';

  @override
  String workspaceTrackedSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites tracked',
      one: '1 site tracked',
      zero: '0 sites tracked',
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
      zero: 'No sites',
    );
    return '$_temp0';
  }

  @override
  String get workspaceNewGroup => 'New group';

  @override
  String get workspaceManageGroups => 'Manage groups';

  @override
  String get homeTitleDefault => 'My sites';

  @override
  String get homeLoadFailed => 'Couldn\'t load.';

  @override
  String get homeInternalTitle => 'Between your sites';

  @override
  String homeTotalVisitors(String name) {
    return 'Visitors · $name';
  }

  @override
  String get homeTotalVisitorsAll => 'Visitors · all sites';

  @override
  String get homeVsPrevious => 'vs prev. period';

  @override
  String homeLiveCount(int count) {
    return '$count live';
  }

  @override
  String get homeEmptyTitle => 'No sites shown';

  @override
  String get homeEmptyBody => 'No sites tracked yet. Pick the ones to show.';

  @override
  String get homeEmptyChooseSites => 'Choose sites';

  @override
  String get homeEmptyAddSource => '+ Add a source';

  @override
  String get homeEmptyGroupTitle => 'Empty group';

  @override
  String homeEmptyGroupBody(String name) {
    return '\"$name\" has no sites.';
  }

  @override
  String get homeEmptyGroupChoose => 'Choose its sites';

  @override
  String get homeEmptyGroupSeeAll => 'See all sites';

  @override
  String get homeWelcomeTagline => 'Your stats, at a glance.';

  @override
  String get homeWelcomeTitle => 'Connect your first tool';

  @override
  String get homeWelcomeBody =>
      'Umami, Plausible… add a source, then pick the sites to track.';

  @override
  String get homeWelcomeAddSource => 'Add a source';

  @override
  String get homeWelcomeFootnote => 'Read-only key · your data stays with you';

  @override
  String get homeSiteUnavailable => 'Unavailable';

  @override
  String get detailVisitorsUnique => 'Unique visitors';

  @override
  String get detailKpiVisits => 'Visits';

  @override
  String get detailKpiAvgDuration => 'Avg. time';

  @override
  String get detailKpiBounce => 'Bounce';

  @override
  String get detailLiveNow => 'Live now';

  @override
  String get detailLiveNobody => 'Nobody right now.';

  @override
  String get detailTabOverview => 'Overview';

  @override
  String get detailTabEvents => 'Events';

  @override
  String get detailTabDashboards => 'Dashboards';

  @override
  String get detailEventsEmpty => 'No events in this period';

  @override
  String get detailEventsTriggered => 'Events triggered';

  @override
  String get detailEventsByEvent => 'By event';

  @override
  String detailSectionViewAll(int count) {
    return 'View all $count rows';
  }

  @override
  String get detailBadgeInternal => 'INTERNAL';

  @override
  String get directEyebrow => 'Real time';

  @override
  String get directTitle => 'Live';

  @override
  String get directNow => 'right now';

  @override
  String get directVisitorsAll => 'visitors across all your sites';

  @override
  String directVisitorsGroup(String name) {
    return 'visitors in the “$name” group';
  }

  @override
  String get directBySite => 'By site';

  @override
  String get directOnlyActive => 'Active only';

  @override
  String get directNoneLive => 'No live visitors right now.';

  @override
  String get directNoSites => 'No sites.';

  @override
  String directHiddenSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites with no visitors hidden',
      one: '1 site with no visitors hidden',
    );
    return '$_temp0';
  }

  @override
  String networkExchanged(String period) {
    return 'Visitors exchanged · $period';
  }

  @override
  String networkPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites loading…',
      one: '1 site loading…',
    );
    return '$_temp0';
  }

  @override
  String get networkExplainer =>
      'Visitors who landed on one of your sites from another of your sites.';

  @override
  String get networkEmpty => 'No internal navigation in this period.';

  @override
  String get networkSenders => 'Who sends';

  @override
  String get networkReceivers => 'Who receives';

  @override
  String get networkFlows => 'Flows';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get dashboardsKindCounter => 'Counter';

  @override
  String get dashboardsKindRatio => 'Rate';

  @override
  String get dashboardsKindFunnel => 'Funnel';

  @override
  String get dashboardsKindBreakdown => 'Breakdown';

  @override
  String get dashboardsKindExternal => 'Metric';

  @override
  String get dashboardsKindSites => 'Sites';

  @override
  String get dashboardsMoveCard => 'Move dashboard';

  @override
  String get dashboardsCardOptions => 'Dashboard options';

  @override
  String get dashboardsResizeCard => 'Resize dashboard';

  @override
  String get dashboardsLoadFailed => 'Couldn\'t load.';

  @override
  String get dashboardsNoData => 'No data for this period';

  @override
  String get dashboardsNoEvents => 'No events in this period';

  @override
  String dashboardsUnpublished(String date) {
    return 'Not published yet: data through $date';
  }

  @override
  String get dashboardsPendingNow => 'Not measurable yet for this period';

  @override
  String dashboardsPendingDelay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Not measurable yet: needs $count days of hindsight',
      one: 'Not measurable yet: needs 1 day of hindsight',
    );
    return '$_temp0';
  }

  @override
  String dashboardsCohortOne(String date) {
    return 'Measured on the $date cohort';
  }

  @override
  String dashboardsCohortRange(String range) {
    return 'Measured on cohorts $range';
  }

  @override
  String dashboardsFamilyMember(String member) {
    return '$member · adjusts to the period';
  }

  @override
  String dashboardsDataUntil(String date) {
    return 'Data through $date';
  }

  @override
  String dashboardsFunnelVisitors(String last, String first) {
    return '$last / $first visitors';
  }

  @override
  String dashboardsCohortTooltip(String date, String cohort) {
    return '$date · cohort of $cohort';
  }

  @override
  String get dashboardsTotal => 'Total';

  @override
  String dashboardsSegmentEstimated(String label) {
    return '$label · estimated';
  }

  @override
  String get dashboardsDeleted => 'Dashboard deleted';

  @override
  String get dashboardsConfirmDelete => 'Confirm deletion';

  @override
  String get dashboardsAllHidden => 'No dashboard has data for this period';

  @override
  String dashboardsHiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dashboards without data for this period',
      one: '1 dashboard without data for this period',
    );
    return '$_temp0';
  }

  @override
  String get dashboardsShow => 'Show';

  @override
  String get dashboardsArrangeHint =>
      'Press and hold a card to move it, drag its corner to resize it.';

  @override
  String get dashboardsArrange => 'Arrange';

  @override
  String get dashboardsArrangeDone => 'Done';

  @override
  String get dashboardsNew => 'New dashboard';

  @override
  String get dashboardsEmptyTitle => 'No dashboards';

  @override
  String get dashboardsEmptyBody =>
      'Track a rate, a funnel or a breakdown built on your events.';

  @override
  String get dashboardsCreate => 'Create a dashboard';

  @override
  String get dashboardsMetricsSource => 'Metrics source';

  @override
  String get dashboardsMetricsIntro =>
      'A small API on your site that serves indicators computed from its database (retention, accounts…): a catalogue and series, protected by a token.';

  @override
  String get dashboardsMetricsHowItWorks => 'How does it work?';

  @override
  String get dashboardsMetricsUrlLabel => 'API address';

  @override
  String get dashboardsMetricsUrlHint =>
      'https://example.com/api/internal/metrics/';

  @override
  String get dashboardsMetricsToken => 'Token';

  @override
  String get dashboardsMetricsTest => 'Test';

  @override
  String dashboardsMetricsAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count indicators available',
      one: '1 indicator available',
    );
    return '$_temp0';
  }

  @override
  String get dashboardsMetricsSaved => 'Source saved';

  @override
  String get dashboardsMetricsRemove => 'Remove source';

  @override
  String dashboardsMetricsRemoveWithCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dashboards',
      one: '1 dashboard',
    );
    return 'Remove source and $_temp0';
  }

  @override
  String get dashboardsMetricsRemoved => 'Source removed';

  @override
  String dashboardsMetricsRemovedWithCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dashboards deleted',
      one: '1 dashboard deleted',
    );
    return 'Source removed, $_temp0';
  }

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonSearch => 'Search';

  @override
  String get editorNameFallback => 'Untitled';

  @override
  String editorNameBy(String a, String b) {
    return '$a by $b';
  }

  @override
  String get editorErrChooseEvent => 'Choose an event';

  @override
  String get editorErrChooseCountEvent => 'Choose the event to count';

  @override
  String get editorErrChooseRefEvent => 'Choose the reference event';

  @override
  String get editorErrChooseProperty => 'Choose a property';

  @override
  String get editorErrChooseMetric => 'Choose a metric';

  @override
  String get editorErrAddSite => 'Add at least one site';

  @override
  String editorErrSitesMax(int max) {
    return 'A dashboard has at most $max sites';
  }

  @override
  String get editorErrChooseLineSite => 'Choose the site for each line';

  @override
  String get editorErrNameLines => 'Name each line';

  @override
  String get editorErrReferrer => 'Enter the referrer domain';

  @override
  String editorErrFunnelMin(int min) {
    return 'A funnel has at least $min steps';
  }

  @override
  String editorErrFunnelMax(int max) {
    return 'A funnel has at most $max steps';
  }

  @override
  String editorErrStepEvent(int n) {
    return 'Choose the event for step $n';
  }

  @override
  String get editorErrFunnelNumeric =>
      'A funnel can\'t compare numbers: remove this filter';

  @override
  String get editorErrWindow => 'Invalid time limit';

  @override
  String get editorErrFilterValueMissing => 'Filter value missing';

  @override
  String get editorErrFilterNotNumber => 'Filter value isn\'t a number';

  @override
  String get editorTitleEdit => 'Edit dashboard';

  @override
  String get editorFieldName => 'Name';

  @override
  String get editorHeadingType => 'Type';

  @override
  String get editorHeadingPreview => 'Preview';

  @override
  String get editorPreviewEmpty =>
      'The preview appears as soon as the dashboard is complete.';

  @override
  String get editorCreated => 'Dashboard created';

  @override
  String get editorSaved => 'Dashboard saved';

  @override
  String get editorDelete => 'Delete this dashboard';

  @override
  String get editorCreate => 'Create';

  @override
  String get editorCountLabel => 'What to count';

  @override
  String get editorRatioOf => 'Relative to';

  @override
  String get editorGapsLabel => 'Leave a gap when nothing happened';

  @override
  String get editorGapsHint => 'Otherwise those days count as 0%.';

  @override
  String get editorOverTimeLabel => 'Trend over time';

  @override
  String get editorOverTimeHint => 'One line per value, full width';

  @override
  String get editorMetricLabel => 'Metric';

  @override
  String get editorMetricPlaceholder => 'Choose a metric';

  @override
  String get editorMetricNone => 'This source offers no indicators.';

  @override
  String get editorMetricAdjusts => 'adjusts to the period';

  @override
  String get editorEventLabel => 'Event';

  @override
  String get editorEventPlaceholder => 'Choose an event';

  @override
  String get editorPropertyLabel => 'Property';

  @override
  String get editorPropertyPlaceholder => 'Choose a property';

  @override
  String get editorKindExternal => 'Site metric';

  @override
  String get editorKindHintCounter => 'How often an event happens';

  @override
  String get editorKindHintRatio => 'One event relative to another';

  @override
  String get editorKindHintFunnel => 'The journey, step by step';

  @override
  String get editorKindHintBreakdown => 'The values of a property';

  @override
  String get editorKindHintExternal => 'An indicator served by your API';

  @override
  String get editorKindHintSites => 'Visitors across several sites';

  @override
  String get editorFunnelAddStep => 'Add a step';

  @override
  String get editorFunnelWindowLabel => 'Maximum time between two steps';

  @override
  String editorFunnelWindowHint(int min, int max) {
    return 'In minutes ($min to $max): a visitor who takes longer to get from one step to the next is no longer counted.';
  }

  @override
  String editorFunnelStep(int n) {
    return 'STEP $n';
  }

  @override
  String get editorFunnelMoveUp => 'Move step up';

  @override
  String get editorFunnelMoveDown => 'Move step down';

  @override
  String get editorFunnelRemove => 'Remove step';

  @override
  String get editorTypeText => 'text';

  @override
  String get editorTypeNumber => 'number';

  @override
  String get editorTypeBoolean => 'yes/no';

  @override
  String get editorFreeEvent => 'Type an event name';

  @override
  String get editorFreeProperty => 'Type a property name';

  @override
  String get editorSiteLabel => 'Site';

  @override
  String editorUseTyped(String value) {
    return 'Use “$value”';
  }

  @override
  String get editorListUnavailable =>
      'List unavailable — type the name by hand.';

  @override
  String get editorListEmpty =>
      'Nothing seen in 30 days — type the name by hand.';

  @override
  String get editorAddFilter => 'Add a filter';

  @override
  String get editorRemoveFilter => 'Remove filter';

  @override
  String get editorFilterValue => 'Value';

  @override
  String get editorTrue => 'true';

  @override
  String get editorFalse => 'false';

  @override
  String get editorModeAll => 'All';

  @override
  String get editorModeOnly => 'From';

  @override
  String get editorModeExcept => 'Except from';

  @override
  String get editorLineSitePlaceholder => 'Choose a site';

  @override
  String get editorLineLabel => 'Label';

  @override
  String get editorLineReferrer => 'Referrer domain';

  @override
  String get editorLineAdd => 'Add a site';

  @override
  String get editorLinesHint =>
      'Unique visitors for each line. “Except from” removes those the site received from that domain.';

  @override
  String editorLineTitle(int n) {
    return 'LINE $n';
  }

  @override
  String get editorLineRemove => 'Remove line';
}
