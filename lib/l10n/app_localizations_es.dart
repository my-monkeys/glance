// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageAuto => 'Automático';

  @override
  String dayRange(String from, String to) {
    return 'del $from al $to';
  }

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonClear => 'Borrar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get tabSites => 'Sitios';

  @override
  String get tabDirect => 'En vivo';

  @override
  String get tabSettings => 'Ajustes';

  @override
  String get siteSearchHint => 'Buscar sitios';

  @override
  String siteSearchNoMatch(String query) {
    return 'Ningún sitio coincide con “$query”.';
  }

  @override
  String get navToday => 'Hoy';

  @override
  String get navYesterday => 'Ayer';

  @override
  String get navDayBeforeYesterday => 'Anteayer';

  @override
  String get navThisMonth => 'Este mes';

  @override
  String get navLastMonth => 'Mes pasado';

  @override
  String get navThisYear => 'Este año';

  @override
  String get navLastYear => 'Año pasado';

  @override
  String get workspaceSheetTitle => 'Ámbito';

  @override
  String get workspaceAllSites => 'Todos los sitios';

  @override
  String workspaceTrackedSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sitios seguidos',
      one: '1 sitio seguido',
      zero: '0 sitios seguidos',
    );
    return '$_temp0';
  }

  @override
  String workspaceSiteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sitios',
      one: '1 sitio',
      zero: 'Ningún sitio',
    );
    return '$_temp0';
  }

  @override
  String get workspaceNewGroup => 'Nuevo grupo';

  @override
  String get workspaceManageGroups => 'Gestionar grupos';

  @override
  String get homeTitleDefault => 'Mis sitios';

  @override
  String get homeLoadFailed => 'No se pudo cargar.';

  @override
  String get homeInternalTitle => 'Entre tus sitios';

  @override
  String homeTotalVisitors(String name) {
    return 'Visitantes · $name';
  }

  @override
  String get homeTotalVisitorsAll => 'Visitantes · todos los sitios';

  @override
  String get homeVsPrevious => 'vs. periodo ant.';

  @override
  String homeLiveCount(int count) {
    return '$count en vivo';
  }

  @override
  String get homeEmptyTitle => 'Ningún sitio visible';

  @override
  String get homeEmptyBody =>
      'Aún no sigues ningún sitio. Elige los que quieres ver.';

  @override
  String get homeEmptyChooseSites => 'Elegir sitios';

  @override
  String get homeEmptyAddSource => '+ Añadir una fuente';

  @override
  String get homeEmptyGroupTitle => 'Grupo vacío';

  @override
  String homeEmptyGroupBody(String name) {
    return '“$name” no tiene sitios.';
  }

  @override
  String get homeEmptyGroupChoose => 'Elegir sitios';

  @override
  String get homeEmptyGroupSeeAll => 'Ver todos los sitios';

  @override
  String get homeWelcomeTagline => 'Tus estadísticas, de un vistazo.';

  @override
  String get homeWelcomeTitle => 'Conecta tu primera herramienta';

  @override
  String get homeWelcomeBody =>
      'Umami, Plausible… añade una fuente y elige los sitios que quieres seguir.';

  @override
  String get homeWelcomeAddSource => 'Añadir una fuente';

  @override
  String get homeWelcomeFootnote =>
      'Clave de solo lectura · tus datos se quedan contigo';

  @override
  String get homeSiteUnavailable => 'No disponible';

  @override
  String get detailVisitorsUnique => 'Visitantes únicos';

  @override
  String get detailKpiVisits => 'Visitas';

  @override
  String get detailKpiAvgDuration => 'Tiempo medio';

  @override
  String get detailKpiBounce => 'Rebote';

  @override
  String get detailLiveNow => 'Ahora mismo';

  @override
  String get detailLiveNobody => 'Nadie por ahora.';

  @override
  String get detailTabOverview => 'Resumen';

  @override
  String get detailTabEvents => 'Eventos';

  @override
  String get detailTabDashboards => 'Panel';

  @override
  String get detailEventsEmpty => 'Sin eventos en este periodo';

  @override
  String get detailEventsTriggered => 'Eventos registrados';

  @override
  String get detailEventsByEvent => 'Por evento';

  @override
  String detailSectionViewAll(int count) {
    return 'Ver las $count filas';
  }

  @override
  String get detailBadgeInternal => 'INTERNO';

  @override
  String get directEyebrow => 'Tiempo real';

  @override
  String get directTitle => 'En vivo';

  @override
  String get directNow => 'ahora mismo';

  @override
  String get directVisitorsAll => 'visitantes en todos tus sitios';

  @override
  String directVisitorsGroup(String name) {
    return 'visitantes en el grupo “$name”';
  }

  @override
  String get directBySite => 'Por sitio';

  @override
  String get directOnlyActive => 'Solo activos';

  @override
  String get directNoneLive => 'Ningún visitante en vivo por ahora.';

  @override
  String get directNoSites => 'Ningún sitio.';

  @override
  String directHiddenSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sitios sin visitantes ocultos',
      one: '1 sitio sin visitantes oculto',
    );
    return '$_temp0';
  }

  @override
  String networkExchanged(String period) {
    return 'Visitantes intercambiados · $period';
  }

  @override
  String networkPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sitios cargando…',
      one: '1 sitio cargando…',
    );
    return '$_temp0';
  }

  @override
  String get networkExplainer =>
      'Visitantes que llegaron a uno de tus sitios desde otro de tus sitios.';

  @override
  String get networkEmpty => 'Sin navegación interna en este periodo.';

  @override
  String get networkSenders => 'Quién envía';

  @override
  String get networkReceivers => 'Quién recibe';

  @override
  String get networkFlows => 'Flujos';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get dashboardsKindCounter => 'Contador';

  @override
  String get dashboardsKindRatio => 'Tasa';

  @override
  String get dashboardsKindFunnel => 'Embudo';

  @override
  String get dashboardsKindBreakdown => 'Desglose';

  @override
  String get dashboardsKindExternal => 'Métrica';

  @override
  String get dashboardsKindSites => 'Sitios';

  @override
  String get dashboardsMoveCard => 'Mover tarjeta';

  @override
  String get dashboardsCardOptions => 'Opciones de la tarjeta';

  @override
  String get dashboardsResizeCard => 'Cambiar tamaño de la tarjeta';

  @override
  String get dashboardsLoadFailed => 'No se pudo cargar.';

  @override
  String get dashboardsNoData => 'Sin datos en este periodo';

  @override
  String get dashboardsNoEvents => 'Sin eventos en este periodo';

  @override
  String dashboardsUnpublished(String date) {
    return 'Aún sin publicar: datos hasta el $date';
  }

  @override
  String get dashboardsPendingNow => 'Aún no medible en este periodo';

  @override
  String dashboardsPendingDelay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aún no medible: requiere $count días de margen',
      one: 'Aún no medible: requiere 1 día de margen',
    );
    return '$_temp0';
  }

  @override
  String dashboardsCohortOne(String date) {
    return 'Medido en la cohorte del $date';
  }

  @override
  String dashboardsCohortRange(String range) {
    return 'Medido en las cohortes $range';
  }

  @override
  String dashboardsFamilyMember(String member) {
    return '$member · se ajusta al periodo';
  }

  @override
  String dashboardsDataUntil(String date) {
    return 'Datos hasta el $date';
  }

  @override
  String dashboardsFunnelVisitors(String last, String first) {
    return '$last / $first visitantes';
  }

  @override
  String dashboardsCohortTooltip(String date, String cohort) {
    return '$date · cohorte del $cohort';
  }

  @override
  String get dashboardsTotal => 'Total';

  @override
  String dashboardsSegmentEstimated(String label) {
    return '$label · estimado';
  }

  @override
  String get dashboardsDeleted => 'Tarjeta eliminada';

  @override
  String get dashboardsConfirmDelete => 'Confirmar eliminación';

  @override
  String get dashboardsAllHidden =>
      'Ninguna tarjeta tiene datos en este periodo';

  @override
  String dashboardsHiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarjetas sin datos en este periodo',
      one: '1 tarjeta sin datos en este periodo',
    );
    return '$_temp0';
  }

  @override
  String get dashboardsShow => 'Mostrar';

  @override
  String get dashboardsArrangeHint =>
      'Mantén pulsada una tarjeta para moverla y arrastra su esquina para cambiar su tamaño.';

  @override
  String get dashboardsArrange => 'Organizar';

  @override
  String get dashboardsArrangeDone => 'Listo';

  @override
  String get dashboardsNew => 'Nueva tarjeta';

  @override
  String get dashboardsEmptyTitle => 'Aún no hay tarjetas';

  @override
  String get dashboardsEmptyBody =>
      'Sigue una tasa, un embudo o un desglose basado en tus eventos.';

  @override
  String get dashboardsCreate => 'Crear una tarjeta';

  @override
  String get dashboardsMetricsSource => 'Fuente de métricas';

  @override
  String get dashboardsMetricsIntro =>
      'Una pequeña API en tu sitio que ofrece indicadores calculados desde su base de datos (retención, cuentas…): un catálogo y series, protegidos con un token.';

  @override
  String get dashboardsMetricsHowItWorks => '¿Cómo funciona?';

  @override
  String get dashboardsMetricsUrlLabel => 'Dirección de la API';

  @override
  String get dashboardsMetricsUrlHint =>
      'https://example.com/api/internal/metrics/';

  @override
  String get dashboardsMetricsToken => 'Token';

  @override
  String get dashboardsMetricsTest => 'Probar';

  @override
  String dashboardsMetricsAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count indicadores disponibles',
      one: '1 indicador disponible',
    );
    return '$_temp0';
  }

  @override
  String get dashboardsMetricsSaved => 'Fuente guardada';

  @override
  String get dashboardsMetricsRemove => 'Quitar la fuente';

  @override
  String dashboardsMetricsRemoveWithCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarjetas',
      one: '1 tarjeta',
    );
    return 'Quitar la fuente y $_temp0';
  }

  @override
  String get dashboardsMetricsRemoved => 'Fuente quitada';

  @override
  String dashboardsMetricsRemovedWithCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarjetas eliminadas',
      one: '1 tarjeta eliminada',
    );
    return 'Fuente quitada, $_temp0';
  }

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonAdd => 'Añadir';

  @override
  String get commonSearch => 'Buscar';

  @override
  String get editorNameFallback => 'Sin título';

  @override
  String editorNameBy(String a, String b) {
    return '$a por $b';
  }

  @override
  String get editorErrChooseEvent => 'Elige un evento';

  @override
  String get editorErrChooseCountEvent => 'Elige el evento que contar';

  @override
  String get editorErrChooseRefEvent => 'Elige el evento de referencia';

  @override
  String get editorErrChooseProperty => 'Elige una propiedad';

  @override
  String get editorErrChooseMetric => 'Elige una métrica';

  @override
  String get editorErrAddSite => 'Añade al menos un sitio';

  @override
  String editorErrSitesMax(int max) {
    return 'Una tarjeta admite como máximo $max sitios';
  }

  @override
  String get editorErrChooseLineSite => 'Elige el sitio de cada línea';

  @override
  String get editorErrNameLines => 'Pon nombre a cada línea';

  @override
  String get editorErrReferrer => 'Introduce el dominio de referencia';

  @override
  String editorErrFunnelMin(int min) {
    return 'Un embudo tiene al menos $min pasos';
  }

  @override
  String editorErrFunnelMax(int max) {
    return 'Un embudo tiene como máximo $max pasos';
  }

  @override
  String editorErrStepEvent(int n) {
    return 'Elige el evento del paso $n';
  }

  @override
  String get editorErrFunnelNumeric =>
      'Un embudo no puede comparar números: quita este filtro';

  @override
  String get editorErrWindow => 'Límite de tiempo no válido';

  @override
  String get editorErrFilterValueMissing => 'Falta el valor del filtro';

  @override
  String get editorErrFilterNotNumber => 'El valor del filtro no es un número';

  @override
  String get editorTitleEdit => 'Editar tarjeta';

  @override
  String get editorFieldName => 'Nombre';

  @override
  String get editorHeadingType => 'Tipo';

  @override
  String get editorHeadingPreview => 'Vista previa';

  @override
  String get editorPreviewEmpty =>
      'La vista previa aparece en cuanto la tarjeta está completa.';

  @override
  String get editorCreated => 'Tarjeta creada';

  @override
  String get editorSaved => 'Tarjeta guardada';

  @override
  String get editorDelete => 'Eliminar esta tarjeta';

  @override
  String get editorCreate => 'Crear';

  @override
  String get editorCountLabel => 'Qué contar';

  @override
  String get editorRatioOf => 'Respecto a';

  @override
  String get editorGapsLabel => 'Dejar un hueco si no pasó nada';

  @override
  String get editorGapsHint => 'Si no, esos días cuentan como 0 %.';

  @override
  String get editorOverTimeLabel => 'Evolución en el tiempo';

  @override
  String get editorOverTimeHint => 'Una línea por valor, a todo el ancho';

  @override
  String get editorMetricLabel => 'Métrica';

  @override
  String get editorMetricPlaceholder => 'Elige una métrica';

  @override
  String get editorMetricNone => 'Esta fuente no ofrece indicadores.';

  @override
  String get editorMetricAdjusts => 'se ajusta al periodo';

  @override
  String get editorEventLabel => 'Evento';

  @override
  String get editorEventPlaceholder => 'Elige un evento';

  @override
  String get editorPropertyLabel => 'Propiedad';

  @override
  String get editorPropertyPlaceholder => 'Elige una propiedad';

  @override
  String get editorKindExternal => 'Métrica del sitio';

  @override
  String get editorKindHintCounter => 'Cuántas veces ocurre un evento';

  @override
  String get editorKindHintRatio => 'Un evento respecto a otro';

  @override
  String get editorKindHintFunnel => 'El recorrido, paso a paso';

  @override
  String get editorKindHintBreakdown => 'Los valores de una propiedad';

  @override
  String get editorKindHintExternal => 'Un indicador que ofrece tu API';

  @override
  String get editorKindHintSites => 'Visitantes de varios sitios';

  @override
  String get editorFunnelAddStep => 'Añadir un paso';

  @override
  String get editorFunnelWindowLabel => 'Tiempo máximo entre dos pasos';

  @override
  String editorFunnelWindowHint(int min, int max) {
    return 'En minutos ($min a $max): un visitante que tarda más en pasar de un paso al siguiente deja de contarse.';
  }

  @override
  String editorFunnelStep(int n) {
    return 'PASO $n';
  }

  @override
  String get editorFunnelMoveUp => 'Subir el paso';

  @override
  String get editorFunnelMoveDown => 'Bajar el paso';

  @override
  String get editorFunnelRemove => 'Quitar el paso';

  @override
  String get editorTypeText => 'texto';

  @override
  String get editorTypeNumber => 'número';

  @override
  String get editorTypeBoolean => 'sí/no';

  @override
  String get editorFreeEvent => 'Escribe el nombre de un evento';

  @override
  String get editorFreeProperty => 'Escribe el nombre de una propiedad';

  @override
  String get editorSiteLabel => 'Sitio';

  @override
  String editorUseTyped(String value) {
    return 'Usar “$value”';
  }

  @override
  String get editorListUnavailable =>
      'Lista no disponible: escribe el nombre a mano.';

  @override
  String get editorListEmpty =>
      'Nada visto en 30 días: escribe el nombre a mano.';

  @override
  String get editorAddFilter => 'Añadir un filtro';

  @override
  String get editorRemoveFilter => 'Quitar el filtro';

  @override
  String get editorFilterValue => 'Valor';

  @override
  String get editorTrue => 'verdadero';

  @override
  String get editorFalse => 'falso';

  @override
  String get editorModeAll => 'Todos';

  @override
  String get editorModeOnly => 'Desde';

  @override
  String get editorModeExcept => 'Salvo desde';

  @override
  String get editorLineSitePlaceholder => 'Elige un sitio';

  @override
  String get editorLineLabel => 'Etiqueta';

  @override
  String get editorLineReferrer => 'Dominio de referencia';

  @override
  String get editorLineAdd => 'Añadir un sitio';

  @override
  String get editorLinesHint =>
      'Visitantes únicos de cada línea. “Salvo desde” descarta los que el sitio recibió de ese dominio.';

  @override
  String editorLineTitle(int n) {
    return 'LÍNEA $n';
  }

  @override
  String get editorLineRemove => 'Quitar la línea';

  @override
  String commonSiteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sitios',
      one: '1 sitio',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsGroupAccount => 'Cuenta';

  @override
  String get settingsGroupSites => 'Sitios';

  @override
  String get settingsGroupSync => 'Sincronización';

  @override
  String get settingsGroupTransfer => 'Transferencia';

  @override
  String get settingsGroupAppearance => 'Apariencia';

  @override
  String get settingsGroupData => 'Datos';

  @override
  String get settingsGroupApp => 'App';

  @override
  String get settingsAccountBadAuth => 'Credenciales o clave de API rechazadas';

  @override
  String get settingsAccountUnreachable => 'Instancia inaccesible';

  @override
  String settingsAccountSubtitle(String provider, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sitios',
      one: '1 sitio',
    );
    return '$provider · $_temp0';
  }

  @override
  String get settingsAddSource => 'Añadir una fuente';

  @override
  String get settingsGroupsTitle => 'Grupos';

  @override
  String get settingsGroupsHint =>
      'Ver un subconjunto de tus sitios por separado';

  @override
  String get settingsSyncConnected => 'Sesión iniciada';

  @override
  String get settingsSyncPitch =>
      'Copia de seguridad y sincronización (cifrada)';

  @override
  String get settingsTransferShow => 'Mostrar un código QR de transferencia';

  @override
  String get settingsTransferNone => 'Ninguna cuenta que transferir';

  @override
  String get settingsTransferContents => 'Cuentas, credenciales y grupos';

  @override
  String get settingsTransferImport => 'Importar desde otro dispositivo';

  @override
  String get settingsTransferScan => 'Escanear un código QR de transferencia';

  @override
  String get settingsThemeTitle => 'Tema';

  @override
  String get settingsThemeAuto => 'Auto';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsChartsTitle => 'Gráficos';

  @override
  String get settingsChartsHint => 'Curva suave o barras';

  @override
  String get settingsChartCurve => 'Curva';

  @override
  String get settingsChartBars => 'Barras';

  @override
  String get settingsDefaultPeriod => 'Periodo predeterminado';

  @override
  String get settingsDefaultPeriodHint => 'Al abrir la app';

  @override
  String get settingsRefresh => 'Actualización automática';

  @override
  String settingsRefreshSeconds(int count) {
    return '$count s';
  }

  @override
  String settingsRefreshMinutes(int count) {
    return '$count min';
  }

  @override
  String get settingsCheckUpdates => 'Buscar actualizaciones';

  @override
  String get accountMenuConnectionOk => 'Conexión correcta';

  @override
  String accountMenuConnectionOkSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Conexión correcta · $count sitios',
      one: 'Conexión correcta · 1 sitio',
    );
    return '$_temp0';
  }

  @override
  String get accountMenuTest => 'Probar la conexión';

  @override
  String get accountMenuEdit => 'Editar la fuente';

  @override
  String get accountMenuEditHint => 'URL, credenciales, clave de API…';

  @override
  String get accountMenuChooseSites => 'Elegir sitios';

  @override
  String get accountMenuDelete => 'Eliminar esta cuenta';

  @override
  String get accountMenuDeleted => 'Fuente eliminada';

  @override
  String get accountMenuSelectionSaved => 'Selección guardada';

  @override
  String get accountSelectionAll => 'todos los sitios';

  @override
  String accountSelectionAllExcept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'todos menos $count sitios',
      one: 'todos menos 1 sitio',
    );
    return '$_temp0';
  }

  @override
  String get accountSelectionNone => 'ningún sitio';

  @override
  String get syncSubtitle => 'Tus cuentas y grupos, sincronizados y cifrados.';

  @override
  String get syncEmail => 'Correo electrónico';

  @override
  String get syncEmailHint => 'tu@ejemplo.com';

  @override
  String get syncPassword => 'Contraseña';

  @override
  String syncPasswordHint(int count) {
    return 'Al menos $count caracteres';
  }

  @override
  String get syncCreateAccount => 'Crear una cuenta';

  @override
  String get syncCreateAccountButton => 'Crear cuenta';

  @override
  String get syncSignIn => 'Iniciar sesión';

  @override
  String get syncHaveAccount => 'Ya tengo una cuenta';

  @override
  String get syncEncryptedNote =>
      'Tu configuración se cifra en tu dispositivo antes de enviarse, así que el servidor no puede leerla. Si olvidas tu contraseña, pierdes tu sincronización para siempre.';

  @override
  String get syncToastCreated => 'Cuenta creada';

  @override
  String get syncToastSignedIn => 'Sesión iniciada';

  @override
  String get syncToastSignedOut => 'Sesión cerrada';

  @override
  String get syncToastSynced => 'Sincronizado';

  @override
  String get syncToastDeleted => 'Cuenta eliminada';

  @override
  String get syncToastUnlocked => 'Glance Sync desbloqueado';

  @override
  String get syncToastRestored => 'Compra restaurada';

  @override
  String get syncNever => 'Nunca sincronizado';

  @override
  String syncLastSync(String date) {
    return 'Sincronizado $date';
  }

  @override
  String get syncNow => 'Sincronizar ahora';

  @override
  String get syncSignOut => 'Cerrar sesión';

  @override
  String get syncDeleteAccount => 'Eliminar mi cuenta';

  @override
  String get syncDeleteTitle => '¿Eliminar la cuenta?';

  @override
  String get syncDeleteBody =>
      'Tu cuenta de Glance Sync y toda la configuración sincronizada se eliminarán definitivamente del servidor. Esta acción no se puede deshacer. Tus fuentes de analytics se quedan en este dispositivo.';

  @override
  String get syncUnlockTitle => 'Desbloquear Glance Sync';

  @override
  String get syncUnlockBuy =>
      'Haz copias de seguridad y sincroniza tus cuentas y grupos en todos tus dispositivos. Compra única.';

  @override
  String get syncUnlockElsewhere =>
      'Compra única desde la app móvil (iOS/Android). Una vez desbloqueado, inicia sesión aquí con la misma cuenta y la sincronización se activa sola.';

  @override
  String get syncUnlockButton => 'Desbloquear';

  @override
  String get syncRestore => 'Restaurar una compra';

  @override
  String get syncSoon => 'Próximamente';

  @override
  String get transferExportTitle => 'Transferencia';

  @override
  String get transferExportSubtitle =>
      'Escanea este código desde el otro dispositivo.';

  @override
  String transferExpiresIn(String time) {
    return 'Caduca en $time';
  }

  @override
  String get transferCodeLabel =>
      'Código para introducir en el otro dispositivo';

  @override
  String get transferWarning =>
      'Este código contiene tus credenciales. No lo fotografíes ni lo compartas: el QR por sí solo no basta, pero junto con el código de 4 dígitos da acceso a tus cuentas.';

  @override
  String get transferExpiredTitle => 'Código caducado';

  @override
  String get transferExpiredBody =>
      'Una transferencia solo es válida durante unos minutos.';

  @override
  String get transferRegenerate => 'Nuevo código';

  @override
  String get transferTooLargeTitle => 'Configuración demasiado grande';

  @override
  String transferTooLargeBody(int size, int max) {
    return 'No cabe en un código QR ($size caracteres, máximo $max). Sigue “todos los sitios” en tus cuentas en lugar de una selección e inténtalo de nuevo.';
  }

  @override
  String get transferFailedTitle => 'Transferencia fallida';

  @override
  String get transferFailedBody => 'No se pudo preparar la transferencia.';

  @override
  String get transferImportTitle => 'Importar';

  @override
  String get transferImportScanHint =>
      'Apunta al código QR que se muestra en el otro dispositivo.';

  @override
  String get transferImportCodeHint =>
      'Introduce el código que aparece junto al código QR.';

  @override
  String get transferScanned => 'Código escaneado';

  @override
  String get transferCodeField => 'Código de 4 dígitos';

  @override
  String get transferImportButton => 'Importar';

  @override
  String get transferRescan => 'Escanear de nuevo';

  @override
  String transferImported(int accounts, int groups) {
    String _temp0 = intl.Intl.pluralLogic(
      accounts,
      locale: localeName,
      other: '$accounts cuentas',
      one: '1 cuenta',
    );
    String _temp1 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups grupos',
      one: '1 grupo',
    );
    return '$_temp0 y $_temp1 importados';
  }

  @override
  String get transferErrExpired =>
      'Este código ha caducado. Genera uno nuevo en el otro dispositivo.';

  @override
  String get transferErrBadCode => 'Código incorrecto.';

  @override
  String get transferErrFailed => 'Error al importar.';

  @override
  String get transferCameraDenied => 'Acceso a la cámara denegado';

  @override
  String get transferCameraUnavailable => 'Cámara no disponible';

  @override
  String get transferCameraDeniedBody =>
      'Permite el acceso a la cámara en los ajustes del sistema para escanear una transferencia.';

  @override
  String get transferCameraUnavailableBody =>
      'No hay ninguna cámara utilizable en este dispositivo.';

  @override
  String get groupsSubtitle =>
      'Una vista de algunos de tus sitios: los totales y el gráfico solo cuentan sus sitios.';

  @override
  String get groupsEmptyTitle => 'Sin grupos';

  @override
  String get groupsEmptyBody =>
      'Agrupa tus sitios, por ejemplo “Juegos” o “Clientes”, para ver sus estadísticas por separado.';

  @override
  String get groupsCreate => 'Crear un grupo';

  @override
  String get groupEditEditTitle => 'Editar grupo';

  @override
  String get groupEditName => 'Nombre';

  @override
  String get groupEditNameHint => 'Juegos, Clientes, Personal…';

  @override
  String get groupEditSitesLabel => 'Sitios del grupo';

  @override
  String get groupEditAddSourceHint => 'sus sitios se unen aquí';

  @override
  String get groupEditNoSites =>
      'Aún no sigues ningún sitio. Añade una fuente arriba para llenar este grupo.';

  @override
  String get groupEditCreateButton => 'Crear grupo';

  @override
  String get groupEditCreated => 'Grupo creado';

  @override
  String get groupEditSaved => 'Grupo guardado';

  @override
  String get groupEditDeleted => 'Grupo eliminado';

  @override
  String get groupEditDeleteTitle => '¿Eliminar este grupo?';

  @override
  String get groupEditDeleteBody =>
      'Los sitios y sus estadísticas no se ven afectados. Solo desaparece el grupo.';

  @override
  String get addSourceNewTitle => 'Nueva fuente';

  @override
  String get addSourceProvider => 'PROVEEDOR';

  @override
  String get addSourceName => 'Nombre (opcional)';

  @override
  String get addSourceNameHint => 'Mi dominio';

  @override
  String get addSourceTest => 'Probar la configuración';

  @override
  String get addSourceContinue => 'Continuar';

  @override
  String get addSourceMissingFields => 'Rellena los campos obligatorios.';

  @override
  String get addSourceTestOk => 'Conexión correcta.';

  @override
  String addSourceTestOkSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Conexión correcta · $count sitios encontrados',
      one: 'Conexión correcta · 1 sitio encontrado',
    );
    return '$_temp0';
  }

  @override
  String get addSourceNoSitesPlausible =>
      'Ningún sitio listado automáticamente: tu instancia no expone la API de listado (Plausible Community Edition). Introduce arriba el dominio que quieres seguir.';

  @override
  String get addSourceNoSites =>
      'No se encontró ningún sitio para esta cuenta.';

  @override
  String get addSourceKeyRejected =>
      'Clave de API rechazada (acceso a las estadísticas). Comprueba la clave de API.';

  @override
  String get addSourceCredsRejected => 'Credenciales rechazadas.';

  @override
  String get addSourceAdded => 'Fuente añadida';

  @override
  String get addSourceEdited => 'Fuente actualizada';

  @override
  String get sitePickerTitle => 'Elegir sitios';

  @override
  String sitePickerDetected(String provider, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sitios encontrados',
      one: '1 sitio encontrado',
    );
    return '$provider · $_temp0';
  }

  @override
  String get sitePickerFollowNew => 'Mostrar los sitios nuevos';

  @override
  String get sitePickerFollowNewHint =>
      'Un sitio creado más adelante aparece solo';

  @override
  String get sitePickerCurrent => 'Sitios actuales';

  @override
  String sitePickerShownOf(int shown, int total) {
    return '$shown de $total';
  }

  @override
  String get sitePickerCheckAll => 'Marcar todos';

  @override
  String get sitePickerUncheckAll => 'Desmarcar todos';

  @override
  String get sitePickerFollowAll => 'Seguir todos los sitios';

  @override
  String sitePickerFollowAndNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Seguir $count sitios y los nuevos',
      one: 'Seguir 1 sitio y los nuevos',
    );
    return '$_temp0';
  }

  @override
  String sitePickerFollow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Seguir $count sitios',
      one: 'Seguir 1 sitio',
    );
    return '$_temp0';
  }

  @override
  String get sitePickerShowNone => 'No mostrar ningún sitio';

  @override
  String get commonVisitors => 'Visitantes';

  @override
  String get commonPageviews => 'Vistas';

  @override
  String get commonNoData => 'Sin datos';

  @override
  String desktopSitesHeader(int count) {
    return 'Sitios ($count)';
  }

  @override
  String desktopHiddenCount(int count) {
    return '$count ocultos';
  }

  @override
  String get desktopShowAllSites => 'Mostrar todos los sitios';

  @override
  String get desktopHideEmptySites => 'Ocultar sitios sin visitantes';

  @override
  String get desktopLiveNobody => 'Nadie por ahora.';

  @override
  String get desktopKpiSites => 'Sitios';

  @override
  String desktopNoSitesGroupBody(String name) {
    return '“$name” no tiene sitios. Elige cuáles le pertenecen.';
  }

  @override
  String get desktopNoSitesBody =>
      'Tus cuentas aún no siguen ningún sitio. Elige los sitios que mostrar en los ajustes.';

  @override
  String get chartLegendForecast => 'Previsión';

  @override
  String get chartLegendPrevious => 'Periodo anterior';

  @override
  String get chartTooltipVisitors => 'visitantes';

  @override
  String get chartTooltipPageviews => 'vistas';

  @override
  String get chartTooltipForecast => 'previsión';

  @override
  String get chartTooltipPrevious => 'periodo anterior';

  @override
  String get chartNoSeries => 'Ninguna serie seleccionada';

  @override
  String chartHour(String hour) {
    return '$hour:00';
  }

  @override
  String get periodControlsDisplay => 'Vista';

  @override
  String get periodControlsSplit => 'Agrupar por';

  @override
  String get periodControlsChart => 'Gráfico';

  @override
  String get periodUnitHour => 'Hora';

  @override
  String get periodUnitDay => 'Día';

  @override
  String get periodUnitMonth => 'Mes';

  @override
  String get errorsAuthRefused => 'Credenciales rechazadas.';

  @override
  String get errorsRequestRefused => 'Solicitud rechazada por el servidor.';

  @override
  String get errorsNotFound => 'Instancia o API no encontrada.';

  @override
  String get errorsTimeout =>
      'Tiempo de espera agotado: la instancia va lenta o es inaccesible.';

  @override
  String get errorsUnreachable => 'Instancia inaccesible. Comprueba la URL.';

  @override
  String errorsServerCode(int code) {
    return 'Error del servidor $code.';
  }

  @override
  String get errorsConnectionFailed => 'No se pudo conectar.';

  @override
  String errorsGeneric(String detail) {
    return 'Error: $detail';
  }

  @override
  String get errUnsupportedIndicators => 'Indicadores no admitidos';

  @override
  String get errUnsupportedSiteTables => 'Tablas de sitios no admitidas';

  @override
  String get errUnsupportedFunnels => 'Embudos no admitidos';

  @override
  String get errUnsupportedBreakdowns => 'Desgloses no admitidos';

  @override
  String errOperatorUmamiFunnel(String op) {
    return 'El operador “$op” no está disponible en un embudo de Umami';
  }

  @override
  String errOperatorPlausible(String op) {
    return 'El operador “$op” no está disponible en Plausible (solo propiedades de texto)';
  }

  @override
  String get errFathomSoon => 'Fathom llegará pronto.';

  @override
  String get errPlausibleNeedsSite =>
      'Introduce un dominio, o un correo y una contraseña para listar tus sitios automáticamente.';

  @override
  String get errUmamiLoginUnexpected =>
      'Respuesta de inicio de sesión de Umami inesperada';

  @override
  String errBucketsTooFine(int count) {
    return 'Agrupación demasiado fina: más de $count puntos en el periodo.';
  }

  @override
  String get errMetricsNotConfigured => 'Fuente no configurada en el servidor';

  @override
  String get errMetricsBadToken => 'Token rechazado';

  @override
  String errMetricsBadRequest(String code) {
    return 'Solicitud rechazada ($code)';
  }

  @override
  String get errMetricsUnsupportedVersion => 'Versión de la API no admitida';

  @override
  String get errMetricsUnexpected => 'Respuesta inesperada del servidor';

  @override
  String get syncMsgUnreachable => 'Servidor inaccesible. Inténtalo de nuevo.';

  @override
  String get syncMsgSessionExpired =>
      'Sesión caducada. Inicia sesión de nuevo y reintenta.';

  @override
  String get syncMsgPurchaseFailed =>
      'La compra ha fallado. Inténtalo de nuevo.';

  @override
  String get syncMsgPurchasePending =>
      'Compra confirmada: activación en curso, reintenta la sincronización en un momento.';

  @override
  String get syncMsgNothingToRestore => 'No hay ninguna compra que restaurar.';

  @override
  String get syncMsgRestorePending => 'Compra restaurada: activación en curso…';

  @override
  String get syncMsgCannotDecrypt =>
      'No se pudo descifrar la configuración remota.';

  @override
  String get syncMsgProRequired =>
      'La sincronización está reservada a Glance Sync (Pro).';

  @override
  String get syncMsgBadCredentials => 'Correo o contraseña incorrectos.';

  @override
  String syncMsgPasswordTooShort(int count) {
    return 'Contraseña demasiado corta: mínimo $count caracteres.';
  }

  @override
  String get syncMsgPasswordTooLong => 'Contraseña demasiado larga.';

  @override
  String get syncMsgInvalidEmail => 'Dirección de correo no válida.';

  @override
  String get syncMsgAccountExists =>
      'Este correo ya tiene una cuenta: inicia sesión.';

  @override
  String get syncMsgSignUpFailed => 'No se pudo crear la cuenta.';

  @override
  String get periodToday => 'Hoy';

  @override
  String get period24h => '24 h';

  @override
  String get period7d => '7 días';

  @override
  String get period30d => '30 d';

  @override
  String get periodThisMonth => 'Este mes';

  @override
  String get period12m => '12 m';

  @override
  String get periodThisYear => 'Este año';

  @override
  String get periodAllTime => 'Todo';

  @override
  String get periodCustom => 'Rango';

  @override
  String get metricTypePages => 'Rutas';

  @override
  String get metricTypeEntry => 'Entrada';

  @override
  String get metricTypeExit => 'Salida';

  @override
  String get metricTypeTitle => 'Título';

  @override
  String get metricTypeReferrers => 'Referidos';

  @override
  String get metricTypeChannels => 'Canales';

  @override
  String get metricTypeQueries => 'Consultas';

  @override
  String get metricTypeBrowsers => 'Navegadores';

  @override
  String get metricTypeOs => 'Sistema';

  @override
  String get metricTypeDevices => 'Dispositivos';

  @override
  String get metricTypeScreens => 'Pantallas';

  @override
  String get metricTypeCountries => 'Países';

  @override
  String get metricTypeRegions => 'Regiones';

  @override
  String get metricTypeCities => 'Ciudades';

  @override
  String get metricTypeLanguages => 'Idiomas';

  @override
  String get metricTypeEvents => 'Eventos';

  @override
  String get metricSectionPages => 'Páginas';

  @override
  String get metricSectionSources => 'Fuentes';

  @override
  String get metricSectionEnvironment => 'Entorno';

  @override
  String get metricSectionLocation => 'Ubicación';

  @override
  String get filterOpContains => 'contiene';

  @override
  String get filterOpNotContains => 'no contiene';

  @override
  String get entityUnknown => 'Desconocido';

  @override
  String get entityReferrerDirect => 'Directo';

  @override
  String get entityBrowserSearchBot => 'Bot de búsqueda';

  @override
  String get entityDeviceDesktop => 'Escritorio';

  @override
  String get entityDeviceLaptop => 'Portátil';

  @override
  String get entityDeviceTablet => 'Tableta';

  @override
  String get entityDeviceMobile => 'Móvil';

  @override
  String get entityDeviceWearable => 'Reloj';

  @override
  String get entityDeviceConsole => 'Consola';

  @override
  String get entityDeviceTv => 'TV';

  @override
  String get channelDirect => 'Directo';

  @override
  String get channelReferral => 'Referencia';

  @override
  String get channelAffiliate => 'Afiliado';

  @override
  String get channelEmail => 'Email';

  @override
  String get channelOrganicSearch => 'Búsqueda orgánica';

  @override
  String get channelOrganicSocial => 'Social orgánico';

  @override
  String get channelOrganicShopping => 'Compras orgánicas';

  @override
  String get channelOrganicVideo => 'Video orgánico';

  @override
  String get channelPaidAds => 'Anuncios de pago';

  @override
  String get channelPaidSearch => 'Búsqueda de pago';

  @override
  String get channelPaidSocial => 'Social de pago';

  @override
  String get channelPaidShopping => 'Compras de pago';

  @override
  String get channelPaidVideo => 'Video de pago';

  @override
  String get credInstanceUrl => 'URL de la instancia';

  @override
  String get credUmamiUrlPlaceholder => 'analytics.tudominio.com';

  @override
  String get credUsername => 'Nombre de usuario';

  @override
  String get credPassword => 'Contraseña';

  @override
  String get credApiKey => 'Clave de API';

  @override
  String get credEmailOptional => 'Correo de la cuenta (opcional)';

  @override
  String get credEmailPlaceholder => 'tu@ejemplo.com';

  @override
  String get credEmailHint =>
      'Correo + contraseña: Glance lista tus sitios automáticamente. Si no, déjalo en blanco e introduce un dominio abajo.';

  @override
  String get credPasswordOptional => 'Contraseña (opcional)';

  @override
  String get credDomainFallback => 'Dominio (si no hay correo ni contraseña)';

  @override
  String get credDomainPlaceholder => 'tudominio.com';
}
