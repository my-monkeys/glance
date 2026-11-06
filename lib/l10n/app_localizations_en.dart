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
  String get homeEmptyGroupChoose => 'Choose sites';

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
  String get detailKpiBounce => 'Bounce rate';

  @override
  String get detailLiveNow => 'Live now';

  @override
  String get detailLiveNobody => 'Nobody right now.';

  @override
  String get detailTabOverview => 'Overview';

  @override
  String get detailTabEvents => 'Events';

  @override
  String get detailTabDashboards => 'Dashboard';

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
  String get dashboardsMoveCard => 'Move card';

  @override
  String get dashboardsCardOptions => 'Card options';

  @override
  String get dashboardsResizeCard => 'Resize card';

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
  String get dashboardsDeleted => 'Card deleted';

  @override
  String get dashboardsConfirmDelete => 'Confirm deletion';

  @override
  String get dashboardsAllHidden => 'No card has data for this period';

  @override
  String dashboardsHiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards without data for this period',
      one: '1 card without data for this period',
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
  String get dashboardsNew => 'New card';

  @override
  String get dashboardsEmptyTitle => 'No cards yet';

  @override
  String get dashboardsEmptyBody =>
      'Track a rate, a funnel or a breakdown built on your events.';

  @override
  String get dashboardsCreate => 'Create a card';

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
      other: '$count cards',
      one: '1 card',
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
      other: '$count cards deleted',
      one: '1 card deleted',
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
    return 'A card has at most $max sites';
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
  String get editorTitleEdit => 'Edit card';

  @override
  String get editorFieldName => 'Name';

  @override
  String get editorHeadingType => 'Type';

  @override
  String get editorHeadingPreview => 'Preview';

  @override
  String get editorPreviewEmpty =>
      'The preview appears as soon as the card is complete.';

  @override
  String get editorCreated => 'Card created';

  @override
  String get editorSaved => 'Card saved';

  @override
  String get editorDelete => 'Delete this card';

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

  @override
  String commonSiteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites',
      one: '1 site',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGroupAccount => 'Account';

  @override
  String get settingsGroupSites => 'Sites';

  @override
  String get settingsGroupSync => 'Sync';

  @override
  String get settingsGroupTransfer => 'Transfer';

  @override
  String get settingsGroupAppearance => 'Appearance';

  @override
  String get settingsGroupData => 'Data';

  @override
  String get settingsGroupApp => 'App';

  @override
  String get settingsAccountBadAuth => 'Credentials or API key rejected';

  @override
  String get settingsAccountUnreachable => 'Instance unreachable';

  @override
  String settingsAccountSubtitle(String provider, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites',
      one: '1 site',
    );
    return '$provider · $_temp0';
  }

  @override
  String get settingsAddSource => 'Add a source';

  @override
  String get settingsGroupsTitle => 'Groups';

  @override
  String get settingsGroupsHint => 'View a subset of your sites on its own';

  @override
  String get settingsSyncConnected => 'Signed in';

  @override
  String get settingsSyncPitch => 'Back up and sync (encrypted)';

  @override
  String get settingsTransferShow => 'Show a transfer QR code';

  @override
  String get settingsTransferNone => 'No account to transfer';

  @override
  String get settingsTransferContents => 'Accounts, credentials and groups';

  @override
  String get settingsTransferImport => 'Import from another device';

  @override
  String get settingsTransferScan => 'Scan a transfer QR code';

  @override
  String get settingsThemeTitle => 'Theme';

  @override
  String get settingsThemeAuto => 'Auto';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsChartsTitle => 'Charts';

  @override
  String get settingsChartsHint => 'Smooth curve or bars';

  @override
  String get settingsChartCurve => 'Curve';

  @override
  String get settingsChartBars => 'Bars';

  @override
  String get settingsDefaultPeriod => 'Default period';

  @override
  String get settingsDefaultPeriodHint => 'When the app opens';

  @override
  String get settingsRefresh => 'Auto refresh';

  @override
  String settingsRefreshSeconds(int count) {
    return '$count s';
  }

  @override
  String settingsRefreshMinutes(int count) {
    return '$count min';
  }

  @override
  String get settingsCheckUpdates => 'Check for updates';

  @override
  String get accountMenuConnectionOk => 'Connection successful';

  @override
  String accountMenuConnectionOkSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Connection successful · $count sites',
      one: 'Connection successful · 1 site',
    );
    return '$_temp0';
  }

  @override
  String get accountMenuTest => 'Test connection';

  @override
  String get accountMenuEdit => 'Edit source';

  @override
  String get accountMenuEditHint => 'URL, credentials, API key…';

  @override
  String get accountMenuChooseSites => 'Choose sites';

  @override
  String get accountMenuDelete => 'Delete this source';

  @override
  String get accountMenuDeleted => 'Source deleted';

  @override
  String get accountMenuSelectionSaved => 'Selection saved';

  @override
  String get accountSelectionAll => 'all sites';

  @override
  String accountSelectionAllExcept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'all but $count sites',
      one: 'all but 1 site',
    );
    return '$_temp0';
  }

  @override
  String get accountSelectionNone => 'no sites';

  @override
  String get syncSubtitle => 'Your accounts and groups, synced and encrypted.';

  @override
  String get syncEmail => 'Email';

  @override
  String get syncEmailHint => 'you@example.com';

  @override
  String get syncPassword => 'Password';

  @override
  String syncPasswordHint(int count) {
    return 'At least $count characters';
  }

  @override
  String get syncCreateAccount => 'Create an account';

  @override
  String get syncCreateAccountButton => 'Create account';

  @override
  String get syncSignIn => 'Sign in';

  @override
  String get syncHaveAccount => 'I already have an account';

  @override
  String get syncEncryptedNote =>
      'Your config is encrypted on your device before it\'s sent, so the server can\'t read it. Forget your password and your sync is gone for good.';

  @override
  String get syncToastCreated => 'Account created';

  @override
  String get syncToastSignedIn => 'Signed in';

  @override
  String get syncToastSignedOut => 'Signed out';

  @override
  String get syncToastSynced => 'Synced';

  @override
  String get syncToastDeleted => 'Account deleted';

  @override
  String get syncToastUnlocked => 'Glance Sync unlocked';

  @override
  String get syncToastRestored => 'Purchase restored';

  @override
  String get syncNever => 'Never synced';

  @override
  String syncLastSync(String date) {
    return 'Synced $date';
  }

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncSignOut => 'Sign out';

  @override
  String get syncDeleteAccount => 'Delete my account';

  @override
  String get syncDeleteTitle => 'Delete account?';

  @override
  String get syncDeleteBody =>
      'Your Glance Sync account and all synced configuration will be permanently deleted from the server. This can\'t be undone. Your analytics sources stay on this device.';

  @override
  String get syncUnlockTitle => 'Unlock Glance Sync';

  @override
  String get syncUnlockBuy =>
      'Back up and sync your accounts and groups across all your devices. One-time purchase.';

  @override
  String get syncUnlockElsewhere =>
      'One-time purchase from the mobile app (iOS/Android). Once unlocked, sign in here with the same account and sync follows automatically.';

  @override
  String get syncUnlockButton => 'Unlock';

  @override
  String get syncRestore => 'Restore a purchase';

  @override
  String get syncSoon => 'Coming soon';

  @override
  String get transferExportTitle => 'Transfer';

  @override
  String get transferExportSubtitle => 'Scan this code from the other device.';

  @override
  String transferExpiresIn(String time) {
    return 'Expires in $time';
  }

  @override
  String get transferCodeLabel => 'Code to enter on the other device';

  @override
  String get transferWarning =>
      'This code contains your credentials. Don\'t photograph or share it: the QR alone isn\'t enough, but together with the 4-digit code it gives access to your accounts.';

  @override
  String get transferExpiredTitle => 'Code expired';

  @override
  String get transferExpiredBody =>
      'A transfer is only valid for a few minutes.';

  @override
  String get transferRegenerate => 'New code';

  @override
  String get transferTooLargeTitle => 'Config too large';

  @override
  String transferTooLargeBody(int size, int max) {
    return 'It doesn\'t fit in a QR code ($size characters, $max at most). Follow \"all sites\" on your accounts instead of a selection, then try again.';
  }

  @override
  String get transferFailedTitle => 'Transfer failed';

  @override
  String get transferFailedBody => 'Couldn\'t prepare the transfer.';

  @override
  String get transferImportTitle => 'Import';

  @override
  String get transferImportScanHint =>
      'Point at the QR code shown on the other device.';

  @override
  String get transferImportCodeHint =>
      'Enter the code shown next to the QR code.';

  @override
  String get transferScanned => 'Code scanned';

  @override
  String get transferCodeField => '4-digit code';

  @override
  String get transferImportButton => 'Import';

  @override
  String get transferRescan => 'Scan again';

  @override
  String transferImported(int accounts, int groups) {
    String _temp0 = intl.Intl.pluralLogic(
      accounts,
      locale: localeName,
      other: '$accounts accounts',
      one: '1 account',
    );
    String _temp1 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups groups',
      one: '1 group',
    );
    return '$_temp0 and $_temp1 imported';
  }

  @override
  String get transferErrExpired =>
      'This code has expired. Generate a new one on the other device.';

  @override
  String get transferErrBadCode => 'Wrong code.';

  @override
  String get transferErrFailed => 'Import failed.';

  @override
  String get transferCameraDenied => 'Camera access denied';

  @override
  String get transferCameraUnavailable => 'Camera unavailable';

  @override
  String get transferCameraDeniedBody =>
      'Allow camera access in system settings to scan a transfer.';

  @override
  String get transferCameraUnavailableBody =>
      'No usable camera on this device.';

  @override
  String get groupsSubtitle =>
      'A view of some of your sites: totals and the chart only count its sites.';

  @override
  String get groupsEmptyTitle => 'No groups';

  @override
  String get groupsEmptyBody =>
      'Group your sites, such as \"Games\" or \"Clients\", to read their stats separately from the rest.';

  @override
  String get groupsCreate => 'Create a group';

  @override
  String get groupEditEditTitle => 'Edit group';

  @override
  String get groupEditName => 'Name';

  @override
  String get groupEditNameHint => 'Games, Clients, Personal…';

  @override
  String get groupEditSitesLabel => 'Group sites';

  @override
  String get groupEditAddSourceHint => 'its sites join here';

  @override
  String get groupEditNoSites =>
      'No sites tracked yet. Add a source above to fill this group.';

  @override
  String get groupEditCreateButton => 'Create group';

  @override
  String get groupEditCreated => 'Group created';

  @override
  String get groupEditSaved => 'Group saved';

  @override
  String get groupEditDeleted => 'Group deleted';

  @override
  String get groupEditDeleteTitle => 'Delete this group?';

  @override
  String get groupEditDeleteBody =>
      'Sites and their stats aren\'t affected. Only the group goes away.';

  @override
  String get addSourceNewTitle => 'New source';

  @override
  String get addSourceProvider => 'PROVIDER';

  @override
  String get addSourceName => 'Label (optional)';

  @override
  String get addSourceNameHint => 'Personal, Business…';

  @override
  String get addSourceTest => 'Test configuration';

  @override
  String get addSourceContinue => 'Continue';

  @override
  String get addSourceMissingFields => 'Fill in the required fields.';

  @override
  String get addSourceTestOk => 'Connection successful.';

  @override
  String addSourceTestOkSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Connection successful · $count sites found',
      one: 'Connection successful · 1 site found',
    );
    return '$_temp0';
  }

  @override
  String get addSourceNoSitesPlausible =>
      'No site listed automatically: your instance doesn\'t expose the listing API (Plausible Community Edition). Enter the domain to track above.';

  @override
  String get addSourceNoSites => 'No sites found for this account.';

  @override
  String get addSourceKeyRejected =>
      'API key rejected (stats access). Check the API key.';

  @override
  String get addSourceCredsRejected => 'Credentials rejected.';

  @override
  String get addSourceUmamiHosting => 'HOSTING';

  @override
  String get addSourceUmamiSelfHosted => 'Self-hosted';

  @override
  String get addSourceUmamiCloudUseKey =>
      'Umami Cloud connects with an API key: choose “Umami Cloud” above.';

  @override
  String get addSourceAdded => 'Source added';

  @override
  String get addSourceEdited => 'Source updated';

  @override
  String get sitePickerTitle => 'Choose sites';

  @override
  String sitePickerDetected(String provider, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites found',
      one: '1 site found',
    );
    return '$provider · $_temp0';
  }

  @override
  String get sitePickerFollowNew => 'Show new sites';

  @override
  String get sitePickerFollowNewHint =>
      'A site created later shows up on its own';

  @override
  String get sitePickerCurrent => 'Current sites';

  @override
  String sitePickerShownOf(int shown, int total) {
    return '$shown of $total';
  }

  @override
  String get sitePickerCheckAll => 'Select all';

  @override
  String get sitePickerUncheckAll => 'Deselect all';

  @override
  String get sitePickerFollowAll => 'Follow all sites';

  @override
  String sitePickerFollowAndNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Follow $count sites and new ones',
      one: 'Follow 1 site and new ones',
    );
    return '$_temp0';
  }

  @override
  String sitePickerFollow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Follow $count sites',
      one: 'Follow 1 site',
    );
    return '$_temp0';
  }

  @override
  String get sitePickerShowNone => 'Show no sites';

  @override
  String get commonVisitors => 'Visitors';

  @override
  String get commonPageviews => 'Pageviews';

  @override
  String get commonNoData => 'No data';

  @override
  String desktopSitesHeader(int count) {
    return 'Sites ($count)';
  }

  @override
  String desktopHiddenCount(int count) {
    return '$count hidden';
  }

  @override
  String get desktopShowAllSites => 'Show all sites';

  @override
  String get desktopHideEmptySites => 'Hide sites with no visitors';

  @override
  String get desktopLiveNobody => 'Nobody right now.';

  @override
  String get desktopKpiSites => 'Sites';

  @override
  String desktopNoSitesGroupBody(String name) {
    return '\"$name\" has no sites. Choose which ones belong to it.';
  }

  @override
  String get desktopNoSitesBody =>
      'Your accounts aren\'t tracking any sites yet. Pick the sites to show from settings.';

  @override
  String get chartLegendForecast => 'Forecast';

  @override
  String get chartLegendPrevious => 'Previous period';

  @override
  String get chartTooltipVisitors => 'visitors';

  @override
  String get chartTooltipPageviews => 'pageviews';

  @override
  String get chartTooltipForecast => 'forecast';

  @override
  String get chartTooltipPrevious => 'previous period';

  @override
  String get chartNoSeries => 'No series selected';

  @override
  String chartHour(String hour) {
    return '$hour:00';
  }

  @override
  String get periodControlsDisplay => 'Display';

  @override
  String get periodControlsSplit => 'Group by';

  @override
  String get periodControlsChart => 'Chart';

  @override
  String get periodUnitHour => 'Hour';

  @override
  String get periodUnitDay => 'Day';

  @override
  String get periodUnitMonth => 'Month';

  @override
  String get errorsAuthRefused => 'Credentials rejected.';

  @override
  String get errorsRequestRefused => 'Request rejected by the server.';

  @override
  String get errorsNotFound => 'Instance or API not found.';

  @override
  String get errorsTimeout =>
      'Timed out — the instance is slow or unreachable.';

  @override
  String get errorsUnreachable => 'Instance unreachable. Check the URL.';

  @override
  String errorsServerCode(int code) {
    return 'Server error $code.';
  }

  @override
  String get errorsConnectionFailed => 'Couldn\'t connect.';

  @override
  String errorsGeneric(String detail) {
    return 'Error: $detail';
  }

  @override
  String get errUnsupportedIndicators => 'Indicators not supported';

  @override
  String get errUnsupportedSiteTables => 'Site tables not supported';

  @override
  String get errUnsupportedFunnels => 'Funnels not supported';

  @override
  String get errUnsupportedBreakdowns => 'Breakdowns not supported';

  @override
  String errOperatorUmamiFunnel(String op) {
    return 'Operator “$op” isn\'t available in an Umami funnel';
  }

  @override
  String errOperatorPlausible(String op) {
    return 'Operator “$op” isn\'t available on Plausible (text properties only)';
  }

  @override
  String get errFathomSoon => 'Fathom is coming soon.';

  @override
  String get errPlausibleNeedsSite =>
      'Enter a domain, or an email and password to list your sites automatically.';

  @override
  String get errUmamiLoginUnexpected => 'Unexpected Umami login response';

  @override
  String errBucketsTooFine(int count) {
    return 'Split too fine: more than $count points over the period.';
  }

  @override
  String get errMetricsNotConfigured => 'Source not configured on the server';

  @override
  String get errMetricsBadToken => 'Token rejected';

  @override
  String errMetricsBadRequest(String code) {
    return 'Request rejected ($code)';
  }

  @override
  String get errMetricsUnsupportedVersion => 'API version not supported';

  @override
  String get errMetricsUnexpected => 'Unexpected response from the server';

  @override
  String get syncMsgUnreachable => 'Server unreachable. Try again.';

  @override
  String get syncMsgSessionExpired =>
      'Session expired. Sign in again, then retry.';

  @override
  String get syncMsgPurchaseFailed => 'Purchase failed. Try again.';

  @override
  String get syncMsgPurchasePending =>
      'Purchase confirmed — activation in progress, retry the sync in a moment.';

  @override
  String get syncMsgNothingToRestore => 'No purchase to restore.';

  @override
  String get syncMsgRestorePending =>
      'Purchase restored — activation in progress…';

  @override
  String get syncMsgCannotDecrypt => 'Couldn\'t decrypt the remote config.';

  @override
  String get syncMsgProRequired => 'Sync is reserved for Glance Sync (Pro).';

  @override
  String get syncMsgBadCredentials => 'Wrong email or password.';

  @override
  String syncMsgPasswordTooShort(int count) {
    return 'Password too short: $count characters minimum.';
  }

  @override
  String get syncMsgPasswordTooLong => 'Password too long.';

  @override
  String get syncMsgInvalidEmail => 'Invalid email address.';

  @override
  String get syncMsgAccountExists =>
      'This email already has an account: sign in instead.';

  @override
  String get syncMsgSignUpFailed => 'Couldn\'t create the account.';

  @override
  String get periodToday => 'Today';

  @override
  String get period24h => '24 h';

  @override
  String get period7d => '7 days';

  @override
  String get period30d => '30 d';

  @override
  String get periodThisMonth => 'This month';

  @override
  String get period12m => '12 mo';

  @override
  String get periodThisYear => 'This year';

  @override
  String get periodAllTime => 'All';

  @override
  String get periodCustom => 'Custom';

  @override
  String get metricTypePages => 'Paths';

  @override
  String get metricTypeEntry => 'Entry';

  @override
  String get metricTypeExit => 'Exit';

  @override
  String get metricTypeTitle => 'Title';

  @override
  String get metricTypeReferrers => 'Referrers';

  @override
  String get metricTypeChannels => 'Channels';

  @override
  String get metricTypeQueries => 'Queries';

  @override
  String get metricTypeBrowsers => 'Browsers';

  @override
  String get metricTypeOs => 'OS';

  @override
  String get metricTypeDevices => 'Devices';

  @override
  String get metricTypeScreens => 'Screens';

  @override
  String get metricTypeCountries => 'Countries';

  @override
  String get metricTypeRegions => 'Regions';

  @override
  String get metricTypeCities => 'Cities';

  @override
  String get metricTypeLanguages => 'Languages';

  @override
  String get metricTypeEvents => 'Events';

  @override
  String get metricSectionPages => 'Pages';

  @override
  String get metricSectionSources => 'Sources';

  @override
  String get metricSectionEnvironment => 'Environment';

  @override
  String get metricSectionLocation => 'Location';

  @override
  String get filterOpContains => 'contains';

  @override
  String get filterOpNotContains => 'doesn\'t contain';

  @override
  String get entityUnknown => 'Unknown';

  @override
  String get entityReferrerDirect => 'Direct';

  @override
  String get entityBrowserSearchBot => 'Search bot';

  @override
  String get entityDeviceDesktop => 'Desktop';

  @override
  String get entityDeviceLaptop => 'Laptop';

  @override
  String get entityDeviceTablet => 'Tablet';

  @override
  String get entityDeviceMobile => 'Mobile';

  @override
  String get entityDeviceWearable => 'Watch';

  @override
  String get entityDeviceConsole => 'Console';

  @override
  String get entityDeviceTv => 'TV';

  @override
  String get channelDirect => 'Direct';

  @override
  String get channelReferral => 'Referral';

  @override
  String get channelAffiliate => 'Affiliate';

  @override
  String get channelEmail => 'Email';

  @override
  String get channelOrganicSearch => 'Organic search';

  @override
  String get channelOrganicSocial => 'Organic social';

  @override
  String get channelOrganicShopping => 'Organic shopping';

  @override
  String get channelOrganicVideo => 'Organic video';

  @override
  String get channelPaidAds => 'Paid ads';

  @override
  String get channelPaidSearch => 'Paid search';

  @override
  String get channelPaidSocial => 'Paid social';

  @override
  String get channelPaidShopping => 'Paid shopping';

  @override
  String get channelPaidVideo => 'Paid video';

  @override
  String get credInstanceUrl => 'Instance URL';

  @override
  String get credUmamiUrlPlaceholder => 'analytics.yourdomain.com';

  @override
  String get credUsername => 'Username';

  @override
  String get credPassword => 'Password';

  @override
  String get credApiKey => 'API key';

  @override
  String get credUmamiCloudKeyHint =>
      'Create one in Umami Cloud: Settings → API keys. API access requires a Pro plan.';

  @override
  String get credEmailOptional => 'Account email (optional)';

  @override
  String get credEmailPlaceholder => 'you@example.com';

  @override
  String get credEmailHint =>
      'Email + password: Glance lists your sites automatically. Otherwise, leave blank and enter a domain below.';

  @override
  String get credPasswordOptional => 'Password (optional)';

  @override
  String get credDomainFallback => 'Domain (if no email/password)';

  @override
  String get credDomainPlaceholder => 'yourdomain.com';
}
