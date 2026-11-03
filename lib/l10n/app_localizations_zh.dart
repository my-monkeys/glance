// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get settingsLanguageTitle => '语言';

  @override
  String get settingsLanguageAuto => '自动';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get commonClose => '关闭';

  @override
  String get commonClear => '清除';

  @override
  String get commonRetry => '重试';

  @override
  String get tabSites => '站点';

  @override
  String get tabDirect => '实时';

  @override
  String get tabSettings => '设置';

  @override
  String get siteSearchHint => '搜索站点';

  @override
  String siteSearchNoMatch(String query) {
    return '没有与“$query”匹配的站点。';
  }

  @override
  String get navToday => '今天';

  @override
  String get navYesterday => '昨天';

  @override
  String get navDayBeforeYesterday => '前天';

  @override
  String get navThisMonth => '本月';

  @override
  String get navLastMonth => '上月';

  @override
  String get navThisYear => '今年';

  @override
  String get navLastYear => '去年';

  @override
  String get workspaceSheetTitle => '范围';

  @override
  String get workspaceAllSites => '所有站点';

  @override
  String workspaceTrackedSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已跟踪 $count 个站点',
    );
    return '$_temp0';
  }

  @override
  String workspaceSiteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个站点',
      zero: '无站点',
    );
    return '$_temp0';
  }

  @override
  String get workspaceNewGroup => '新建分组';

  @override
  String get workspaceManageGroups => '管理分组';

  @override
  String get homeTitleDefault => '我的站点';

  @override
  String get homeLoadFailed => '无法加载。';

  @override
  String get homeInternalTitle => '站点之间';

  @override
  String homeTotalVisitors(String name) {
    return '访客 · $name';
  }

  @override
  String get homeTotalVisitorsAll => '访客 · 所有站点';

  @override
  String get homeVsPrevious => '较上一时期';

  @override
  String homeLiveCount(int count) {
    return '$count 人在线';
  }

  @override
  String get homeEmptyTitle => '没有显示站点';

  @override
  String get homeEmptyBody => '尚未跟踪任何站点，请选择要显示的站点。';

  @override
  String get homeEmptyChooseSites => '选择站点';

  @override
  String get homeEmptyAddSource => '+ 添加数据源';

  @override
  String get homeEmptyGroupTitle => '空分组';

  @override
  String homeEmptyGroupBody(String name) {
    return '“$name”中没有站点。';
  }

  @override
  String get homeEmptyGroupChoose => '选择站点';

  @override
  String get homeEmptyGroupSeeAll => '查看所有站点';

  @override
  String get homeWelcomeTagline => '您的统计数据，一目了然。';

  @override
  String get homeWelcomeTitle => '连接您的第一个工具';

  @override
  String get homeWelcomeBody => 'Umami、Plausible……添加数据源，然后选择要跟踪的站点。';

  @override
  String get homeWelcomeAddSource => '添加数据源';

  @override
  String get homeWelcomeFootnote => '只读密钥 · 数据由您自己掌握';

  @override
  String get homeSiteUnavailable => '不可用';

  @override
  String get detailVisitorsUnique => '独立访客';

  @override
  String get detailKpiVisits => '访问次数';

  @override
  String get detailKpiAvgDuration => '平均时长';

  @override
  String get detailKpiBounce => '跳出率';

  @override
  String get detailLiveNow => '当前在线';

  @override
  String get detailLiveNobody => '目前没有人。';

  @override
  String get detailTabOverview => '概览';

  @override
  String get detailTabEvents => '事件';

  @override
  String get detailTabDashboards => '仪表盘';

  @override
  String get detailEventsEmpty => '此时段没有事件';

  @override
  String get detailEventsTriggered => '触发的事件';

  @override
  String get detailEventsByEvent => '按事件';

  @override
  String detailSectionViewAll(int count) {
    return '查看全部 $count 行';
  }

  @override
  String get detailBadgeInternal => '内部';

  @override
  String get directEyebrow => '实时';

  @override
  String get directTitle => '实时';

  @override
  String get directNow => '此刻';

  @override
  String get directVisitorsAll => '位访客分布在您的所有站点';

  @override
  String directVisitorsGroup(String name) {
    return '位访客在“$name”分组中';
  }

  @override
  String get directBySite => '按站点';

  @override
  String get directOnlyActive => '仅看活跃';

  @override
  String get directNoneLive => '目前没有在线访客。';

  @override
  String get directNoSites => '没有站点。';

  @override
  String directHiddenSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已隐藏 $count 个无访客的站点',
    );
    return '$_temp0';
  }

  @override
  String networkExchanged(String period) {
    return '互相导流的访客 · $period';
  }

  @override
  String networkPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个站点加载中…',
    );
    return '$_temp0';
  }

  @override
  String get networkExplainer => '从您的某个站点跳转到另一个站点的访客。';

  @override
  String get networkEmpty => '此时段没有站内跳转。';

  @override
  String get networkSenders => '导出方';

  @override
  String get networkReceivers => '接收方';

  @override
  String get networkFlows => '流向';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonDelete => '删除';

  @override
  String get commonSave => '保存';

  @override
  String get dashboardsKindCounter => '计数';

  @override
  String get dashboardsKindRatio => '比率';

  @override
  String get dashboardsKindFunnel => '漏斗';

  @override
  String get dashboardsKindBreakdown => '分布';

  @override
  String get dashboardsKindExternal => '指标';

  @override
  String get dashboardsKindSites => '站点';

  @override
  String get dashboardsMoveCard => '移动卡片';

  @override
  String get dashboardsCardOptions => '卡片选项';

  @override
  String get dashboardsResizeCard => '调整卡片大小';

  @override
  String get dashboardsLoadFailed => '无法加载。';

  @override
  String get dashboardsNoData => '此时段没有数据';

  @override
  String get dashboardsNoEvents => '此时段没有事件';

  @override
  String dashboardsUnpublished(String date) {
    return '尚未发布：数据截至 $date';
  }

  @override
  String get dashboardsPendingNow => '此时段暂时无法测量';

  @override
  String dashboardsPendingDelay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '暂时无法测量：需要再等 $count 天',
    );
    return '$_temp0';
  }

  @override
  String dashboardsCohortOne(String date) {
    return '按 $date 的同期群测得';
  }

  @override
  String dashboardsCohortRange(String range) {
    return '按 $range 的同期群测得';
  }

  @override
  String dashboardsFamilyMember(String member) {
    return '$member · 随时段自动调整';
  }

  @override
  String dashboardsDataUntil(String date) {
    return '数据截至 $date';
  }

  @override
  String dashboardsFunnelVisitors(String last, String first) {
    return '$last / $first 位访客';
  }

  @override
  String dashboardsCohortTooltip(String date, String cohort) {
    return '$date · $cohort 的同期群';
  }

  @override
  String get dashboardsTotal => '总计';

  @override
  String dashboardsSegmentEstimated(String label) {
    return '$label · 估算';
  }

  @override
  String get dashboardsDeleted => '卡片已删除';

  @override
  String get dashboardsConfirmDelete => '确认删除';

  @override
  String get dashboardsAllHidden => '此时段没有卡片有数据';

  @override
  String dashboardsHiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张卡片在此时段没有数据',
    );
    return '$_temp0';
  }

  @override
  String get dashboardsShow => '显示';

  @override
  String get dashboardsArrangeHint => '长按卡片可移动，拖动卡片一角可调整大小。';

  @override
  String get dashboardsArrange => '排列';

  @override
  String get dashboardsArrangeDone => '完成';

  @override
  String get dashboardsNew => '新建卡片';

  @override
  String get dashboardsEmptyTitle => '还没有卡片';

  @override
  String get dashboardsEmptyBody => '基于您的事件，跟踪比率、漏斗或分布。';

  @override
  String get dashboardsCreate => '创建卡片';

  @override
  String get dashboardsMetricsSource => '指标数据源';

  @override
  String get dashboardsMetricsIntro =>
      '您站点上的一个小型 API，提供基于其数据库计算的指标（留存、账户数等）：包含目录和序列，并由令牌保护。';

  @override
  String get dashboardsMetricsHowItWorks => '它是如何工作的？';

  @override
  String get dashboardsMetricsUrlLabel => 'API 地址';

  @override
  String get dashboardsMetricsUrlHint =>
      'https://example.com/api/internal/metrics/';

  @override
  String get dashboardsMetricsToken => '令牌';

  @override
  String get dashboardsMetricsTest => '测试';

  @override
  String dashboardsMetricsAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个可用指标',
    );
    return '$_temp0';
  }

  @override
  String get dashboardsMetricsSaved => '数据源已保存';

  @override
  String get dashboardsMetricsRemove => '移除数据源';

  @override
  String dashboardsMetricsRemoveWithCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '移除数据源和 $count 张卡片',
    );
    return '$_temp0';
  }

  @override
  String get dashboardsMetricsRemoved => '数据源已移除';

  @override
  String dashboardsMetricsRemovedWithCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '数据源已移除，$count 张卡片已删除',
    );
    return '$_temp0';
  }

  @override
  String get commonCancel => '取消';

  @override
  String get commonAdd => '添加';

  @override
  String get commonSearch => '搜索';

  @override
  String get editorNameFallback => '未命名';

  @override
  String editorNameBy(String a, String b) {
    return '$a（按 $b）';
  }

  @override
  String get editorErrChooseEvent => '请选择事件';

  @override
  String get editorErrChooseCountEvent => '请选择要计数的事件';

  @override
  String get editorErrChooseRefEvent => '请选择参照事件';

  @override
  String get editorErrChooseProperty => '请选择属性';

  @override
  String get editorErrChooseMetric => '请选择指标';

  @override
  String get editorErrAddSite => '请至少添加一个站点';

  @override
  String editorErrSitesMax(int max) {
    return '一张卡片最多包含 $max 个站点';
  }

  @override
  String get editorErrChooseLineSite => '请为每一行选择站点';

  @override
  String get editorErrNameLines => '请为每一行命名';

  @override
  String get editorErrReferrer => '请输入来源域名';

  @override
  String editorErrFunnelMin(int min) {
    return '漏斗至少需要 $min 个步骤';
  }

  @override
  String editorErrFunnelMax(int max) {
    return '漏斗最多只能有 $max 个步骤';
  }

  @override
  String editorErrStepEvent(int n) {
    return '请选择第 $n 步的事件';
  }

  @override
  String get editorErrFunnelNumeric => '漏斗无法比较数值：请移除此筛选器';

  @override
  String get editorErrWindow => '时间限制无效';

  @override
  String get editorErrFilterValueMissing => '缺少筛选值';

  @override
  String get editorErrFilterNotNumber => '筛选值不是数字';

  @override
  String get editorTitleEdit => '编辑卡片';

  @override
  String get editorFieldName => '名称';

  @override
  String get editorHeadingType => '类型';

  @override
  String get editorHeadingPreview => '预览';

  @override
  String get editorPreviewEmpty => '卡片设置完整后将显示预览。';

  @override
  String get editorCreated => '卡片已创建';

  @override
  String get editorSaved => '卡片已保存';

  @override
  String get editorDelete => '删除此卡片';

  @override
  String get editorCreate => '创建';

  @override
  String get editorCountLabel => '统计内容';

  @override
  String get editorRatioOf => '相对于';

  @override
  String get editorGapsLabel => '无事件发生时留空';

  @override
  String get editorGapsHint => '否则这些日期将按 0% 计算。';

  @override
  String get editorOverTimeLabel => '随时间变化';

  @override
  String get editorOverTimeHint => '每个值一条曲线，占满整行宽度';

  @override
  String get editorMetricLabel => '指标';

  @override
  String get editorMetricPlaceholder => '选择指标';

  @override
  String get editorMetricNone => '此数据源没有提供任何指标。';

  @override
  String get editorMetricAdjusts => '随时段自动调整';

  @override
  String get editorEventLabel => '事件';

  @override
  String get editorEventPlaceholder => '选择事件';

  @override
  String get editorPropertyLabel => '属性';

  @override
  String get editorPropertyPlaceholder => '选择属性';

  @override
  String get editorKindExternal => '站点指标';

  @override
  String get editorKindHintCounter => '某个事件发生的次数';

  @override
  String get editorKindHintRatio => '一个事件相对于另一个事件';

  @override
  String get editorKindHintFunnel => '逐步查看访客路径';

  @override
  String get editorKindHintBreakdown => '某个属性的各个值';

  @override
  String get editorKindHintExternal => '由您的 API 提供的指标';

  @override
  String get editorKindHintSites => '多个站点的访客';

  @override
  String get editorFunnelAddStep => '添加步骤';

  @override
  String get editorFunnelWindowLabel => '两步之间的最长时间';

  @override
  String editorFunnelWindowHint(int min, int max) {
    return '单位为分钟（$min 到 $max）：从一步到下一步耗时更长的访客将不再计入。';
  }

  @override
  String editorFunnelStep(int n) {
    return '第 $n 步';
  }

  @override
  String get editorFunnelMoveUp => '上移步骤';

  @override
  String get editorFunnelMoveDown => '下移步骤';

  @override
  String get editorFunnelRemove => '移除步骤';

  @override
  String get editorTypeText => '文本';

  @override
  String get editorTypeNumber => '数字';

  @override
  String get editorTypeBoolean => '是/否';

  @override
  String get editorFreeEvent => '输入事件名称';

  @override
  String get editorFreeProperty => '输入属性名称';

  @override
  String get editorSiteLabel => '站点';

  @override
  String editorUseTyped(String value) {
    return '使用“$value”';
  }

  @override
  String get editorListUnavailable => '列表不可用，请手动输入名称。';

  @override
  String get editorListEmpty => '30 天内没有记录，请手动输入名称。';

  @override
  String get editorAddFilter => '添加筛选器';

  @override
  String get editorRemoveFilter => '移除筛选器';

  @override
  String get editorFilterValue => '值';

  @override
  String get editorTrue => '真';

  @override
  String get editorFalse => '假';

  @override
  String get editorModeAll => '全部';

  @override
  String get editorModeOnly => '来自';

  @override
  String get editorModeExcept => '不含来自';

  @override
  String get editorLineSitePlaceholder => '选择站点';

  @override
  String get editorLineLabel => '标签';

  @override
  String get editorLineReferrer => '来源域名';

  @override
  String get editorLineAdd => '添加站点';

  @override
  String get editorLinesHint => '每行显示独立访客数。“不含来自”会去掉该站点从此域名获得的访客。';

  @override
  String editorLineTitle(int n) {
    return '第 $n 行';
  }

  @override
  String get editorLineRemove => '移除此行';

  @override
  String commonSiteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个站点',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsGroupAccount => '账户';

  @override
  String get settingsGroupSites => '站点';

  @override
  String get settingsGroupSync => '同步';

  @override
  String get settingsGroupTransfer => '迁移';

  @override
  String get settingsGroupAppearance => '外观';

  @override
  String get settingsGroupData => '数据';

  @override
  String get settingsGroupApp => '应用';

  @override
  String get settingsAccountBadAuth => '凭据或 API 密钥被拒绝';

  @override
  String get settingsAccountUnreachable => '无法连接实例';

  @override
  String settingsAccountSubtitle(String provider, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个站点',
    );
    return '$provider · $_temp0';
  }

  @override
  String get settingsAddSource => '添加数据源';

  @override
  String get settingsGroupsTitle => '分组';

  @override
  String get settingsGroupsHint => '单独查看一部分站点';

  @override
  String get settingsSyncConnected => '已登录';

  @override
  String get settingsSyncPitch => '备份并同步（加密）';

  @override
  String get settingsTransferShow => '显示迁移二维码';

  @override
  String get settingsTransferNone => '没有可迁移的账户';

  @override
  String get settingsTransferContents => '账户、凭据和分组';

  @override
  String get settingsTransferImport => '从其他设备导入';

  @override
  String get settingsTransferScan => '扫描迁移二维码';

  @override
  String get settingsThemeTitle => '主题';

  @override
  String get settingsThemeAuto => '自动';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsChartsTitle => '图表';

  @override
  String get settingsChartsHint => '平滑曲线或柱状图';

  @override
  String get settingsChartCurve => '曲线';

  @override
  String get settingsChartBars => '柱状';

  @override
  String get settingsDefaultPeriod => '默认时段';

  @override
  String get settingsDefaultPeriodHint => '应用打开时';

  @override
  String get settingsRefresh => '自动刷新';

  @override
  String settingsRefreshSeconds(int count) {
    return '$count 秒';
  }

  @override
  String settingsRefreshMinutes(int count) {
    return '$count 分钟';
  }

  @override
  String get settingsCheckUpdates => '检查更新';

  @override
  String get accountMenuConnectionOk => '连接成功';

  @override
  String accountMenuConnectionOkSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '连接成功 · $count 个站点',
    );
    return '$_temp0';
  }

  @override
  String get accountMenuTest => '测试连接';

  @override
  String get accountMenuEdit => '编辑数据源';

  @override
  String get accountMenuEditHint => 'URL、凭据、API 密钥……';

  @override
  String get accountMenuChooseSites => '选择站点';

  @override
  String get accountMenuDelete => '删除此账户';

  @override
  String get accountMenuDeleted => '数据源已删除';

  @override
  String get accountMenuSelectionSaved => '选择已保存';

  @override
  String get accountSelectionAll => '所有站点';

  @override
  String accountSelectionAllExcept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '除 $count 个站点外的所有站点',
    );
    return '$_temp0';
  }

  @override
  String get accountSelectionNone => '无站点';

  @override
  String get syncSubtitle => '您的账户和分组，经加密同步。';

  @override
  String get syncEmail => '邮箱';

  @override
  String get syncEmailHint => 'you@example.com';

  @override
  String get syncPassword => '密码';

  @override
  String syncPasswordHint(int count) {
    return '至少 $count 个字符';
  }

  @override
  String get syncCreateAccount => '创建账户';

  @override
  String get syncCreateAccountButton => '创建账户';

  @override
  String get syncSignIn => '登录';

  @override
  String get syncHaveAccount => '我已有账户';

  @override
  String get syncEncryptedNote => '您的配置在发送前已在设备上加密，服务器无法读取。忘记密码，同步数据将永久无法找回。';

  @override
  String get syncToastCreated => '账户已创建';

  @override
  String get syncToastSignedIn => '已登录';

  @override
  String get syncToastSignedOut => '已退出登录';

  @override
  String get syncToastSynced => '已同步';

  @override
  String get syncToastDeleted => '账户已删除';

  @override
  String get syncToastUnlocked => 'Glance Sync 已解锁';

  @override
  String get syncToastRestored => '购买已恢复';

  @override
  String get syncNever => '从未同步';

  @override
  String syncLastSync(String date) {
    return '$date已同步';
  }

  @override
  String get syncNow => '立即同步';

  @override
  String get syncSignOut => '退出登录';

  @override
  String get syncDeleteAccount => '删除我的账户';

  @override
  String get syncDeleteTitle => '删除账户？';

  @override
  String get syncDeleteBody =>
      '您的 Glance Sync 账户及所有已同步的配置将从服务器上永久删除，且无法撤销。您的统计数据源仍保留在此设备上。';

  @override
  String get syncUnlockTitle => '解锁 Glance Sync';

  @override
  String get syncUnlockBuy => '在您的所有设备间备份并同步账户和分组。一次性购买。';

  @override
  String get syncUnlockElsewhere =>
      '请在移动端应用（iOS/Android）中一次性购买。解锁后，在此使用同一账户登录，同步将自动进行。';

  @override
  String get syncUnlockButton => '解锁';

  @override
  String get syncRestore => '恢复购买';

  @override
  String get syncSoon => '即将推出';

  @override
  String get transferExportTitle => '迁移';

  @override
  String get transferExportSubtitle => '请用另一台设备扫描此二维码。';

  @override
  String transferExpiresIn(String time) {
    return '$time后过期';
  }

  @override
  String get transferCodeLabel => '请在另一台设备上输入的验证码';

  @override
  String get transferWarning =>
      '此二维码包含您的凭据，请勿拍照或分享：仅有二维码无法使用，但与 4 位验证码一起即可访问您的账户。';

  @override
  String get transferExpiredTitle => '二维码已过期';

  @override
  String get transferExpiredBody => '迁移仅在几分钟内有效。';

  @override
  String get transferRegenerate => '重新生成';

  @override
  String get transferTooLargeTitle => '配置过大';

  @override
  String transferTooLargeBody(int size, int max) {
    return '无法放入二维码（$size 个字符，上限 $max 个）。请在账户中选择“所有站点”而非手动选择，然后重试。';
  }

  @override
  String get transferFailedTitle => '迁移失败';

  @override
  String get transferFailedBody => '无法准备迁移。';

  @override
  String get transferImportTitle => '导入';

  @override
  String get transferImportScanHint => '请对准另一台设备上显示的二维码。';

  @override
  String get transferImportCodeHint => '请输入二维码旁显示的验证码。';

  @override
  String get transferScanned => '已扫描二维码';

  @override
  String get transferCodeField => '4 位验证码';

  @override
  String get transferImportButton => '导入';

  @override
  String get transferRescan => '重新扫描';

  @override
  String transferImported(int accounts, int groups) {
    String _temp0 = intl.Intl.pluralLogic(
      accounts,
      locale: localeName,
      other: '$accounts 个账户',
    );
    String _temp1 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups 个分组',
    );
    return '已导入 $_temp0和 $_temp1';
  }

  @override
  String get transferErrExpired => '此二维码已过期，请在另一台设备上重新生成。';

  @override
  String get transferErrBadCode => '验证码错误。';

  @override
  String get transferErrFailed => '导入失败。';

  @override
  String get transferCameraDenied => '相机访问被拒绝';

  @override
  String get transferCameraUnavailable => '相机不可用';

  @override
  String get transferCameraDeniedBody => '请在系统设置中允许访问相机，以扫描迁移二维码。';

  @override
  String get transferCameraUnavailableBody => '此设备上没有可用的相机。';

  @override
  String get groupsSubtitle => '您部分站点的视图：总数和图表只统计其中的站点。';

  @override
  String get groupsEmptyTitle => '没有分组';

  @override
  String get groupsEmptyBody => '将站点分组，例如“游戏”或“客户”，即可单独查看它们的统计数据。';

  @override
  String get groupsCreate => '创建分组';

  @override
  String get groupEditEditTitle => '编辑分组';

  @override
  String get groupEditName => '名称';

  @override
  String get groupEditNameHint => '游戏、客户、个人……';

  @override
  String get groupEditSitesLabel => '分组站点';

  @override
  String get groupEditAddSourceHint => '其站点将加入此处';

  @override
  String get groupEditNoSites => '尚未跟踪任何站点。请先在上方添加数据源，再填充此分组。';

  @override
  String get groupEditCreateButton => '创建分组';

  @override
  String get groupEditCreated => '分组已创建';

  @override
  String get groupEditSaved => '分组已保存';

  @override
  String get groupEditDeleted => '分组已删除';

  @override
  String get groupEditDeleteTitle => '删除此分组？';

  @override
  String get groupEditDeleteBody => '站点及其统计数据不受影响，只会删除分组本身。';

  @override
  String get addSourceNewTitle => '新建数据源';

  @override
  String get addSourceProvider => '服务商';

  @override
  String get addSourceName => '名称（可选）';

  @override
  String get addSourceNameHint => '我的域名';

  @override
  String get addSourceTest => '测试配置';

  @override
  String get addSourceContinue => '继续';

  @override
  String get addSourceMissingFields => '请填写必填项。';

  @override
  String get addSourceTestOk => '连接成功。';

  @override
  String addSourceTestOkSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '连接成功 · 找到 $count 个站点',
    );
    return '$_temp0';
  }

  @override
  String get addSourceNoSitesPlausible =>
      '未能自动列出站点：您的实例没有开放站点列表 API（Plausible 社区版）。请在上方输入要跟踪的域名。';

  @override
  String get addSourceNoSites => '此账户下没有找到站点。';

  @override
  String get addSourceKeyRejected => 'API 密钥被拒绝（统计访问权限）。请检查 API 密钥。';

  @override
  String get addSourceCredsRejected => '凭据被拒绝。';

  @override
  String get addSourceUmamiHosting => '托管方式';

  @override
  String get addSourceUmamiSelfHosted => '自托管';

  @override
  String get addSourceUmamiCloudUseKey =>
      'Umami Cloud 使用 API 密钥连接：请在上方选择“Umami Cloud”。';

  @override
  String get addSourceAdded => '数据源已添加';

  @override
  String get addSourceEdited => '数据源已更新';

  @override
  String get sitePickerTitle => '选择站点';

  @override
  String sitePickerDetected(String provider, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '找到 $count 个站点',
    );
    return '$provider · $_temp0';
  }

  @override
  String get sitePickerFollowNew => '显示新站点';

  @override
  String get sitePickerFollowNewHint => '日后创建的站点会自动显示';

  @override
  String get sitePickerCurrent => '当前站点';

  @override
  String sitePickerShownOf(int shown, int total) {
    return '$shown / $total';
  }

  @override
  String get sitePickerCheckAll => '全选';

  @override
  String get sitePickerUncheckAll => '取消全选';

  @override
  String get sitePickerFollowAll => '跟踪所有站点';

  @override
  String sitePickerFollowAndNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '跟踪 $count 个站点及新站点',
    );
    return '$_temp0';
  }

  @override
  String sitePickerFollow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '跟踪 $count 个站点',
    );
    return '$_temp0';
  }

  @override
  String get sitePickerShowNone => '不显示任何站点';

  @override
  String get commonVisitors => '访客';

  @override
  String get commonPageviews => '浏览量';

  @override
  String get commonNoData => '无数据';

  @override
  String desktopSitesHeader(int count) {
    return '站点（$count）';
  }

  @override
  String desktopHiddenCount(int count) {
    return '已隐藏 $count 个';
  }

  @override
  String get desktopShowAllSites => '显示所有站点';

  @override
  String get desktopHideEmptySites => '隐藏没有访客的站点';

  @override
  String get desktopLiveNobody => '目前没有人。';

  @override
  String get desktopKpiSites => '站点';

  @override
  String desktopNoSitesGroupBody(String name) {
    return '“$name”中没有站点，请选择要加入的站点。';
  }

  @override
  String get desktopNoSitesBody => '您的账户尚未跟踪任何站点。请在设置中选择要显示的站点。';

  @override
  String get chartLegendForecast => '预测';

  @override
  String get chartLegendPrevious => '上一时期';

  @override
  String get chartTooltipVisitors => '访客';

  @override
  String get chartTooltipPageviews => '浏览量';

  @override
  String get chartTooltipForecast => '预测';

  @override
  String get chartTooltipPrevious => '上一时期';

  @override
  String get chartNoSeries => '未选择任何数据系列';

  @override
  String chartHour(String hour) {
    return '$hour:00';
  }

  @override
  String get periodControlsDisplay => '显示';

  @override
  String get periodControlsSplit => '分组方式';

  @override
  String get periodControlsChart => '图表';

  @override
  String get periodUnitHour => '小时';

  @override
  String get periodUnitDay => '日';

  @override
  String get periodUnitMonth => '月';

  @override
  String get errorsAuthRefused => '凭据被拒绝。';

  @override
  String get errorsRequestRefused => '请求被服务器拒绝。';

  @override
  String get errorsNotFound => '找不到实例或 API。';

  @override
  String get errorsTimeout => '请求超时：实例响应缓慢或无法访问。';

  @override
  String get errorsUnreachable => '无法访问实例，请检查 URL。';

  @override
  String errorsServerCode(int code) {
    return '服务器错误 $code。';
  }

  @override
  String get errorsConnectionFailed => '无法连接。';

  @override
  String errorsGeneric(String detail) {
    return '错误：$detail';
  }

  @override
  String get errUnsupportedIndicators => '不支持指标';

  @override
  String get errUnsupportedSiteTables => '不支持站点表格';

  @override
  String get errUnsupportedFunnels => '不支持漏斗';

  @override
  String get errUnsupportedBreakdowns => '不支持分布';

  @override
  String errOperatorUmamiFunnel(String op) {
    return 'Umami 漏斗不支持运算符“$op”';
  }

  @override
  String errOperatorPlausible(String op) {
    return 'Plausible 不支持运算符“$op”（仅支持文本属性）';
  }

  @override
  String get errFathomSoon => 'Fathom 即将支持。';

  @override
  String get errPlausibleNeedsSite => '请输入域名，或输入邮箱和密码以自动列出您的站点。';

  @override
  String get errUmamiLoginUnexpected => 'Umami 登录响应异常';

  @override
  String errBucketsTooFine(int count) {
    return '分组过细：此时段内超过 $count 个数据点。';
  }

  @override
  String get errMetricsNotConfigured => '服务器上未配置该数据源';

  @override
  String get errMetricsBadToken => '令牌被拒绝';

  @override
  String errMetricsBadRequest(String code) {
    return '请求被拒绝（$code）';
  }

  @override
  String get errMetricsUnsupportedVersion => '不支持该 API 版本';

  @override
  String get errMetricsUnexpected => '服务器响应异常';

  @override
  String get syncMsgUnreachable => '无法访问服务器，请重试。';

  @override
  String get syncMsgSessionExpired => '登录已过期，请重新登录后再试。';

  @override
  String get syncMsgPurchaseFailed => '购买失败，请重试。';

  @override
  String get syncMsgPurchasePending => '购买已确认，正在激活，请稍后重试同步。';

  @override
  String get syncMsgNothingToRestore => '没有可恢复的购买。';

  @override
  String get syncMsgRestorePending => '购买已恢复，正在激活……';

  @override
  String get syncMsgCannotDecrypt => '无法解密远程配置。';

  @override
  String get syncMsgProRequired => '同步功能仅限 Glance Sync（Pro）使用。';

  @override
  String get syncMsgBadCredentials => '邮箱或密码错误。';

  @override
  String syncMsgPasswordTooShort(int count) {
    return '密码太短：至少 $count 个字符。';
  }

  @override
  String get syncMsgPasswordTooLong => '密码太长。';

  @override
  String get syncMsgInvalidEmail => '邮箱地址无效。';

  @override
  String get syncMsgAccountExists => '此邮箱已注册，请直接登录。';

  @override
  String get syncMsgSignUpFailed => '无法创建账户。';

  @override
  String get periodToday => '今天';

  @override
  String get period24h => '24 小时';

  @override
  String get period7d => '7 天';

  @override
  String get period30d => '30 天';

  @override
  String get periodThisMonth => '本月';

  @override
  String get period12m => '12 个月';

  @override
  String get periodThisYear => '今年';

  @override
  String get periodAllTime => '全部';

  @override
  String get periodCustom => '自定义';

  @override
  String get metricTypePages => '路径';

  @override
  String get metricTypeEntry => '入口';

  @override
  String get metricTypeExit => '退出';

  @override
  String get metricTypeTitle => '标题';

  @override
  String get metricTypeReferrers => '来源域名';

  @override
  String get metricTypeChannels => '渠道';

  @override
  String get metricTypeQueries => '查询';

  @override
  String get metricTypeBrowsers => '浏览器';

  @override
  String get metricTypeOs => '操作系统';

  @override
  String get metricTypeDevices => '设备';

  @override
  String get metricTypeScreens => '屏幕尺寸';

  @override
  String get metricTypeCountries => '国家/地区';

  @override
  String get metricTypeRegions => '州/省';

  @override
  String get metricTypeCities => '城市';

  @override
  String get metricTypeLanguages => '语言';

  @override
  String get metricTypeEvents => '事件';

  @override
  String get metricSectionPages => '页面';

  @override
  String get metricSectionSources => '来源';

  @override
  String get metricSectionEnvironment => '环境';

  @override
  String get metricSectionLocation => '位置';

  @override
  String get filterOpContains => '包含';

  @override
  String get filterOpNotContains => '不包含';

  @override
  String get entityUnknown => '未知';

  @override
  String get entityReferrerDirect => '直接访问';

  @override
  String get entityBrowserSearchBot => '搜索机器人';

  @override
  String get entityDeviceDesktop => '台式机';

  @override
  String get entityDeviceLaptop => '笔记本';

  @override
  String get entityDeviceTablet => '平板';

  @override
  String get entityDeviceMobile => '手机';

  @override
  String get entityDeviceWearable => '手表';

  @override
  String get entityDeviceConsole => '游戏机';

  @override
  String get entityDeviceTv => '电视';

  @override
  String get channelDirect => '直接';

  @override
  String get channelReferral => '引荐';

  @override
  String get channelAffiliate => '联盟';

  @override
  String get channelEmail => '邮件';

  @override
  String get channelOrganicSearch => '自然搜索';

  @override
  String get channelOrganicSocial => '自然社交';

  @override
  String get channelOrganicShopping => '自然购物';

  @override
  String get channelOrganicVideo => '自然视频';

  @override
  String get channelPaidAds => '付费广告';

  @override
  String get channelPaidSearch => '付费搜索';

  @override
  String get channelPaidSocial => '付费社交';

  @override
  String get channelPaidShopping => '付费购物';

  @override
  String get channelPaidVideo => '付费视频';

  @override
  String get credInstanceUrl => '实例 URL';

  @override
  String get credUmamiUrlPlaceholder => 'analytics.yourdomain.com';

  @override
  String get credUsername => '用户名';

  @override
  String get credPassword => '密码';

  @override
  String get credApiKey => 'API 密钥';

  @override
  String get credUmamiCloudKeyHint =>
      '在 Umami Cloud 中创建：Settings → API keys。API 访问需要 Pro 套餐。';

  @override
  String get credEmailOptional => '账户邮箱（可选）';

  @override
  String get credEmailPlaceholder => 'you@example.com';

  @override
  String get credEmailHint => '邮箱加密码：Glance 会自动列出您的站点。否则请留空，并在下方输入域名。';

  @override
  String get credPasswordOptional => '密码（可选）';

  @override
  String get credDomainFallback => '域名（未填邮箱/密码时）';

  @override
  String get credDomainPlaceholder => 'yourdomain.com';
}
