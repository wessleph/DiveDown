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
  String profileSemantics(String depth, String duration) {
    return 'Tiefenprofil: max. $depth, Dauer $duration';
  }

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
}
