// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'DiveDown';

  @override
  String get navLogbook => 'Logbuch';

  @override
  String get navImport => 'Importieren';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get undo => 'Rückgängig';

  @override
  String get save => 'Speichern';

  @override
  String get valueMissing => '—';

  @override
  String get startupError => 'Das Logbuch konnte nicht geöffnet werden.';

  @override
  String get settingsLicences => 'Open-Source-Lizenzen';

  @override
  String get settingsSectionDiver => 'TAUCHER';

  @override
  String get settingsSectionDevices => 'GERÄTE';

  @override
  String get settingsSectionAppearance => 'DARSTELLUNG';

  @override
  String get settingsSectionAbout => 'ÜBER DIVEDOWN';

  @override
  String get settingsName => 'Name';

  @override
  String get settingsRenameTitle => 'Name ändern';

  @override
  String get settingsStartNumber => 'Nummerierung beginnt bei';

  @override
  String get settingsStartNumberHint =>
      'Für Tauchgänge aus früheren Logbüchern';

  @override
  String get settingsStartNumberInvalid =>
      'Bitte eine Zahl von 1 bis 9999 eingeben.';

  @override
  String get settingsShiftTitle => 'Nummern verschieben?';

  @override
  String settingsShiftBody(int from, int to, int newFrom, int newTo) {
    return 'Aus #$from–#$to werden #$newFrom–#$newTo.';
  }

  @override
  String get settingsShift => 'Verschieben';

  @override
  String get settingsRenumber => 'Nummern nach Datum neu vergeben';

  @override
  String settingsRenumberBody(int start) {
    return 'Alle Tauchgänge nach Datum neu nummerieren? Der älteste bekommt #$start.';
  }

  @override
  String get settingsRenumberAction => 'Neu nummerieren';

  @override
  String settingsRenumbered(int count) {
    return '$count Tauchgänge neu nummeriert';
  }

  @override
  String get settingsNoDevices => 'Noch kein Tauchcomputer verbunden.';

  @override
  String settingsLastDive(String date) {
    return 'Zuletzt: $date';
  }

  @override
  String get settingsNoDivesYet => 'Noch keine Tauchgänge';

  @override
  String settingsForgetTooltip(String name) {
    return '$name vergessen';
  }

  @override
  String settingsForgetTitle(String name) {
    return '$name vergessen?';
  }

  @override
  String get settingsForgetBody =>
      'Beim nächsten Übertragen werden alle Tauchgänge erneut gelesen; Duplikate werden erkannt.';

  @override
  String get settingsForget => 'Vergessen';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String settingsVersion(String version, String build) {
    return 'Version $version (Build $build)';
  }

  @override
  String settingsLibdc(String version) {
    return 'libdivecomputer $version';
  }

  @override
  String get settingsLicence => 'Lizenz: GPL-3.0-or-later';

  @override
  String get settingsPrivacy => 'Datenschutzerklärung';

  @override
  String get settingsSource => 'Quellcode';

  @override
  String siteUseNew(String name) {
    return '‚$name‘ als neuen Tauchplatz verwenden';
  }

  @override
  String get welcomeTitle => 'Willkommen bei DiveDown';

  @override
  String get welcomeBody =>
      'Wer taucht? Du kannst später weitere Taucher hinzufügen.';

  @override
  String get welcomeName => 'Name';

  @override
  String get welcomeNameMissing => 'Bitte gib einen Namen ein.';

  @override
  String get welcomeStart => 'Los geht’s';

  @override
  String get welcomeLocalOnly => 'Alle Daten bleiben auf diesem Gerät.';

  @override
  String get logbookEmptyTitle => 'Noch keine Tauchgänge';

  @override
  String get logbookEmptyBody =>
      'Importiere vom Tauchcomputer oder trage einen Tauchgang von Hand ein.';

  @override
  String get logbookManualEntry => 'Manuell eintragen';

  @override
  String get logbookLoadError => 'Das Logbuch konnte nicht geladen werden.';

  @override
  String get noSite => 'Ohne Tauchplatz';

  @override
  String get logbookTileDives => 'Tauchgänge';

  @override
  String get logbookTileUnderwater => 'unter Wasser';

  @override
  String diveNumber(int number) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);

    return '#$numberString';
  }

  @override
  String diveNumberSpoken(int number) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);

    return 'Tauchgang $numberString';
  }

  @override
  String depthSpoken(String depth) {
    return '$depth Meter';
  }

  @override
  String durationSpoken(int minutes) {
    return '$minutes Minuten';
  }

  @override
  String get sourceDiveComputer => 'Tauchcomputer';

  @override
  String get sourceFit => 'Datei';

  @override
  String get sourceAppleHealth => 'Apple Watch';

  @override
  String get sourceManual => 'Von Hand';

  @override
  String get sourceSpokenDiveComputer => 'vom Tauchcomputer';

  @override
  String get sourceSpokenFit => 'aus einer Datei';

  @override
  String get sourceSpokenAppleHealth => 'von der Apple Watch';

  @override
  String get sourceSpokenManual => 'von Hand eingetragen';

  @override
  String get diveDeleted => 'Tauchgang gelöscht.';

  @override
  String duplicateNumber(int number) {
    return 'Die Nummer $number gibt es schon. Der Tauchgang ist trotzdem gespeichert.';
  }

  @override
  String get detailEdit => 'Bearbeiten';

  @override
  String get detailAddSite => 'Tauchplatz hinzufügen';

  @override
  String get detailNotFound => 'Diesen Tauchgang gibt es nicht mehr.';

  @override
  String get metricMaxDepth => 'Max. Tiefe';

  @override
  String get metricDuration => 'Dauer';

  @override
  String get metricAvgDepth => 'Ø-Tiefe';

  @override
  String get metricMinTemperature => 'Wassertemp. min';

  @override
  String get metricPressure => 'Druck';

  @override
  String get metricSac => 'Ø-SAC';

  @override
  String get metricGas => 'Gas';

  @override
  String get metricWaterType => 'Wassertyp';

  @override
  String get waterSalt => 'Salzwasser';

  @override
  String get waterFresh => 'Süßwasser';

  @override
  String get sacNeedsPressure =>
      'Für den Luftverbrauch werden Flaschendruck und Flaschengröße benötigt.';

  @override
  String get sacAddTankSize => 'Flaschengröße eintragen';

  @override
  String get estimatedProfile => 'Geschätztes Profil';

  @override
  String profileSemantics(String depth, String time, String duration) {
    return 'Tiefenprofil: max. $depth nach $time, Dauer $duration';
  }

  @override
  String get metricWater => 'Wasser';

  @override
  String get metricTank => 'Flasche';

  @override
  String get sacMeasured => 'gemessen';

  @override
  String sacEstimatedFrom(String pressure) {
    return 'geschätzt aus $pressure';
  }

  @override
  String get chipTemperature => 'Temperatur';

  @override
  String get chipAir => 'Luft';

  @override
  String get chipAirEstimated => 'Luft (geschätzt)';

  @override
  String get chipNdl => 'NDL';

  @override
  String get chipSac => 'SAC';

  @override
  String get chipLayersSpoken => 'Ebenen im Diagramm';

  @override
  String profileAxesLimit(String name) {
    return 'Höchstens zwei Werte mit eigener Achse. „$name“ ist jetzt aus.';
  }

  @override
  String get valueTime => 'Zeit';

  @override
  String get valueDepth => 'Tiefe';

  @override
  String get valueTemperature => 'Temperatur';

  @override
  String get valueNdl => 'NDL';

  @override
  String get valueAmbient => 'Umgebung';

  @override
  String get valueAirNow => 'Luft jetzt';

  @override
  String get valueTankLeft => 'Noch in der Flasche';

  @override
  String get valueUsed => 'Bisher verbraucht';

  @override
  String valueAbout(String value) {
    return 'ca. $value';
  }

  @override
  String airEstimateNote(String pressure, String volume) {
    return 'Luftwerte geschätzt aus Start- und Enddruck ($pressure, $volume)';
  }

  @override
  String get airEnterPressure => 'Start- und Enddruck eintragen';

  @override
  String get profileDisclaimer => 'Werte vom Tauchcomputer, nur zur Anzeige.';

  @override
  String get profileDisclaimerEstimated =>
      'Werte vom Tauchcomputer, nur zur Anzeige. Luft ist geschätzt, weil kein Flaschendruck aufgezeichnet wurde.';

  @override
  String get profileShowTable => 'Als Tabelle anzeigen';

  @override
  String get profileTableTitle => 'Minutenwerte';

  @override
  String get tanksTitle => 'Flaschen';

  @override
  String tankNumber(int number) {
    return 'Flasche $number';
  }

  @override
  String get eventsTitle => 'Ereignisse';

  @override
  String get eventGasChange => 'Gaswechsel';

  @override
  String get eventAscent => 'Aufstieg zu schnell';

  @override
  String get eventSafetyStop => 'Sicherheitsstopp';

  @override
  String get eventDeco => 'Dekostopp';

  @override
  String get eventDeepStop => 'Tiefenstopp';

  @override
  String get eventCeiling => 'Deko-Grenze verletzt';

  @override
  String get eventViolation => 'Grenzwert überschritten';

  @override
  String get eventBookmark => 'Markierung';

  @override
  String get eventSurface => 'Aufgetaucht';

  @override
  String get eventRbt => 'Restgrundzeit';

  @override
  String get eventAirTime => 'Luftzeit';

  @override
  String get eventMaxDepth => 'Maximaltiefe';

  @override
  String get eventDiveTime => 'Tauchzeit';

  @override
  String get eventWorkload => 'Hohe Atemarbeit';

  @override
  String get eventTransmitter => 'Sender-Warnung';

  @override
  String get eventTissueLevel => 'Gewebesättigung';

  @override
  String get eventHeading => 'Kompass-Richtung';

  @override
  String get eventFloor => 'Tiefengrenze';

  @override
  String get eventOlf => 'Sauerstoffbelastung';

  @override
  String get eventPo2 => 'Sauerstoff-Partialdruck';

  @override
  String get eventRgbm => 'RGBM-Warnung';

  @override
  String eventUnknown(String code) {
    return 'Ereignis ($code)';
  }

  @override
  String get notesTitle => 'Notizen';

  @override
  String ratingSpoken(int stars) {
    return 'Bewertung: $stars von 5 Sternen';
  }

  @override
  String get deleteDialogTitle => 'Tauchgang löschen?';

  @override
  String get formNewTitle => 'Tauchgang eintragen';

  @override
  String get formEditTitle => 'Tauchgang bearbeiten';

  @override
  String get fieldNumber => 'Nr.';

  @override
  String get fieldSite => 'Tauchplatz';

  @override
  String get fieldDate => 'Datum';

  @override
  String get fieldStartTime => 'Startzeit';

  @override
  String get fieldDuration => 'Dauer (min)';

  @override
  String get fieldMaxDepth => 'Max. Tiefe (m)';

  @override
  String get fieldAvgDepth => 'Ø-Tiefe (m)';

  @override
  String get fieldTemperature => 'Wassertemp. (°C)';

  @override
  String get fieldTankVolume => 'Flasche (l)';

  @override
  String get fieldStartPressure => 'Startdruck (bar)';

  @override
  String get fieldEndPressure => 'Enddruck (bar)';

  @override
  String get fieldO2 => 'O₂ (%)';

  @override
  String get fieldWaterType => 'Wassertyp';

  @override
  String get fieldNotes => 'Notizen';

  @override
  String get fieldRating => 'Bewertung';

  @override
  String ratingStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sterne',
      one: '1 Stern',
    );
    return '$_temp0';
  }

  @override
  String requiredField(String label) {
    return '$label *';
  }

  @override
  String get discardTitle => 'Änderungen verwerfen?';

  @override
  String get discard => 'Verwerfen';

  @override
  String get keepEditing => 'Weiter bearbeiten';

  @override
  String get errorRequired => 'Bitte ausfüllen.';

  @override
  String get errorNotANumber => 'Bitte gib eine Zahl ein.';

  @override
  String get errorNumberInvalid => 'Die Nummer muss eine ganze Zahl ab 1 sein.';

  @override
  String get errorDateInFuture => 'Das Datum darf nicht in der Zukunft liegen.';

  @override
  String get errorDuration => 'Dauer muss zwischen 1 und 1.440 min liegen.';

  @override
  String get errorDepth => 'Tiefe muss zwischen 0 und 350 m liegen.';

  @override
  String get errorAvgDepthAboveMax =>
      'Die Ø-Tiefe darf nicht größer als die max. Tiefe sein.';

  @override
  String get errorTemperature =>
      'Temperatur muss zwischen −5 und 45 °C liegen.';

  @override
  String get errorVolume =>
      'Die Flaschengröße muss zwischen 0 und 30 l liegen.';

  @override
  String get errorPressure => 'Druck muss zwischen 0 und 400 bar liegen.';

  @override
  String get errorEndPressure =>
      'Der Enddruck muss kleiner als der Startdruck sein.';

  @override
  String get errorO2 => 'Der O₂-Anteil muss zwischen 1 und 100 % liegen.';

  @override
  String get importSourceComputer => 'Tauchcomputer';

  @override
  String get importSourceComputerHint => 'Per Bluetooth übertragen';

  @override
  String get importSourceFit => 'FIT-Datei';

  @override
  String get importSourceFitHint => 'Datei aus der Suunto-App oder Garmin';

  @override
  String get importSourceHealth => 'Apple Health';

  @override
  String get importSourceHealthHint => 'Tauchgänge der Apple Watch';

  @override
  String get importComingSoon => 'Kommt mit einem der nächsten Updates.';

  @override
  String get btOff => 'Bluetooth ist ausgeschaltet.';

  @override
  String get btTurnOn => 'Bluetooth einschalten';

  @override
  String get btTurnOnIos => 'Schalte Bluetooth im Kontrollzentrum ein.';

  @override
  String get btExplain =>
      'DiveDown braucht Bluetooth, um Tauchgänge von deinem Tauchcomputer zu laden. Es werden keine anderen Geräte gespeichert.';

  @override
  String get btContinue => 'Weiter';

  @override
  String get btDenied =>
      'Ohne Bluetooth-Berechtigung kann DiveDown keine Tauchcomputer finden.';

  @override
  String get btOpenSettings => 'Einstellungen öffnen';

  @override
  String get scanPairHintEonCore =>
      'Aktiviere Bluetooth am Tauchcomputer: EON Core → Einstellungen → Verbindungen → Koppeln.';

  @override
  String get scanRunning => 'Suche nach Tauchcomputern …';

  @override
  String get scanStop => 'Stopp';

  @override
  String get scanAgain => 'Erneut suchen';

  @override
  String get scanNothing => 'Kein Tauchcomputer gefunden.';

  @override
  String get scanCheckBluetooth => 'Ist Bluetooth am Tauchcomputer aktiv?';

  @override
  String get scanCheckDistance => 'Liegt der Tauchcomputer nah am Handy?';

  @override
  String get scanCheckSuuntoApp =>
      'Schließe die Suunto-App ganz. Sie hält sonst die Verbindung zum EON Core, auch im Hintergrund.';

  @override
  String get scanKnown => 'Bekannt';

  @override
  String get scanUnsupported => 'Dieses Modell wird nicht direkt unterstützt.';

  @override
  String get scanUseFit => 'Nutze den Import per FIT-Datei.';

  @override
  String get scanFitGuide => 'Zur FIT-Anleitung';

  @override
  String get fitGuideTitle => 'So exportierst du aus der Suunto-App';

  @override
  String get fitGuideSteps =>
      '1. Öffne die Suunto-App und wähle den Tauchgang.\n2. Tippe auf ⋯ → ‚Exportieren‘ bzw. ‚Teilen‘ und wähle FIT.\n3. Wähle DiveDown oder speichere die Datei und öffne sie hier.';

  @override
  String get ok => 'OK';

  @override
  String transferConnecting(String name) {
    return 'Verbinde mit $name …';
  }

  @override
  String transferFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Tauchgänge gefunden …',
      one: '1 neuer Tauchgang gefunden …',
    );
    return '$_temp0';
  }

  @override
  String get transferKeepClose =>
      'Halte den Tauchcomputer in der Nähe. Das kann einige Minuten dauern.';

  @override
  String get transferUpToDate =>
      'Alles auf dem neuesten Stand. Keine neuen Tauchgänge auf dem Tauchcomputer.';

  @override
  String get transferDone => 'Fertig';

  @override
  String get transferLost => 'Die Verbindung wurde unterbrochen.';

  @override
  String transferPartial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tauchgänge wurden übertragen.',
      one: '1 Tauchgang wurde übertragen.',
    );
    return '$_temp0';
  }

  @override
  String get transferCheckReceived => 'Übertragene prüfen';

  @override
  String get transferReconnect => 'Erneut verbinden';

  @override
  String get transferCancelled => 'Übertragung abgebrochen.';

  @override
  String get transferFailed => 'Die Übertragung ist fehlgeschlagen.';

  @override
  String errorCode(String code) {
    return 'Fehlercode: $code';
  }

  @override
  String get pinTitle => 'Code eingeben';

  @override
  String pinBody(String name, String id) {
    return '$name (••$id) fragt nach einem Code. Gib den Code ein, der auf dem Tauchcomputer angezeigt wird.';
  }

  @override
  String get pinField => 'Code';

  @override
  String get pinConfirm => 'Bestätigen';

  @override
  String get pinTimeout => 'Zeit abgelaufen. Bitte erneut verbinden.';

  @override
  String get serialTitle => 'Andere Seriennummer';

  @override
  String serialBody(String product) {
    return 'Dieses Gerät meldet eine andere Seriennummer als dein gespeicherter ‚$product‘. Wenn du das Gerät nicht kennst, brich ab.';
  }

  @override
  String get serialUseAsNew => 'Als neues Gerät verwenden';

  @override
  String previewSourceComputer(String name) {
    return 'Vom Tauchcomputer: $name';
  }

  @override
  String previewSimilar(String date, String depth, String duration) {
    return 'Ähnlicher Tauchgang vorhanden ($date, $depth, $duration)';
  }

  @override
  String get previewSameIdOtherData =>
      'Gleiche Kennung, aber abweichende Daten';

  @override
  String get previewAlreadyThere => 'Bereits im Logbuch';

  @override
  String get previewRejected =>
      'Unplausible Werte, kann nicht importiert werden.';

  @override
  String previewImport(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tauchgänge importieren',
      one: '1 Tauchgang importieren',
    );
    return '$_temp0';
  }

  @override
  String get previewNothing => 'Nichts ausgewählt';

  @override
  String importedSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tauchgänge importiert',
      one: '1 Tauchgang importiert',
    );
    return '$_temp0';
  }

  @override
  String get fitReading => 'Datei wird gelesen …';

  @override
  String get fitTooLarge => 'Die Datei ist zu groß (max. 10 MB).';

  @override
  String get fitUnreadable =>
      'Diese Datei konnte nicht gelesen werden. Ist es eine FIT-Datei aus der Suunto- oder Garmin-App?';

  @override
  String get fitNoDive =>
      'Die Datei enthält keinen Tauchgang (sondern z. B. Laufen oder Radfahren).';

  @override
  String get fitTimeout =>
      'Das Lesen hat zu lange gedauert. Die Datei ist möglicherweise beschädigt.';

  @override
  String previewSourceFile(String name) {
    return 'Aus Datei: $name';
  }
}
