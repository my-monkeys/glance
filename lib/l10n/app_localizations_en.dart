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
}
