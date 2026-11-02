// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get settingsLanguageTitle => 'Sprache';

  @override
  String get settingsLanguageAuto => 'Automatisch';

  @override
  String dayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonClear => 'Löschen';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get tabSites => 'Websites';

  @override
  String get tabDirect => 'Live';

  @override
  String get tabSettings => 'Einstellungen';

  @override
  String get siteSearchHint => 'Website suchen';

  @override
  String siteSearchNoMatch(String query) {
    return 'Keine Website passt zu „$query“.';
  }

  @override
  String get navToday => 'Heute';

  @override
  String get navYesterday => 'Gestern';

  @override
  String get navDayBeforeYesterday => 'Vorgestern';

  @override
  String get navThisMonth => 'Dieser Monat';

  @override
  String get navLastMonth => 'Letzter Monat';

  @override
  String get navThisYear => 'Dieses Jahr';

  @override
  String get navLastYear => 'Letztes Jahr';

  @override
  String get workspaceSheetTitle => 'Bereich';

  @override
  String get workspaceAllSites => 'Alle Websites';

  @override
  String workspaceTrackedSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Websites verfolgt',
      one: '1 Website verfolgt',
      zero: '0 Websites verfolgt',
    );
    return '$_temp0';
  }

  @override
  String workspaceSiteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Websites',
      one: '1 Website',
      zero: 'Keine Websites',
    );
    return '$_temp0';
  }

  @override
  String get workspaceNewGroup => 'Neue Gruppe';

  @override
  String get workspaceManageGroups => 'Gruppen verwalten';

  @override
  String get homeTitleDefault => 'Meine Websites';

  @override
  String get homeLoadFailed => 'Laden nicht möglich.';

  @override
  String get homeInternalTitle => 'Zwischen Ihren Websites';

  @override
  String homeTotalVisitors(String name) {
    return 'Besucher · $name';
  }

  @override
  String get homeTotalVisitorsAll => 'Besucher · alle Websites';

  @override
  String get homeVsPrevious => 'ggü. Vorperiode';

  @override
  String homeLiveCount(int count) {
    return '$count live';
  }

  @override
  String get homeEmptyTitle => 'Keine Website angezeigt';

  @override
  String get homeEmptyBody =>
      'Noch keine Websites verfolgt. Wählen Sie die anzuzeigenden aus.';

  @override
  String get homeEmptyChooseSites => 'Websites wählen';

  @override
  String get homeEmptyAddSource => '+ Quelle hinzufügen';

  @override
  String get homeEmptyGroupTitle => 'Leere Gruppe';

  @override
  String homeEmptyGroupBody(String name) {
    return '„$name“ enthält keine Websites.';
  }

  @override
  String get homeEmptyGroupChoose => 'Websites wählen';

  @override
  String get homeEmptyGroupSeeAll => 'Alle Websites anzeigen';

  @override
  String get homeWelcomeTagline => 'Ihre Statistiken auf einen Blick.';

  @override
  String get homeWelcomeTitle => 'Verbinden Sie Ihr erstes Tool';

  @override
  String get homeWelcomeBody =>
      'Umami, Plausible… Fügen Sie eine Quelle hinzu und wählen Sie dann die zu verfolgenden Websites.';

  @override
  String get homeWelcomeAddSource => 'Quelle hinzufügen';

  @override
  String get homeWelcomeFootnote =>
      'Schreibgeschützter Schlüssel · Ihre Daten bleiben bei Ihnen';

  @override
  String get homeSiteUnavailable => 'Nicht verfügbar';

  @override
  String get detailVisitorsUnique => 'Eindeutige Besucher';

  @override
  String get detailKpiVisits => 'Besuche';

  @override
  String get detailKpiAvgDuration => 'Ø Dauer';

  @override
  String get detailKpiBounce => 'Absprungrate';

  @override
  String get detailLiveNow => 'Jetzt live';

  @override
  String get detailLiveNobody => 'Im Moment niemand.';

  @override
  String get detailTabOverview => 'Übersicht';

  @override
  String get detailTabEvents => 'Ereignisse';

  @override
  String get detailTabDashboards => 'Dashboard';

  @override
  String get detailEventsEmpty => 'Keine Ereignisse in diesem Zeitraum';

  @override
  String get detailEventsTriggered => 'Ausgelöste Ereignisse';

  @override
  String get detailEventsByEvent => 'Nach Ereignis';

  @override
  String detailSectionViewAll(int count) {
    return 'Alle $count Zeilen anzeigen';
  }

  @override
  String get detailBadgeInternal => 'INTERN';

  @override
  String get directEyebrow => 'Echtzeit';

  @override
  String get directTitle => 'Live';

  @override
  String get directNow => 'gerade jetzt';

  @override
  String get directVisitorsAll => 'Besucher auf allen Ihren Websites';

  @override
  String directVisitorsGroup(String name) {
    return 'Besucher in der Gruppe „$name“';
  }

  @override
  String get directBySite => 'Nach Website';

  @override
  String get directOnlyActive => 'Nur aktive';

  @override
  String get directNoneLive => 'Im Moment keine Besucher live.';

  @override
  String get directNoSites => 'Keine Websites.';

  @override
  String directHiddenSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Websites ohne Besucher ausgeblendet',
      one: '1 Website ohne Besucher ausgeblendet',
    );
    return '$_temp0';
  }

  @override
  String networkExchanged(String period) {
    return 'Ausgetauschte Besucher · $period';
  }

  @override
  String networkPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Websites laden…',
      one: '1 Website lädt…',
    );
    return '$_temp0';
  }

  @override
  String get networkExplainer =>
      'Besucher, die von einer Ihrer Websites auf eine andere Ihrer Websites gelangt sind.';

  @override
  String get networkEmpty => 'Keine interne Navigation in diesem Zeitraum.';

  @override
  String get networkSenders => 'Sender';

  @override
  String get networkReceivers => 'Empfänger';

  @override
  String get networkFlows => 'Ströme';

  @override
  String get commonEdit => 'Bearbeiten';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get dashboardsKindCounter => 'Zähler';

  @override
  String get dashboardsKindRatio => 'Rate';

  @override
  String get dashboardsKindFunnel => 'Funnel';

  @override
  String get dashboardsKindBreakdown => 'Aufschlüsselung';

  @override
  String get dashboardsKindExternal => 'Metrik';

  @override
  String get dashboardsKindSites => 'Websites';

  @override
  String get dashboardsMoveCard => 'Karte verschieben';

  @override
  String get dashboardsCardOptions => 'Kartenoptionen';

  @override
  String get dashboardsResizeCard => 'Kartengröße ändern';

  @override
  String get dashboardsLoadFailed => 'Laden nicht möglich.';

  @override
  String get dashboardsNoData => 'Keine Daten für diesen Zeitraum';

  @override
  String get dashboardsNoEvents => 'Keine Ereignisse im Zeitraum';

  @override
  String dashboardsUnpublished(String date) {
    return 'Noch nicht veröffentlicht: Daten bis $date';
  }

  @override
  String get dashboardsPendingNow => 'Für diesen Zeitraum noch nicht messbar';

  @override
  String dashboardsPendingDelay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch nicht messbar: $count Tage Abstand nötig',
      one: 'Noch nicht messbar: 1 Tag Abstand nötig',
    );
    return '$_temp0';
  }

  @override
  String dashboardsCohortOne(String date) {
    return 'Gemessen an der Kohorte vom $date';
  }

  @override
  String dashboardsCohortRange(String range) {
    return 'Gemessen an den Kohorten $range';
  }

  @override
  String dashboardsFamilyMember(String member) {
    return '$member · passt sich dem Zeitraum an';
  }

  @override
  String dashboardsDataUntil(String date) {
    return 'Daten bis $date';
  }

  @override
  String dashboardsFunnelVisitors(String last, String first) {
    return '$last / $first Besucher';
  }

  @override
  String dashboardsCohortTooltip(String date, String cohort) {
    return '$date · Kohorte vom $cohort';
  }

  @override
  String get dashboardsTotal => 'Gesamt';

  @override
  String dashboardsSegmentEstimated(String label) {
    return '$label · geschätzt';
  }

  @override
  String get dashboardsDeleted => 'Karte gelöscht';

  @override
  String get dashboardsConfirmDelete => 'Löschen bestätigen';

  @override
  String get dashboardsAllHidden => 'Keine Karte hat Daten für diesen Zeitraum';

  @override
  String dashboardsHiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Karten ohne Daten in diesem Zeitraum',
      one: '1 Karte ohne Daten in diesem Zeitraum',
    );
    return '$_temp0';
  }

  @override
  String get dashboardsShow => 'Anzeigen';

  @override
  String get dashboardsArrangeHint =>
      'Karte gedrückt halten, um sie zu verschieben; an der Ecke ziehen, um die Größe zu ändern.';

  @override
  String get dashboardsArrange => 'Anordnen';

  @override
  String get dashboardsArrangeDone => 'Fertig';

  @override
  String get dashboardsNew => 'Neue Karte';

  @override
  String get dashboardsEmptyTitle => 'Noch keine Karten';

  @override
  String get dashboardsEmptyBody =>
      'Verfolgen Sie eine Rate, einen Funnel oder eine Aufschlüsselung auf Basis Ihrer Ereignisse.';

  @override
  String get dashboardsCreate => 'Karte erstellen';

  @override
  String get dashboardsMetricsSource => 'Metrikquelle';

  @override
  String get dashboardsMetricsIntro =>
      'Eine kleine API Ihrer Website, die aus ihrer Datenbank berechnete Kennzahlen liefert (Nutzerbindung, Konten…): ein Katalog und Zeitreihen, durch ein Token geschützt.';

  @override
  String get dashboardsMetricsHowItWorks => 'Wie funktioniert das?';

  @override
  String get dashboardsMetricsUrlLabel => 'API-Adresse';

  @override
  String get dashboardsMetricsUrlHint =>
      'https://beispiel.de/api/intern/metriken/';

  @override
  String get dashboardsMetricsToken => 'Token';

  @override
  String get dashboardsMetricsTest => 'Testen';

  @override
  String dashboardsMetricsAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kennzahlen verfügbar',
      one: '1 Kennzahl verfügbar',
    );
    return '$_temp0';
  }

  @override
  String get dashboardsMetricsSaved => 'Quelle gespeichert';

  @override
  String get dashboardsMetricsRemove => 'Quelle entfernen';

  @override
  String dashboardsMetricsRemoveWithCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Karten',
      one: '1 Karte',
    );
    return 'Quelle und $_temp0 entfernen';
  }

  @override
  String get dashboardsMetricsRemoved => 'Quelle entfernt';

  @override
  String dashboardsMetricsRemovedWithCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Karten gelöscht',
      one: '1 Karte gelöscht',
    );
    return 'Quelle entfernt, $_temp0';
  }

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonAdd => 'Hinzufügen';

  @override
  String get commonSearch => 'Suchen';

  @override
  String get editorNameFallback => 'Ohne Titel';

  @override
  String editorNameBy(String a, String b) {
    return '$a nach $b';
  }

  @override
  String get editorErrChooseEvent => 'Wählen Sie ein Ereignis';

  @override
  String get editorErrChooseCountEvent => 'Wählen Sie das zu zählende Ereignis';

  @override
  String get editorErrChooseRefEvent => 'Wählen Sie das Bezugsereignis';

  @override
  String get editorErrChooseProperty => 'Wählen Sie eine Eigenschaft';

  @override
  String get editorErrChooseMetric => 'Wählen Sie eine Metrik';

  @override
  String get editorErrAddSite => 'Fügen Sie mindestens eine Website hinzu';

  @override
  String editorErrSitesMax(int max) {
    return 'Eine Karte hat höchstens $max Websites';
  }

  @override
  String get editorErrChooseLineSite => 'Wählen Sie die Website jeder Zeile';

  @override
  String get editorErrNameLines => 'Benennen Sie jede Zeile';

  @override
  String get editorErrReferrer => 'Geben Sie die Referrer-Domain an';

  @override
  String editorErrFunnelMin(int min) {
    return 'Ein Funnel hat mindestens $min Schritte';
  }

  @override
  String editorErrFunnelMax(int max) {
    return 'Ein Funnel hat höchstens $max Schritte';
  }

  @override
  String editorErrStepEvent(int n) {
    return 'Wählen Sie das Ereignis für Schritt $n';
  }

  @override
  String get editorErrFunnelNumeric =>
      'Ein Funnel vergleicht keine Zahlen: Entfernen Sie diesen Filter';

  @override
  String get editorErrWindow => 'Ungültiges Zeitfenster';

  @override
  String get editorErrFilterValueMissing => 'Filterwert fehlt';

  @override
  String get editorErrFilterNotNumber => 'Filterwert ist keine Zahl';

  @override
  String get editorTitleEdit => 'Karte bearbeiten';

  @override
  String get editorFieldName => 'Name';

  @override
  String get editorHeadingType => 'Typ';

  @override
  String get editorHeadingPreview => 'Vorschau';

  @override
  String get editorPreviewEmpty =>
      'Die Vorschau erscheint, sobald die Karte vollständig ist.';

  @override
  String get editorCreated => 'Karte erstellt';

  @override
  String get editorSaved => 'Karte gespeichert';

  @override
  String get editorDelete => 'Diese Karte löschen';

  @override
  String get editorCreate => 'Erstellen';

  @override
  String get editorCountLabel => 'Was gezählt wird';

  @override
  String get editorRatioOf => 'Bezogen auf';

  @override
  String get editorGapsLabel => 'Lücke lassen, wenn nichts passiert ist';

  @override
  String get editorGapsHint => 'Sonst zählen diese Tage als 0 %.';

  @override
  String get editorOverTimeLabel => 'Verlauf über die Zeit';

  @override
  String get editorOverTimeHint => 'Eine Linie pro Wert, über die volle Breite';

  @override
  String get editorMetricLabel => 'Metrik';

  @override
  String get editorMetricPlaceholder => 'Metrik wählen';

  @override
  String get editorMetricNone => 'Diese Quelle bietet keine Kennzahlen.';

  @override
  String get editorMetricAdjusts => 'passt sich dem Zeitraum an';

  @override
  String get editorEventLabel => 'Ereignis';

  @override
  String get editorEventPlaceholder => 'Ereignis wählen';

  @override
  String get editorPropertyLabel => 'Eigenschaft';

  @override
  String get editorPropertyPlaceholder => 'Eigenschaft wählen';

  @override
  String get editorKindExternal => 'Website-Metrik';

  @override
  String get editorKindHintCounter => 'Wie oft ein Ereignis eintritt';

  @override
  String get editorKindHintRatio =>
      'Ein Ereignis im Verhältnis zu einem anderen';

  @override
  String get editorKindHintFunnel => 'Der Weg, Schritt für Schritt';

  @override
  String get editorKindHintBreakdown => 'Die Werte einer Eigenschaft';

  @override
  String get editorKindHintExternal => 'Eine Kennzahl aus Ihrer API';

  @override
  String get editorKindHintSites => 'Besucher mehrerer Websites';

  @override
  String get editorFunnelAddStep => 'Schritt hinzufügen';

  @override
  String get editorFunnelWindowLabel => 'Maximale Zeit zwischen zwei Schritten';

  @override
  String editorFunnelWindowHint(int min, int max) {
    return 'In Minuten ($min bis $max): Wer länger von einem Schritt zum nächsten braucht, wird nicht mehr gezählt.';
  }

  @override
  String editorFunnelStep(int n) {
    return 'SCHRITT $n';
  }

  @override
  String get editorFunnelMoveUp => 'Schritt nach oben';

  @override
  String get editorFunnelMoveDown => 'Schritt nach unten';

  @override
  String get editorFunnelRemove => 'Schritt entfernen';

  @override
  String get editorTypeText => 'Text';

  @override
  String get editorTypeNumber => 'Zahl';

  @override
  String get editorTypeBoolean => 'Ja/Nein';

  @override
  String get editorFreeEvent => 'Ereignisnamen eingeben';

  @override
  String get editorFreeProperty => 'Eigenschaftsnamen eingeben';

  @override
  String get editorSiteLabel => 'Website';

  @override
  String editorUseTyped(String value) {
    return '„$value“ verwenden';
  }

  @override
  String get editorListUnavailable =>
      'Liste nicht verfügbar — geben Sie den Namen manuell ein.';

  @override
  String get editorListEmpty =>
      'In 30 Tagen nichts gesehen — geben Sie den Namen manuell ein.';

  @override
  String get editorAddFilter => 'Filter hinzufügen';

  @override
  String get editorRemoveFilter => 'Filter entfernen';

  @override
  String get editorFilterValue => 'Wert';

  @override
  String get editorTrue => 'wahr';

  @override
  String get editorFalse => 'falsch';

  @override
  String get editorModeAll => 'Alle';

  @override
  String get editorModeOnly => 'Von';

  @override
  String get editorModeExcept => 'Außer von';

  @override
  String get editorLineSitePlaceholder => 'Website wählen';

  @override
  String get editorLineLabel => 'Bezeichnung';

  @override
  String get editorLineReferrer => 'Referrer-Domain';

  @override
  String get editorLineAdd => 'Website hinzufügen';

  @override
  String get editorLinesHint =>
      'Eindeutige Besucher je Zeile. „Außer von“ zieht die Besucher ab, die die Website von dieser Domain erhalten hat.';

  @override
  String editorLineTitle(int n) {
    return 'ZEILE $n';
  }

  @override
  String get editorLineRemove => 'Zeile entfernen';

  @override
  String commonSiteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Websites',
      one: '1 Website',
      zero: '0 Websites',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsGroupAccount => 'Konto';

  @override
  String get settingsGroupSites => 'Websites';

  @override
  String get settingsGroupSync => 'Synchronisierung';

  @override
  String get settingsGroupTransfer => 'Übertragung';

  @override
  String get settingsGroupAppearance => 'Darstellung';

  @override
  String get settingsGroupData => 'Daten';

  @override
  String get settingsGroupApp => 'App';

  @override
  String get settingsAccountBadAuth =>
      'Zugangsdaten oder API-Schlüssel abgelehnt';

  @override
  String get settingsAccountUnreachable => 'Instanz nicht erreichbar';

  @override
  String settingsAccountSubtitle(String provider, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Websites',
      one: '1 Website',
      zero: '0 Websites',
    );
    return '$provider · $_temp0';
  }

  @override
  String get settingsAddSource => 'Quelle hinzufügen';

  @override
  String get settingsGroupsTitle => 'Gruppen';

  @override
  String get settingsGroupsHint => 'Einen Teil Ihrer Websites separat ansehen';

  @override
  String get settingsSyncConnected => 'Angemeldet';

  @override
  String get settingsSyncPitch => 'Sichern und synchronisieren (verschlüsselt)';

  @override
  String get settingsTransferShow => 'Übertragungs-QR-Code anzeigen';

  @override
  String get settingsTransferNone => 'Kein Konto zu übertragen';

  @override
  String get settingsTransferContents => 'Konten, Zugangsdaten und Gruppen';

  @override
  String get settingsTransferImport => 'Von einem anderen Gerät importieren';

  @override
  String get settingsTransferScan => 'Übertragungs-QR-Code scannen';

  @override
  String get settingsThemeTitle => 'Design';

  @override
  String get settingsThemeAuto => 'Auto';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsChartsTitle => 'Diagramme';

  @override
  String get settingsChartsHint => 'Geglättete Kurve oder Balken';

  @override
  String get settingsChartCurve => 'Kurve';

  @override
  String get settingsChartBars => 'Balken';

  @override
  String get settingsDefaultPeriod => 'Standardzeitraum';

  @override
  String get settingsDefaultPeriodHint => 'Beim Öffnen der App';

  @override
  String get settingsRefresh => 'Auto-Aktualisierung';

  @override
  String settingsRefreshSeconds(int count) {
    return '$count Sek.';
  }

  @override
  String settingsRefreshMinutes(int count) {
    return '$count Min.';
  }

  @override
  String get settingsCheckUpdates => 'Nach Updates suchen';

  @override
  String get accountMenuConnectionOk => 'Verbindung erfolgreich';

  @override
  String accountMenuConnectionOkSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verbindung erfolgreich · $count Websites',
      one: 'Verbindung erfolgreich · 1 Website',
    );
    return '$_temp0';
  }

  @override
  String get accountMenuTest => 'Verbindung testen';

  @override
  String get accountMenuEdit => 'Quelle bearbeiten';

  @override
  String get accountMenuEditHint => 'URL, Zugangsdaten, API-Schlüssel…';

  @override
  String get accountMenuChooseSites => 'Websites wählen';

  @override
  String get accountMenuDelete => 'Dieses Konto löschen';

  @override
  String get accountMenuDeleted => 'Quelle gelöscht';

  @override
  String get accountMenuSelectionSaved => 'Auswahl gespeichert';

  @override
  String get accountSelectionAll => 'alle Websites';

  @override
  String accountSelectionAllExcept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'alle außer $count Websites',
      one: 'alle außer 1 Website',
    );
    return '$_temp0';
  }

  @override
  String get accountSelectionNone => 'keine Websites';

  @override
  String get syncSubtitle =>
      'Ihre Konten und Gruppen, synchronisiert und verschlüsselt.';

  @override
  String get syncEmail => 'E-Mail';

  @override
  String get syncEmailHint => 'sie@beispiel.de';

  @override
  String get syncPassword => 'Passwort';

  @override
  String syncPasswordHint(int count) {
    return 'Mindestens $count Zeichen';
  }

  @override
  String get syncCreateAccount => 'Konto erstellen';

  @override
  String get syncCreateAccountButton => 'Konto erstellen';

  @override
  String get syncSignIn => 'Anmelden';

  @override
  String get syncHaveAccount => 'Ich habe schon ein Konto';

  @override
  String get syncEncryptedNote =>
      'Ihre Konfiguration wird vor dem Senden auf dem Gerät verschlüsselt: Der Server kann sie nicht lesen. Passwort vergessen = Sync unwiederbringlich verloren.';

  @override
  String get syncToastCreated => 'Konto erstellt';

  @override
  String get syncToastSignedIn => 'Angemeldet';

  @override
  String get syncToastSignedOut => 'Abgemeldet';

  @override
  String get syncToastSynced => 'Synchronisiert';

  @override
  String get syncToastDeleted => 'Konto gelöscht';

  @override
  String get syncToastUnlocked => 'Glance Sync freigeschaltet';

  @override
  String get syncToastRestored => 'Kauf wiederhergestellt';

  @override
  String get syncNever => 'Nie synchronisiert';

  @override
  String syncLastSync(String date) {
    return 'Sync $date';
  }

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String get syncSignOut => 'Abmelden';

  @override
  String get syncDeleteAccount => 'Mein Konto löschen';

  @override
  String get syncDeleteTitle => 'Konto löschen?';

  @override
  String get syncDeleteBody =>
      'Ihr Glance-Sync-Konto und die gesamte synchronisierte Konfiguration werden unwiderruflich vom Server gelöscht. Das lässt sich nicht rückgängig machen. Ihre Analytics-Quellen bleiben auf diesem Gerät.';

  @override
  String get syncUnlockTitle => 'Glance Sync freischalten';

  @override
  String get syncUnlockBuy =>
      'Sichern und synchronisieren Sie Ihre Konten und Gruppen auf allen Ihren Geräten. Einmalkauf.';

  @override
  String get syncUnlockElsewhere =>
      'Einmalkauf in der mobilen App (iOS/Android). Nach der Freischaltung melden Sie sich hier mit demselben Konto an: Die Synchronisierung folgt automatisch.';

  @override
  String get syncUnlockButton => 'Freischalten';

  @override
  String get syncRestore => 'Kauf wiederherstellen';

  @override
  String get syncSoon => 'Demnächst verfügbar';

  @override
  String get transferExportTitle => 'Übertragen';

  @override
  String get transferExportSubtitle =>
      'Scannen Sie diesen Code mit dem anderen Gerät.';

  @override
  String transferExpiresIn(String time) {
    return 'Läuft ab in $time';
  }

  @override
  String get transferCodeLabel => 'Code für das andere Gerät';

  @override
  String get transferWarning =>
      'Dieser Code enthält Ihre Zugangsdaten. Fotografieren und teilen Sie ihn nicht: Der QR-Code allein genügt nicht, aber zusammen mit dem 4-stelligen Code gewährt er Zugriff auf Ihre Konten.';

  @override
  String get transferExpiredTitle => 'Code abgelaufen';

  @override
  String get transferExpiredBody =>
      'Eine Übertragung ist nur wenige Minuten gültig.';

  @override
  String get transferRegenerate => 'Neuer Code';

  @override
  String get transferTooLargeTitle => 'Konfiguration zu groß';

  @override
  String transferTooLargeBody(int size, int max) {
    return 'Sie passt nicht in einen QR-Code ($size Zeichen, höchstens $max). Folgen Sie in Ihren Konten „allen Websites“ statt einer Auswahl und versuchen Sie es erneut.';
  }

  @override
  String get transferFailedTitle => 'Übertragung nicht möglich';

  @override
  String get transferFailedBody =>
      'Die Übertragung konnte nicht vorbereitet werden.';

  @override
  String get transferImportTitle => 'Importieren';

  @override
  String get transferImportScanHint =>
      'Richten Sie die Kamera auf den QR-Code des anderen Geräts.';

  @override
  String get transferImportCodeHint =>
      'Geben Sie den Code ein, der neben dem QR-Code steht.';

  @override
  String get transferScanned => 'Code gescannt';

  @override
  String get transferCodeField => '4-stelliger Code';

  @override
  String get transferImportButton => 'Importieren';

  @override
  String get transferRescan => 'Erneut scannen';

  @override
  String transferImported(int accounts, int groups) {
    String _temp0 = intl.Intl.pluralLogic(
      accounts,
      locale: localeName,
      other: '$accounts Konten',
      one: '1 Konto',
    );
    String _temp1 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups Gruppen',
      one: '1 Gruppe',
      zero: '0 Gruppen',
    );
    return '$_temp0 und $_temp1 importiert';
  }

  @override
  String get transferErrExpired =>
      'Dieser Code ist abgelaufen. Erzeugen Sie auf dem anderen Gerät einen neuen.';

  @override
  String get transferErrBadCode => 'Falscher Code.';

  @override
  String get transferErrFailed => 'Import nicht möglich.';

  @override
  String get transferCameraDenied => 'Kamerazugriff verweigert';

  @override
  String get transferCameraUnavailable => 'Kamera nicht verfügbar';

  @override
  String get transferCameraDeniedBody =>
      'Erlauben Sie den Kamerazugriff in den Systemeinstellungen, um eine Übertragung zu scannen.';

  @override
  String get transferCameraUnavailableBody =>
      'Auf diesem Gerät ist keine Kamera nutzbar.';

  @override
  String get groupsSubtitle =>
      'Ein Leseausschnitt: Summen und Diagramm zählen nur die Websites der Gruppe.';

  @override
  String get groupsEmptyTitle => 'Keine Gruppen';

  @override
  String get groupsEmptyBody =>
      'Fassen Sie Ihre Websites zusammen, etwa „Spiele“ oder „Kunden“, um ihre Statistiken getrennt vom Rest zu lesen.';

  @override
  String get groupsCreate => 'Gruppe erstellen';

  @override
  String get groupEditEditTitle => 'Gruppe bearbeiten';

  @override
  String get groupEditName => 'Name';

  @override
  String get groupEditNameHint => 'Spiele, Kunden, Privat…';

  @override
  String get groupEditSitesLabel => 'Websites der Gruppe';

  @override
  String get groupEditAddSourceHint => 'ihre Websites erscheinen hier';

  @override
  String get groupEditNoSites =>
      'Noch keine Websites verfolgt — fügen Sie oben eine Quelle hinzu, um diese Gruppe zu füllen.';

  @override
  String get groupEditCreateButton => 'Gruppe erstellen';

  @override
  String get groupEditCreated => 'Gruppe erstellt';

  @override
  String get groupEditSaved => 'Gruppe gespeichert';

  @override
  String get groupEditDeleted => 'Gruppe gelöscht';

  @override
  String get groupEditDeleteTitle => 'Diese Gruppe löschen?';

  @override
  String get groupEditDeleteBody =>
      'Websites und ihre Statistiken bleiben unberührt — nur die Gruppierung verschwindet.';

  @override
  String get addSourceNewTitle => 'Neue Quelle';

  @override
  String get addSourceProvider => 'ANBIETER';

  @override
  String get addSourceName => 'Name (optional)';

  @override
  String get addSourceNameHint => 'Meine Domain';

  @override
  String get addSourceTest => 'Konfiguration testen';

  @override
  String get addSourceContinue => 'Weiter';

  @override
  String get addSourceMissingFields => 'Füllen Sie die Pflichtfelder aus.';

  @override
  String get addSourceTestOk => 'Verbindung erfolgreich.';

  @override
  String addSourceTestOkSites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verbindung erfolgreich · $count Websites gefunden',
      one: 'Verbindung erfolgreich · 1 Website gefunden',
    );
    return '$_temp0';
  }

  @override
  String get addSourceNoSitesPlausible =>
      'Keine Website automatisch aufgelistet: Ihre Instanz bietet die Listen-API nicht an (Plausible Community Edition). Geben Sie oben die zu verfolgende Domain ein.';

  @override
  String get addSourceNoSites => 'Keine Websites für dieses Konto gefunden.';

  @override
  String get addSourceKeyRejected =>
      'API-Schlüssel abgelehnt (Zugriff auf Statistiken). Prüfen Sie den API-Schlüssel.';

  @override
  String get addSourceCredsRejected => 'Zugangsdaten abgelehnt.';

  @override
  String get addSourceAdded => 'Quelle hinzugefügt';

  @override
  String get addSourceEdited => 'Quelle aktualisiert';

  @override
  String get sitePickerTitle => 'Websites wählen';

  @override
  String sitePickerDetected(String provider, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Websites gefunden',
      one: '1 Website gefunden',
    );
    return '$provider · $_temp0';
  }

  @override
  String get sitePickerFollowNew => 'Neue Websites anzeigen';

  @override
  String get sitePickerFollowNewHint =>
      'Eine später erstellte Website erscheint automatisch';

  @override
  String get sitePickerCurrent => 'Aktuelle Websites';

  @override
  String sitePickerShownOf(int shown, int total) {
    return '$shown von $total';
  }

  @override
  String get sitePickerCheckAll => 'Alle auswählen';

  @override
  String get sitePickerUncheckAll => 'Alle abwählen';

  @override
  String get sitePickerFollowAll => 'Allen Websites folgen';

  @override
  String sitePickerFollowAndNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Websites und neue verfolgen',
      one: '1 Website und neue verfolgen',
      zero: '0 Websites und neue verfolgen',
    );
    return '$_temp0';
  }

  @override
  String sitePickerFollow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Websites verfolgen',
      one: '1 Website verfolgen',
      zero: '0 Websites verfolgen',
    );
    return '$_temp0';
  }

  @override
  String get sitePickerShowNone => 'Keine Website anzeigen';

  @override
  String get commonVisitors => 'Besucher';

  @override
  String get commonPageviews => 'Seitenaufrufe';

  @override
  String get commonNoData => 'Keine Daten';

  @override
  String desktopSitesHeader(int count) {
    return 'Websites ($count)';
  }

  @override
  String desktopHiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausgeblendet',
      one: '$count ausgeblendet',
    );
    return '$_temp0';
  }

  @override
  String get desktopShowAllSites => 'Alle Websites anzeigen';

  @override
  String get desktopHideEmptySites => 'Websites ohne Besucher ausblenden';

  @override
  String get desktopLiveNobody => 'Im Moment niemand.';

  @override
  String get desktopKpiSites => 'Websites';

  @override
  String desktopNoSitesGroupBody(String name) {
    return '„$name“ enthält keine Websites. Wählen Sie aus, welche dazugehören.';
  }

  @override
  String get desktopNoSitesBody =>
      'Ihre Konten verfolgen derzeit keine Websites. Wählen Sie die anzuzeigenden Websites in den Einstellungen.';

  @override
  String get chartLegendForecast => 'Prognose';

  @override
  String get chartLegendPrevious => 'Vorperiode';

  @override
  String get chartTooltipVisitors => 'Besucher';

  @override
  String get chartTooltipPageviews => 'Seitenaufrufe';

  @override
  String get chartTooltipForecast => 'Prognose';

  @override
  String get chartTooltipPrevious => 'Vorperiode';

  @override
  String get chartNoSeries => 'Keine Datenreihe ausgewählt';

  @override
  String chartHour(String hour) {
    return '$hour Uhr';
  }

  @override
  String get periodControlsDisplay => 'Anzeige';

  @override
  String get periodControlsSplit => 'Gruppierung';

  @override
  String get periodControlsChart => 'Diagramm';

  @override
  String get periodUnitHour => 'Stunde';

  @override
  String get periodUnitDay => 'Tag';

  @override
  String get periodUnitMonth => 'Monat';

  @override
  String get errorsAuthRefused => 'Zugangsdaten abgelehnt.';

  @override
  String get errorsRequestRefused => 'Anfrage vom Server abgelehnt.';

  @override
  String get errorsNotFound => 'Instanz oder API nicht gefunden.';

  @override
  String get errorsTimeout =>
      'Zeitüberschreitung — Instanz langsam oder nicht erreichbar.';

  @override
  String get errorsUnreachable =>
      'Instanz nicht erreichbar. Prüfen Sie die URL.';

  @override
  String errorsServerCode(int code) {
    return 'Serverfehler $code.';
  }

  @override
  String get errorsConnectionFailed => 'Verbindung nicht möglich.';

  @override
  String errorsGeneric(String detail) {
    return 'Fehler: $detail';
  }

  @override
  String get errUnsupportedIndicators => 'Kennzahlen werden nicht unterstützt';

  @override
  String get errUnsupportedSiteTables =>
      'Website-Tabellen werden nicht unterstützt';

  @override
  String get errUnsupportedFunnels => 'Funnels werden nicht unterstützt';

  @override
  String get errUnsupportedBreakdowns =>
      'Aufschlüsselungen werden nicht unterstützt';

  @override
  String errOperatorUmamiFunnel(String op) {
    return 'Operator „$op“ ist in einem Umami-Funnel nicht verfügbar';
  }

  @override
  String errOperatorPlausible(String op) {
    return 'Operator „$op“ ist bei Plausible nicht verfügbar (nur Texteigenschaften)';
  }

  @override
  String get errFathomSoon => 'Fathom kommt bald.';

  @override
  String get errPlausibleNeedsSite =>
      'Geben Sie eine Domain an, oder E-Mail und Passwort, um Ihre Websites automatisch aufzulisten.';

  @override
  String get errUmamiLoginUnexpected => 'Unerwartete Umami-Login-Antwort';

  @override
  String errBucketsTooFine(int count) {
    return 'Gruppierung zu fein: mehr als $count Punkte im Zeitraum.';
  }

  @override
  String get errMetricsNotConfigured =>
      'Quelle auf dem Server nicht konfiguriert';

  @override
  String get errMetricsBadToken => 'Token abgelehnt';

  @override
  String errMetricsBadRequest(String code) {
    return 'Anfrage abgelehnt ($code)';
  }

  @override
  String get errMetricsUnsupportedVersion =>
      'API-Version wird nicht unterstützt';

  @override
  String get errMetricsUnexpected => 'Unerwartete Antwort des Servers';

  @override
  String get syncMsgUnreachable =>
      'Server nicht erreichbar. Versuchen Sie es erneut.';

  @override
  String get syncMsgSessionExpired =>
      'Sitzung abgelaufen. Melden Sie sich erneut an und versuchen Sie es noch einmal.';

  @override
  String get syncMsgPurchaseFailed =>
      'Kauf nicht möglich. Versuchen Sie es erneut.';

  @override
  String get syncMsgPurchasePending =>
      'Kauf bestätigt — Aktivierung läuft, versuchen Sie den Sync gleich noch einmal.';

  @override
  String get syncMsgNothingToRestore => 'Kein Kauf zum Wiederherstellen.';

  @override
  String get syncMsgRestorePending =>
      'Kauf wiederhergestellt — Aktivierung läuft…';

  @override
  String get syncMsgCannotDecrypt =>
      'Die Konfiguration auf dem Server konnte nicht entschlüsselt werden.';

  @override
  String get syncMsgProRequired => 'Sync ist Glance Sync (Pro) vorbehalten.';

  @override
  String get syncMsgBadCredentials => 'E-Mail oder Passwort falsch.';

  @override
  String syncMsgPasswordTooShort(int count) {
    return 'Passwort zu kurz: mindestens $count Zeichen.';
  }

  @override
  String get syncMsgPasswordTooLong => 'Passwort zu lang.';

  @override
  String get syncMsgInvalidEmail => 'Ungültige E-Mail-Adresse.';

  @override
  String get syncMsgAccountExists =>
      'Für diese E-Mail gibt es schon ein Konto: Melden Sie sich an.';

  @override
  String get syncMsgSignUpFailed => 'Das Konto konnte nicht erstellt werden.';

  @override
  String get periodToday => 'Heute';

  @override
  String get period24h => '24 Std.';

  @override
  String get period7d => '7 Tage';

  @override
  String get period30d => '30 T.';

  @override
  String get periodThisMonth => 'Dieser Monat';

  @override
  String get period12m => '12 M.';

  @override
  String get periodThisYear => 'Dieses Jahr';

  @override
  String get periodAllTime => 'Alle';

  @override
  String get periodCustom => 'Eigene';

  @override
  String get metricTypePages => 'Pfade';

  @override
  String get metricTypeEntry => 'Einstieg';

  @override
  String get metricTypeExit => 'Ausstieg';

  @override
  String get metricTypeTitle => 'Titel';

  @override
  String get metricTypeReferrers => 'Referrer';

  @override
  String get metricTypeChannels => 'Kanäle';

  @override
  String get metricTypeQueries => 'Abfragen';

  @override
  String get metricTypeBrowsers => 'Browser';

  @override
  String get metricTypeOs => 'OS';

  @override
  String get metricTypeDevices => 'Geräte';

  @override
  String get metricTypeScreens => 'Bildschirme';

  @override
  String get metricTypeCountries => 'Länder';

  @override
  String get metricTypeRegions => 'Regionen';

  @override
  String get metricTypeCities => 'Städte';

  @override
  String get metricTypeLanguages => 'Sprachen';

  @override
  String get metricTypeEvents => 'Ereignisse';

  @override
  String get metricSectionPages => 'Seiten';

  @override
  String get metricSectionSources => 'Quellen';

  @override
  String get metricSectionEnvironment => 'Umgebung';

  @override
  String get metricSectionLocation => 'Standort';

  @override
  String get filterOpContains => 'enthält';

  @override
  String get filterOpNotContains => 'enthält nicht';

  @override
  String get entityUnknown => 'Unbekannt';

  @override
  String get entityReferrerDirect => 'Direktzugriff';

  @override
  String get entityBrowserSearchBot => 'Suchmaschinen-Bot';

  @override
  String get entityDeviceDesktop => 'Desktop';

  @override
  String get entityDeviceLaptop => 'Laptop';

  @override
  String get entityDeviceTablet => 'Tablet';

  @override
  String get entityDeviceMobile => 'Mobil';

  @override
  String get entityDeviceWearable => 'Smartwatch';

  @override
  String get entityDeviceConsole => 'Konsole';

  @override
  String get entityDeviceTv => 'Fernseher';

  @override
  String get channelDirect => 'Direkt';

  @override
  String get channelReferral => 'Verweis';

  @override
  String get channelAffiliate => 'Affiliate';

  @override
  String get channelEmail => 'E-Mail';

  @override
  String get channelOrganicSearch => 'Suche (organisch)';

  @override
  String get channelOrganicSocial => 'Social (organisch)';

  @override
  String get channelOrganicShopping => 'Shopping (organisch)';

  @override
  String get channelOrganicVideo => 'Video (organisch)';

  @override
  String get channelPaidAds => 'Werbung (bezahlt)';

  @override
  String get channelPaidSearch => 'Suche (bezahlt)';

  @override
  String get channelPaidSocial => 'Social (bezahlt)';

  @override
  String get channelPaidShopping => 'Shopping (bezahlt)';

  @override
  String get channelPaidVideo => 'Video (bezahlt)';

  @override
  String get credInstanceUrl => 'Instanz-URL';

  @override
  String get credUmamiUrlPlaceholder => 'analytics.ihredomain.de';

  @override
  String get credUsername => 'Benutzername';

  @override
  String get credPassword => 'Passwort';

  @override
  String get credApiKey => 'API-Schlüssel';

  @override
  String get credEmailOptional => 'Konto-E-Mail (optional)';

  @override
  String get credEmailPlaceholder => 'sie@beispiel.de';

  @override
  String get credEmailHint =>
      'E-Mail + Passwort: Glance listet Ihre Websites automatisch auf. Andernfalls lassen Sie das Feld leer und geben unten eine Domain an.';

  @override
  String get credPasswordOptional => 'Passwort (optional)';

  @override
  String get credDomainFallback => 'Domain (ohne E-Mail/Passwort)';

  @override
  String get credDomainPlaceholder => 'ihredomain.de';
}
