// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageAuto => 'Automático';

  @override
  String dayRange(String from, String to) {
    return 'de $from a $to';
  }

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonClear => 'Limpar';

  @override
  String get commonRetry => 'Tentar de novo';

  @override
  String get tabSites => 'Sites';

  @override
  String get tabDirect => 'Ao vivo';

  @override
  String get tabSettings => 'Ajustes';

  @override
  String get siteSearchHint => 'Buscar um site';

  @override
  String siteSearchNoMatch(String query) {
    return 'Nenhum site corresponde a “$query”.';
  }

  @override
  String get navToday => 'Hoje';

  @override
  String get navYesterday => 'Ontem';

  @override
  String get navDayBeforeYesterday => 'Anteontem';

  @override
  String get navThisMonth => 'Este mês';

  @override
  String get navLastMonth => 'Mês passado';

  @override
  String get navThisYear => 'Este ano';

  @override
  String get navLastYear => 'Ano passado';

  @override
  String get workspaceSheetTitle => 'Escopo';

  @override
  String get workspaceAllSites => 'Todos os sites';

  @override
  String workspaceTrackedSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites acompanhados',
      one: '1 site acompanhado',
      zero: '0 sites acompanhados',
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
      zero: 'Nenhum site',
    );
    return '$_temp0';
  }

  @override
  String get workspaceNewGroup => 'Novo grupo';

  @override
  String get workspaceManageGroups => 'Gerenciar grupos';

  @override
  String get homeTitleDefault => 'Meus sites';

  @override
  String get homeLoadFailed => 'Não foi possível carregar.';

  @override
  String get homeInternalTitle => 'Entre seus sites';

  @override
  String homeTotalVisitors(String name) {
    return 'Visitantes · $name';
  }

  @override
  String get homeTotalVisitorsAll => 'Visitantes · todos os sites';

  @override
  String get homeVsPrevious => 'vs período ant.';

  @override
  String homeLiveCount(int count) {
    return '$count ao vivo';
  }

  @override
  String get homeEmptyTitle => 'Nenhum site exibido';

  @override
  String get homeEmptyBody =>
      'Nenhum site acompanhado por enquanto. Escolha quais exibir.';

  @override
  String get homeEmptyChooseSites => 'Escolher sites';

  @override
  String get homeEmptyAddSource => '+ Adicionar fonte';

  @override
  String get homeEmptyGroupTitle => 'Grupo vazio';

  @override
  String homeEmptyGroupBody(String name) {
    return '“$name” não tem nenhum site.';
  }

  @override
  String get homeEmptyGroupChoose => 'Escolher os sites';

  @override
  String get homeEmptyGroupSeeAll => 'Ver todos os sites';

  @override
  String get homeWelcomeTagline => 'Suas estatísticas, num piscar de olhos.';

  @override
  String get homeWelcomeTitle => 'Conecte sua primeira ferramenta';

  @override
  String get homeWelcomeBody =>
      'Umami, Plausible… adicione uma fonte e escolha os sites a acompanhar.';

  @override
  String get homeWelcomeAddSource => 'Adicionar fonte';

  @override
  String get homeWelcomeFootnote =>
      'Chave somente leitura · seus dados ficam com você';

  @override
  String get homeSiteUnavailable => 'Indisponível';

  @override
  String get detailVisitorsUnique => 'Visitantes únicos';

  @override
  String get detailKpiVisits => 'Visitas';

  @override
  String get detailKpiAvgDuration => 'Duração méd.';

  @override
  String get detailKpiBounce => 'Rejeição';

  @override
  String get detailLiveNow => 'Ao vivo agora';

  @override
  String get detailLiveNobody => 'Ninguém por enquanto.';

  @override
  String get detailTabOverview => 'Visão geral';

  @override
  String get detailTabEvents => 'Eventos';

  @override
  String get detailTabDashboards => 'Painéis';

  @override
  String get detailEventsEmpty => 'Nenhum evento neste período';

  @override
  String get detailEventsTriggered => 'Eventos disparados';

  @override
  String get detailEventsByEvent => 'Por evento';

  @override
  String detailSectionViewAll(int count) {
    return 'Ver as $count linhas';
  }

  @override
  String get detailBadgeInternal => 'INTERNO';

  @override
  String get directEyebrow => 'Tempo real';

  @override
  String get directTitle => 'Ao vivo';

  @override
  String get directNow => 'agora';

  @override
  String get directVisitorsAll => 'visitantes em todos os seus sites';

  @override
  String directVisitorsGroup(String name) {
    return 'visitantes no grupo “$name”';
  }

  @override
  String get directBySite => 'Por site';

  @override
  String get directOnlyActive => 'Só ativos';

  @override
  String get directNoneLive => 'Nenhum visitante ao vivo por enquanto.';

  @override
  String get directNoSites => 'Nenhum site.';

  @override
  String directHiddenSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites sem visitantes ocultos',
      one: '1 site sem visitantes oculto',
    );
    return '$_temp0';
  }

  @override
  String networkExchanged(String period) {
    return 'Visitantes trocados · $period';
  }

  @override
  String networkPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites em andamento…',
      one: '1 site em andamento…',
    );
    return '$_temp0';
  }

  @override
  String get networkExplainer =>
      'Visitantes que chegaram a um dos seus sites vindos de outro site seu.';

  @override
  String get networkEmpty => 'Nenhuma navegação interna neste período.';

  @override
  String get networkSenders => 'Quem envia';

  @override
  String get networkReceivers => 'Quem recebe';

  @override
  String get networkFlows => 'Fluxos';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonSave => 'Salvar';

  @override
  String get dashboardsKindCounter => 'Contador';

  @override
  String get dashboardsKindRatio => 'Taxa';

  @override
  String get dashboardsKindFunnel => 'Funil';

  @override
  String get dashboardsKindBreakdown => 'Detalhamento';

  @override
  String get dashboardsKindExternal => 'Métrica';

  @override
  String get dashboardsKindSites => 'Sites';

  @override
  String get dashboardsMoveCard => 'Mover o card';

  @override
  String get dashboardsCardOptions => 'Opções do card';

  @override
  String get dashboardsResizeCard => 'Redimensionar o card';

  @override
  String get dashboardsLoadFailed => 'Não foi possível carregar.';

  @override
  String get dashboardsNoData => 'Sem dados no período';

  @override
  String get dashboardsNoEvents => 'Nenhum evento no período';

  @override
  String dashboardsUnpublished(String date) {
    return 'Ainda não publicados: dados até $date';
  }

  @override
  String get dashboardsPendingNow => 'Ainda não mensurável neste período';

  @override
  String dashboardsPendingDelay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ainda não mensurável: é preciso um intervalo de $count dias',
      one: 'Ainda não mensurável: é preciso 1 dia de intervalo',
    );
    return '$_temp0';
  }

  @override
  String dashboardsCohortOne(String date) {
    return 'Medida na coorte de $date';
  }

  @override
  String dashboardsCohortRange(String range) {
    return 'Medida nas coortes $range';
  }

  @override
  String dashboardsFamilyMember(String member) {
    return '$member · ajusta-se ao período';
  }

  @override
  String dashboardsDataUntil(String date) {
    return 'Dados até $date';
  }

  @override
  String dashboardsFunnelVisitors(String last, String first) {
    return '$last / $first visitantes';
  }

  @override
  String dashboardsCohortTooltip(String date, String cohort) {
    return '$date · coorte de $cohort';
  }

  @override
  String get dashboardsTotal => 'Total';

  @override
  String dashboardsSegmentEstimated(String label) {
    return '$label · estimado';
  }

  @override
  String get dashboardsDeleted => 'Card excluído';

  @override
  String get dashboardsConfirmDelete => 'Confirmar exclusão';

  @override
  String get dashboardsAllHidden => 'Nenhum card tem dados neste período';

  @override
  String dashboardsHiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards sem dados neste período',
      one: '1 card sem dados neste período',
    );
    return '$_temp0';
  }

  @override
  String get dashboardsShow => 'Mostrar';

  @override
  String get dashboardsArrangeHint =>
      'Mantenha um card pressionado para movê-lo e arraste o canto para redimensioná-lo.';

  @override
  String get dashboardsArrange => 'Organizar';

  @override
  String get dashboardsArrangeDone => 'Concluir';

  @override
  String get dashboardsNew => 'Novo card';

  @override
  String get dashboardsEmptyTitle => 'Nenhum card';

  @override
  String get dashboardsEmptyBody =>
      'Acompanhe uma taxa, um funil ou um detalhamento criados a partir dos seus eventos.';

  @override
  String get dashboardsCreate => 'Criar um card';

  @override
  String get dashboardsMetricsSource => 'Fonte de métricas';

  @override
  String get dashboardsMetricsIntro =>
      'Uma pequena API do seu site que fornece indicadores calculados no banco de dados dele (retenção, contas…): um catálogo e séries, protegidos por um token.';

  @override
  String get dashboardsMetricsHowItWorks => 'Como funciona?';

  @override
  String get dashboardsMetricsUrlLabel => 'Endereço da API';

  @override
  String get dashboardsMetricsUrlHint =>
      'https://exemplo.com.br/api/interna/metricas/';

  @override
  String get dashboardsMetricsToken => 'Token';

  @override
  String get dashboardsMetricsTest => 'Testar';

  @override
  String dashboardsMetricsAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count indicadores disponíveis',
      one: '1 indicador disponível',
    );
    return '$_temp0';
  }

  @override
  String get dashboardsMetricsSaved => 'Fonte salva';

  @override
  String get dashboardsMetricsRemove => 'Remover a fonte';

  @override
  String dashboardsMetricsRemoveWithCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return 'Remover a fonte e $_temp0';
  }

  @override
  String get dashboardsMetricsRemoved => 'Fonte removida';

  @override
  String dashboardsMetricsRemovedWithCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards excluídos',
      one: '1 card excluído',
    );
    return 'Fonte removida, $_temp0';
  }

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonAdd => 'Adicionar';

  @override
  String get commonSearch => 'Buscar';

  @override
  String get editorNameFallback => 'Sem título';

  @override
  String editorNameBy(String a, String b) {
    return '$a por $b';
  }

  @override
  String get editorErrChooseEvent => 'Escolha um evento';

  @override
  String get editorErrChooseCountEvent => 'Escolha o evento a contar';

  @override
  String get editorErrChooseRefEvent => 'Escolha o evento de referência';

  @override
  String get editorErrChooseProperty => 'Escolha uma propriedade';

  @override
  String get editorErrChooseMetric => 'Escolha uma métrica';

  @override
  String get editorErrAddSite => 'Adicione pelo menos um site';

  @override
  String editorErrSitesMax(int max) {
    return 'Um card tem no máximo $max sites';
  }

  @override
  String get editorErrChooseLineSite => 'Escolha o site de cada linha';

  @override
  String get editorErrNameLines => 'Dê um nome a cada linha';

  @override
  String get editorErrReferrer => 'Informe o domínio da referência';

  @override
  String editorErrFunnelMin(int min) {
    return 'Um funil tem pelo menos $min etapas';
  }

  @override
  String editorErrFunnelMax(int max) {
    return 'Um funil tem no máximo $max etapas';
  }

  @override
  String editorErrStepEvent(int n) {
    return 'Escolha o evento da etapa $n';
  }

  @override
  String get editorErrFunnelNumeric =>
      'Um funil não compara números: remova este filtro';

  @override
  String get editorErrWindow => 'Intervalo inválido';

  @override
  String get editorErrFilterValueMissing => 'Valor do filtro ausente';

  @override
  String get editorErrFilterNotNumber => 'Valor do filtro não numérico';

  @override
  String get editorTitleEdit => 'Editar o card';

  @override
  String get editorFieldName => 'Nome';

  @override
  String get editorHeadingType => 'Tipo';

  @override
  String get editorHeadingPreview => 'Prévia';

  @override
  String get editorPreviewEmpty =>
      'A prévia aparece assim que o card estiver completo.';

  @override
  String get editorCreated => 'Card criado';

  @override
  String get editorSaved => 'Card salvo';

  @override
  String get editorDelete => 'Excluir este card';

  @override
  String get editorCreate => 'Criar';

  @override
  String get editorCountLabel => 'O que contar';

  @override
  String get editorRatioOf => 'Em relação a';

  @override
  String get editorGapsLabel => 'Deixar uma lacuna quando nada aconteceu';

  @override
  String get editorGapsHint => 'Senão, esses dias contam como 0 %.';

  @override
  String get editorOverTimeLabel => 'Evolução ao longo do tempo';

  @override
  String get editorOverTimeHint => 'Uma curva por valor, na largura toda';

  @override
  String get editorMetricLabel => 'Métrica';

  @override
  String get editorMetricPlaceholder => 'Escolher uma métrica';

  @override
  String get editorMetricNone => 'Esta fonte não oferece nenhum indicador.';

  @override
  String get editorMetricAdjusts => 'ajusta-se ao período';

  @override
  String get editorEventLabel => 'Evento';

  @override
  String get editorEventPlaceholder => 'Escolher um evento';

  @override
  String get editorPropertyLabel => 'Propriedade';

  @override
  String get editorPropertyPlaceholder => 'Escolher uma propriedade';

  @override
  String get editorKindExternal => 'Métrica do site';

  @override
  String get editorKindHintCounter => 'Quantas vezes um evento acontece';

  @override
  String get editorKindHintRatio => 'Um evento em relação a outro';

  @override
  String get editorKindHintFunnel => 'O caminho etapa por etapa';

  @override
  String get editorKindHintBreakdown => 'Os valores de uma propriedade';

  @override
  String get editorKindHintExternal => 'Um indicador fornecido pela sua API';

  @override
  String get editorKindHintSites => 'Os visitantes de vários sites';

  @override
  String get editorFunnelAddStep => 'Adicionar etapa';

  @override
  String get editorFunnelWindowLabel => 'Intervalo máximo entre duas etapas';

  @override
  String editorFunnelWindowHint(int min, int max) {
    return 'Em minutos (de $min a $max): um visitante que demora mais para passar de uma etapa à seguinte deixa de ser contado.';
  }

  @override
  String editorFunnelStep(int n) {
    return 'ETAPA $n';
  }

  @override
  String get editorFunnelMoveUp => 'Subir a etapa';

  @override
  String get editorFunnelMoveDown => 'Descer a etapa';

  @override
  String get editorFunnelRemove => 'Remover a etapa';

  @override
  String get editorTypeText => 'texto';

  @override
  String get editorTypeNumber => 'número';

  @override
  String get editorTypeBoolean => 'sim/não';

  @override
  String get editorFreeEvent => 'Digitar um nome de evento';

  @override
  String get editorFreeProperty => 'Digitar um nome de propriedade';

  @override
  String get editorSiteLabel => 'Site';

  @override
  String editorUseTyped(String value) {
    return 'Usar “$value”';
  }

  @override
  String get editorListUnavailable =>
      'Lista indisponível — digite o nome manualmente.';

  @override
  String get editorListEmpty =>
      'Nada visto em 30 dias — digite o nome manualmente.';

  @override
  String get editorAddFilter => 'Adicionar filtro';

  @override
  String get editorRemoveFilter => 'Remover o filtro';

  @override
  String get editorFilterValue => 'Valor';

  @override
  String get editorTrue => 'verdadeiro';

  @override
  String get editorFalse => 'falso';

  @override
  String get editorModeAll => 'Todos';

  @override
  String get editorModeOnly => 'Vindos de';

  @override
  String get editorModeExcept => 'Exceto vindos de';

  @override
  String get editorLineSitePlaceholder => 'Escolher um site';

  @override
  String get editorLineLabel => 'Rótulo';

  @override
  String get editorLineReferrer => 'Domínio da referência';

  @override
  String get editorLineAdd => 'Adicionar um site';

  @override
  String get editorLinesHint =>
      'Visitantes únicos de cada linha. “Exceto vindos de” remove os que o site recebeu desse domínio.';

  @override
  String editorLineTitle(int n) {
    return 'LINHA $n';
  }

  @override
  String get editorLineRemove => 'Remover a linha';

  @override
  String commonSiteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites',
      one: '1 site',
      zero: '0 sites',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsGroupAccount => 'Conta';

  @override
  String get settingsGroupSites => 'Sites';

  @override
  String get settingsGroupSync => 'Sincronização';

  @override
  String get settingsGroupTransfer => 'Transferência';

  @override
  String get settingsGroupAppearance => 'Aparência';

  @override
  String get settingsGroupData => 'Dados';

  @override
  String get settingsGroupApp => 'Aplicativo';

  @override
  String get settingsAccountBadAuth => 'Credenciais ou chave de API recusadas';

  @override
  String get settingsAccountUnreachable => 'Instância inacessível';

  @override
  String settingsAccountSubtitle(String provider, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites',
      one: '1 site',
      zero: '0 sites',
    );
    return '$provider · $_temp0';
  }

  @override
  String get settingsAddSource => 'Adicionar fonte';

  @override
  String get settingsGroupsTitle => 'Grupos';

  @override
  String get settingsGroupsHint => 'Ver uma parte dos seus sites à parte';

  @override
  String get settingsSyncConnected => 'Conectado';

  @override
  String get settingsSyncPitch => 'Fazer backup e sincronizar (criptografado)';

  @override
  String get settingsTransferShow => 'Mostrar um QR de transferência';

  @override
  String get settingsTransferNone => 'Nenhuma conta para transferir';

  @override
  String get settingsTransferContents => 'Contas, credenciais e grupos';

  @override
  String get settingsTransferImport => 'Importar de outro dispositivo';

  @override
  String get settingsTransferScan => 'Escanear um QR de transferência';

  @override
  String get settingsThemeTitle => 'Tema';

  @override
  String get settingsThemeAuto => 'Auto';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Escuro';

  @override
  String get settingsChartsTitle => 'Gráficos';

  @override
  String get settingsChartsHint => 'Curva suave ou barras';

  @override
  String get settingsChartCurve => 'Curva';

  @override
  String get settingsChartBars => 'Barras';

  @override
  String get settingsDefaultPeriod => 'Período padrão';

  @override
  String get settingsDefaultPeriodHint => 'Ao abrir o aplicativo';

  @override
  String get settingsRefresh => 'Atualização auto';

  @override
  String settingsRefreshSeconds(int count) {
    return '$count s';
  }

  @override
  String settingsRefreshMinutes(int count) {
    return '$count min';
  }

  @override
  String get settingsCheckUpdates => 'Buscar atualizações';

  @override
  String get accountMenuConnectionOk => 'Conexão bem-sucedida';

  @override
  String accountMenuConnectionOkSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Conexão bem-sucedida · $count sites',
      one: 'Conexão bem-sucedida · 1 site',
    );
    return '$_temp0';
  }

  @override
  String get accountMenuTest => 'Testar a conexão';

  @override
  String get accountMenuEdit => 'Editar a fonte';

  @override
  String get accountMenuEditHint => 'URL, credenciais, chave de API…';

  @override
  String get accountMenuChooseSites => 'Escolher sites';

  @override
  String get accountMenuDelete => 'Excluir esta conta';

  @override
  String get accountMenuDeleted => 'Fonte excluída';

  @override
  String get accountMenuSelectionSaved => 'Seleção salva';

  @override
  String get accountSelectionAll => 'todos os sites';

  @override
  String accountSelectionAllExcept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'todos, exceto $count sites',
      one: 'todos, exceto 1 site',
    );
    return '$_temp0';
  }

  @override
  String get accountSelectionNone => 'nenhum site';

  @override
  String get syncSubtitle =>
      'Suas contas e grupos, sincronizados e criptografados.';

  @override
  String get syncEmail => 'E-mail';

  @override
  String get syncEmailHint => 'voce@example.com';

  @override
  String get syncPassword => 'Senha';

  @override
  String syncPasswordHint(int count) {
    return 'Mínimo de $count caracteres';
  }

  @override
  String get syncCreateAccount => 'Criar uma conta';

  @override
  String get syncCreateAccountButton => 'Criar conta';

  @override
  String get syncSignIn => 'Entrar';

  @override
  String get syncHaveAccount => 'Já tenho uma conta';

  @override
  String get syncEncryptedNote =>
      'Sua configuração é criptografada no dispositivo antes do envio: o servidor não consegue lê-la. Senha esquecida = sincronização irrecuperável.';

  @override
  String get syncToastCreated => 'Conta criada';

  @override
  String get syncToastSignedIn => 'Conectado';

  @override
  String get syncToastSignedOut => 'Desconectado';

  @override
  String get syncToastSynced => 'Sincronizado';

  @override
  String get syncToastDeleted => 'Conta excluída';

  @override
  String get syncToastUnlocked => 'Glance Sync desbloqueado';

  @override
  String get syncToastRestored => 'Compra restaurada';

  @override
  String get syncNever => 'Nunca sincronizado';

  @override
  String syncLastSync(String date) {
    return 'Sinc. $date';
  }

  @override
  String get syncNow => 'Sincronizar agora';

  @override
  String get syncSignOut => 'Sair';

  @override
  String get syncDeleteAccount => 'Excluir minha conta';

  @override
  String get syncDeleteTitle => 'Excluir a conta?';

  @override
  String get syncDeleteBody =>
      'Sua conta Glance Sync e toda a configuração sincronizada serão excluídas definitivamente do servidor. Esta ação é irreversível. Suas fontes de analytics permanecem neste dispositivo.';

  @override
  String get syncUnlockTitle => 'Desbloqueie o Glance Sync';

  @override
  String get syncUnlockBuy =>
      'Faça backup e sincronize suas contas e grupos em todos os seus dispositivos. Compra única.';

  @override
  String get syncUnlockElsewhere =>
      'Compra única pelo app mobile (iOS/Android). Depois de desbloqueado, entre aqui com a mesma conta: a sincronização acompanha automaticamente.';

  @override
  String get syncUnlockButton => 'Desbloquear';

  @override
  String get syncRestore => 'Restaurar uma compra';

  @override
  String get syncSoon => 'Em breve';

  @override
  String get transferExportTitle => 'Transferir';

  @override
  String get transferExportSubtitle =>
      'Escaneie este código no outro dispositivo.';

  @override
  String transferExpiresIn(String time) {
    return 'Expira em $time';
  }

  @override
  String get transferCodeLabel => 'Código a digitar no outro dispositivo';

  @override
  String get transferWarning =>
      'Este código contém suas credenciais. Não o fotografe nem o compartilhe: o QR sozinho não basta, mas com o código de 4 dígitos ele dá acesso às suas contas.';

  @override
  String get transferExpiredTitle => 'Código expirado';

  @override
  String get transferExpiredBody =>
      'Uma transferência só vale por alguns minutos.';

  @override
  String get transferRegenerate => 'Gerar de novo';

  @override
  String get transferTooLargeTitle => 'Configuração grande demais';

  @override
  String transferTooLargeBody(int size, int max) {
    return 'Ela não cabe em um QR code ($size caracteres para um máximo de $max). Acompanhe “todos os sites” nas suas contas em vez de uma seleção e tente de novo.';
  }

  @override
  String get transferFailedTitle => 'Transferência impossível';

  @override
  String get transferFailedBody => 'Não foi possível preparar a transferência.';

  @override
  String get transferImportTitle => 'Importar';

  @override
  String get transferImportScanHint =>
      'Aponte para o QR exibido no outro dispositivo.';

  @override
  String get transferImportCodeHint => 'Digite o código exibido ao lado do QR.';

  @override
  String get transferScanned => 'Código escaneado';

  @override
  String get transferCodeField => 'Código de 4 dígitos';

  @override
  String get transferImportButton => 'Importar';

  @override
  String get transferRescan => 'Escanear de novo';

  @override
  String transferImported(int accounts, int groups) {
    String _temp0 = intl.Intl.pluralLogic(
      accounts,
      locale: localeName,
      other: '$accounts contas',
      one: '1 conta',
    );
    String _temp1 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups grupos',
      one: '1 grupo',
      zero: '0 grupos',
    );
    return '$_temp0 e $_temp1 importados';
  }

  @override
  String get transferErrExpired =>
      'Este código expirou. Gere-o de novo no outro dispositivo.';

  @override
  String get transferErrBadCode => 'Código incorreto.';

  @override
  String get transferErrFailed => 'Não foi possível importar.';

  @override
  String get transferCameraDenied => 'Câmera negada';

  @override
  String get transferCameraUnavailable => 'Câmera indisponível';

  @override
  String get transferCameraDeniedBody =>
      'Permita o acesso à câmera nos ajustes do sistema para escanear uma transferência.';

  @override
  String get transferCameraUnavailableBody =>
      'Nenhuma câmera utilizável neste dispositivo.';

  @override
  String get groupsSubtitle =>
      'Um escopo de leitura: totais e curva contam só os sites dele.';

  @override
  String get groupsEmptyTitle => 'Nenhum grupo';

  @override
  String get groupsEmptyBody =>
      'Agrupe seus sites — por exemplo “Jogos” ou “Clientes” — para ver as estatísticas deles à parte, sem o resto.';

  @override
  String get groupsCreate => 'Criar um grupo';

  @override
  String get groupEditEditTitle => 'Editar o grupo';

  @override
  String get groupEditName => 'Nome';

  @override
  String get groupEditNameHint => 'Jogos, Clientes, Pessoal…';

  @override
  String get groupEditSitesLabel => 'Sites do grupo';

  @override
  String get groupEditAddSourceHint => 'os sites dela entram aqui';

  @override
  String get groupEditNoSites =>
      'Nenhum site acompanhado por enquanto — adicione uma fonte acima para preencher este grupo.';

  @override
  String get groupEditCreateButton => 'Criar o grupo';

  @override
  String get groupEditCreated => 'Grupo criado';

  @override
  String get groupEditSaved => 'Grupo salvo';

  @override
  String get groupEditDeleted => 'Grupo excluído';

  @override
  String get groupEditDeleteTitle => 'Excluir este grupo?';

  @override
  String get groupEditDeleteBody =>
      'Os sites e suas estatísticas não são afetados — só o agrupamento desaparece.';

  @override
  String get addSourceNewTitle => 'Nova fonte';

  @override
  String get addSourceProvider => 'PROVEDOR';

  @override
  String get addSourceName => 'Nome (opcional)';

  @override
  String get addSourceNameHint => 'Meu domínio';

  @override
  String get addSourceTest => 'Testar a configuração';

  @override
  String get addSourceContinue => 'Continuar';

  @override
  String get addSourceMissingFields => 'Preencha os campos obrigatórios.';

  @override
  String get addSourceTestOk => 'Conexão bem-sucedida.';

  @override
  String addSourceTestOkSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Conexão bem-sucedida · $count sites detectados',
      one: 'Conexão bem-sucedida · 1 site detectado',
    );
    return '$_temp0';
  }

  @override
  String get addSourceNoSitesPlausible =>
      'Nenhum site listado automaticamente: sua instância não expõe a API de listagem (Plausible Community Edition). Informe acima o domínio a acompanhar.';

  @override
  String get addSourceNoSites => 'Nenhum site encontrado para esta conta.';

  @override
  String get addSourceKeyRejected =>
      'Chave de API recusada (acesso às estatísticas). Verifique a chave de API.';

  @override
  String get addSourceCredsRejected => 'Credenciais recusadas.';

  @override
  String get addSourceAdded => 'Fonte adicionada';

  @override
  String get addSourceEdited => 'Fonte alterada';

  @override
  String get sitePickerTitle => 'Escolha dos sites';

  @override
  String sitePickerDetected(String provider, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites detectados',
      one: '1 site detectado',
    );
    return '$provider · $_temp0';
  }

  @override
  String get sitePickerFollowNew => 'Exibir os novos sites';

  @override
  String get sitePickerFollowNewHint => 'Um site criado depois aparece sozinho';

  @override
  String get sitePickerCurrent => 'Sites atuais';

  @override
  String sitePickerShownOf(int shown, int total) {
    return '$shown de $total';
  }

  @override
  String get sitePickerCheckAll => 'Marcar tudo';

  @override
  String get sitePickerUncheckAll => 'Desmarcar tudo';

  @override
  String get sitePickerFollowAll => 'Acompanhar todos os sites';

  @override
  String sitePickerFollowAndNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Acompanhar $count sites e os novos',
      one: 'Acompanhar 1 site e os novos',
      zero: 'Acompanhar 0 sites e os novos',
    );
    return '$_temp0';
  }

  @override
  String sitePickerFollow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Acompanhar $count sites',
      one: 'Acompanhar 1 site',
      zero: 'Acompanhar 0 sites',
    );
    return '$_temp0';
  }

  @override
  String get sitePickerShowNone => 'Não exibir nenhum site';

  @override
  String get commonVisitors => 'Visitantes';

  @override
  String get commonPageviews => 'Visualizações';

  @override
  String get commonNoData => 'Sem dados';

  @override
  String desktopSitesHeader(int count) {
    return 'Sites ($count)';
  }

  @override
  String desktopHiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ocultos',
      one: '$count oculto',
    );
    return '$_temp0';
  }

  @override
  String get desktopShowAllSites => 'Mostrar todos os sites';

  @override
  String get desktopHideEmptySites => 'Ocultar sites sem visitantes';

  @override
  String get desktopLiveNobody => 'Ninguém neste momento.';

  @override
  String get desktopKpiSites => 'Sites';

  @override
  String desktopNoSitesGroupBody(String name) {
    return '“$name” não tem nenhum site. Escolha os que fazem parte dele.';
  }

  @override
  String get desktopNoSitesBody =>
      'Suas contas não acompanham nenhum site por enquanto. Escolha os sites a exibir nos ajustes.';

  @override
  String get chartLegendForecast => 'Previsão';

  @override
  String get chartLegendPrevious => 'Período anterior';

  @override
  String get chartTooltipVisitors => 'visitantes';

  @override
  String get chartTooltipPageviews => 'visualizações';

  @override
  String get chartTooltipForecast => 'previsão';

  @override
  String get chartTooltipPrevious => 'período anterior';

  @override
  String get chartNoSeries => 'Nenhuma série selecionada';

  @override
  String chartHour(String hour) {
    return '${hour}h';
  }

  @override
  String get periodControlsDisplay => 'Exibição';

  @override
  String get periodControlsSplit => 'Divisão';

  @override
  String get periodControlsChart => 'Gráfico';

  @override
  String get periodUnitHour => 'Hora';

  @override
  String get periodUnitDay => 'Dia';

  @override
  String get periodUnitMonth => 'Mês';

  @override
  String get errorsAuthRefused => 'Credenciais recusadas.';

  @override
  String get errorsRequestRefused => 'Requisição recusada pelo servidor.';

  @override
  String get errorsNotFound => 'Instância ou API não encontrada.';

  @override
  String get errorsTimeout =>
      'Tempo esgotado — instância lenta ou inacessível.';

  @override
  String get errorsUnreachable => 'Instância inacessível. Verifique a URL.';

  @override
  String errorsServerCode(int code) {
    return 'Erro $code do servidor.';
  }

  @override
  String get errorsConnectionFailed => 'Não foi possível conectar.';

  @override
  String errorsGeneric(String detail) {
    return 'Erro: $detail';
  }

  @override
  String get errUnsupportedIndicators => 'Indicadores não suportados';

  @override
  String get errUnsupportedSiteTables => 'Cards de sites não suportados';

  @override
  String get errUnsupportedFunnels => 'Funis não suportados';

  @override
  String get errUnsupportedBreakdowns => 'Detalhamentos não suportados';

  @override
  String errOperatorUmamiFunnel(String op) {
    return 'Operador “$op” indisponível em um funil do Umami';
  }

  @override
  String errOperatorPlausible(String op) {
    return 'Operador “$op” indisponível no Plausible (propriedades só em texto)';
  }

  @override
  String get errFathomSoon => 'O Fathom chega em breve.';

  @override
  String get errPlausibleNeedsSite =>
      'Informe um domínio, ou e-mail + senha para listar seus sites automaticamente.';

  @override
  String get errUmamiLoginUnexpected => 'Resposta de login do Umami inesperada';

  @override
  String errBucketsTooFine(int count) {
    return 'Divisão fina demais: mais de $count pontos no período.';
  }

  @override
  String get errMetricsNotConfigured => 'Fonte não configurada no servidor';

  @override
  String get errMetricsBadToken => 'Token recusado';

  @override
  String errMetricsBadRequest(String code) {
    return 'Requisição recusada ($code)';
  }

  @override
  String get errMetricsUnsupportedVersion => 'Versão da API não suportada';

  @override
  String get errMetricsUnexpected => 'Resposta inesperada do servidor';

  @override
  String get syncMsgUnreachable => 'Servidor inacessível. Tente de novo.';

  @override
  String get syncMsgSessionExpired =>
      'Sessão expirada. Entre de novo e tente outra vez.';

  @override
  String get syncMsgPurchaseFailed =>
      'Não foi possível comprar. Tente de novo.';

  @override
  String get syncMsgPurchasePending =>
      'Compra validada — ativação em andamento, tente sincronizar de novo daqui a pouco.';

  @override
  String get syncMsgNothingToRestore => 'Nenhuma compra a restaurar.';

  @override
  String get syncMsgRestorePending =>
      'Compra restaurada — ativação em andamento…';

  @override
  String get syncMsgCannotDecrypt =>
      'Não foi possível descriptografar a configuração remota.';

  @override
  String get syncMsgProRequired =>
      'A sincronização é exclusiva do Glance Sync (Pro).';

  @override
  String get syncMsgBadCredentials => 'E-mail ou senha incorretos.';

  @override
  String syncMsgPasswordTooShort(int count) {
    return 'Senha curta demais: mínimo de $count caracteres.';
  }

  @override
  String get syncMsgPasswordTooLong => 'Senha longa demais.';

  @override
  String get syncMsgInvalidEmail => 'Endereço de e-mail inválido.';

  @override
  String get syncMsgAccountExists =>
      'Este e-mail já tem uma conta: entre nela.';

  @override
  String get syncMsgSignUpFailed => 'Não foi possível criar a conta.';

  @override
  String get periodToday => 'Hoje';

  @override
  String get period24h => '24 h';

  @override
  String get period7d => '7 dias';

  @override
  String get period30d => '30 d';

  @override
  String get periodThisMonth => 'Este mês';

  @override
  String get period12m => '12 m';

  @override
  String get periodThisYear => 'Este ano';

  @override
  String get periodAllTime => 'Tudo';

  @override
  String get periodCustom => 'Outro';

  @override
  String get metricTypePages => 'Caminhos';

  @override
  String get metricTypeEntry => 'Entrada';

  @override
  String get metricTypeExit => 'Saída';

  @override
  String get metricTypeTitle => 'Título';

  @override
  String get metricTypeReferrers => 'Referências';

  @override
  String get metricTypeChannels => 'Canais';

  @override
  String get metricTypeQueries => 'Consultas';

  @override
  String get metricTypeBrowsers => 'Navegadores';

  @override
  String get metricTypeOs => 'SO';

  @override
  String get metricTypeDevices => 'Dispositivos';

  @override
  String get metricTypeScreens => 'Telas';

  @override
  String get metricTypeCountries => 'Países';

  @override
  String get metricTypeRegions => 'Regiões';

  @override
  String get metricTypeCities => 'Cidades';

  @override
  String get metricTypeLanguages => 'Idiomas';

  @override
  String get metricTypeEvents => 'Eventos';

  @override
  String get metricSectionPages => 'Páginas';

  @override
  String get metricSectionSources => 'Fontes';

  @override
  String get metricSectionEnvironment => 'Ambiente';

  @override
  String get metricSectionLocation => 'Localização';

  @override
  String get filterOpContains => 'contém';

  @override
  String get filterOpNotContains => 'não contém';

  @override
  String get entityUnknown => 'Desconhecido';

  @override
  String get entityReferrerDirect => 'Acesso direto';

  @override
  String get entityBrowserSearchBot => 'Robô de busca';

  @override
  String get entityDeviceDesktop => 'Computador';

  @override
  String get entityDeviceLaptop => 'Notebook';

  @override
  String get entityDeviceTablet => 'Tablet';

  @override
  String get entityDeviceMobile => 'Celular';

  @override
  String get entityDeviceWearable => 'Relógio';

  @override
  String get entityDeviceConsole => 'Console';

  @override
  String get entityDeviceTv => 'TV';

  @override
  String get channelDirect => 'Direto';

  @override
  String get channelReferral => 'Referência';

  @override
  String get channelAffiliate => 'Afiliados';

  @override
  String get channelEmail => 'E-mail';

  @override
  String get channelOrganicSearch => 'Busca orgânica';

  @override
  String get channelOrganicSocial => 'Redes sociais';

  @override
  String get channelOrganicShopping => 'Shopping orgânico';

  @override
  String get channelOrganicVideo => 'Vídeo orgânico';

  @override
  String get channelPaidAds => 'Anúncios pagos';

  @override
  String get channelPaidSearch => 'Busca paga';

  @override
  String get channelPaidSocial => 'Redes sociais pagas';

  @override
  String get channelPaidShopping => 'Shopping pago';

  @override
  String get channelPaidVideo => 'Vídeo pago';

  @override
  String get credInstanceUrl => 'URL da instância';

  @override
  String get credUmamiUrlPlaceholder => 'analytics.meudominio.com.br';

  @override
  String get credUsername => 'Nome de usuário';

  @override
  String get credPassword => 'Senha';

  @override
  String get credApiKey => 'Chave de API';

  @override
  String get credEmailOptional => 'E-mail da conta (opcional)';

  @override
  String get credEmailPlaceholder => 'voce@example.com';

  @override
  String get credEmailHint =>
      'E-mail + senha: o Glance lista seus sites automaticamente. Senão, deixe em branco e informe um domínio abaixo.';

  @override
  String get credPasswordOptional => 'Senha (opcional)';

  @override
  String get credDomainFallback => 'Domínio (sem e-mail/senha)';

  @override
  String get credDomainPlaceholder => 'meudominio.com.br';
}
