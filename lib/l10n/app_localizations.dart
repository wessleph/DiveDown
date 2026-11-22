import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('de')];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'DiveDown'**
  String get appTitle;

  /// Bottom navigation: dive log tab
  ///
  /// In de, this message translates to:
  /// **'Logbuch'**
  String get navLogbook;

  /// Bottom navigation: import tab
  ///
  /// In de, this message translates to:
  /// **'Importieren'**
  String get navImport;

  /// Bottom navigation: settings tab
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get navSettings;

  /// No description provided for @retry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @undo.
  ///
  /// In de, this message translates to:
  /// **'Rückgängig'**
  String get undo;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// Shown instead of a value that is not known
  ///
  /// In de, this message translates to:
  /// **'—'**
  String get valueMissing;

  /// No description provided for @startupError.
  ///
  /// In de, this message translates to:
  /// **'Das Logbuch konnte nicht geöffnet werden.'**
  String get startupError;

  /// No description provided for @settingsLicences.
  ///
  /// In de, this message translates to:
  /// **'Open-Source-Lizenzen'**
  String get settingsLicences;

  /// No description provided for @settingsSectionDiver.
  ///
  /// In de, this message translates to:
  /// **'TAUCHER'**
  String get settingsSectionDiver;

  /// No description provided for @settingsSectionDevices.
  ///
  /// In de, this message translates to:
  /// **'GERÄTE'**
  String get settingsSectionDevices;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In de, this message translates to:
  /// **'DARSTELLUNG'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In de, this message translates to:
  /// **'ÜBER DIVEDOWN'**
  String get settingsSectionAbout;

  /// No description provided for @settingsName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get settingsName;

  /// No description provided for @settingsRenameTitle.
  ///
  /// In de, this message translates to:
  /// **'Name ändern'**
  String get settingsRenameTitle;

  /// No description provided for @settingsStartNumber.
  ///
  /// In de, this message translates to:
  /// **'Nummerierung beginnt bei'**
  String get settingsStartNumber;

  /// No description provided for @settingsStartNumberHint.
  ///
  /// In de, this message translates to:
  /// **'Für Tauchgänge aus früheren Logbüchern'**
  String get settingsStartNumberHint;

  /// No description provided for @settingsStartNumberInvalid.
  ///
  /// In de, this message translates to:
  /// **'Bitte eine Zahl von 1 bis 9999 eingeben.'**
  String get settingsStartNumberInvalid;

  /// No description provided for @settingsShiftTitle.
  ///
  /// In de, this message translates to:
  /// **'Nummern verschieben?'**
  String get settingsShiftTitle;

  /// No description provided for @settingsShiftBody.
  ///
  /// In de, this message translates to:
  /// **'Aus #{from}–#{to} werden #{newFrom}–#{newTo}.'**
  String settingsShiftBody(int from, int to, int newFrom, int newTo);

  /// No description provided for @settingsShift.
  ///
  /// In de, this message translates to:
  /// **'Verschieben'**
  String get settingsShift;

  /// No description provided for @settingsRenumber.
  ///
  /// In de, this message translates to:
  /// **'Nummern nach Datum neu vergeben'**
  String get settingsRenumber;

  /// No description provided for @settingsRenumberBody.
  ///
  /// In de, this message translates to:
  /// **'Alle Tauchgänge nach Datum neu nummerieren? Der älteste bekommt #{start}.'**
  String settingsRenumberBody(int start);

  /// No description provided for @settingsRenumberAction.
  ///
  /// In de, this message translates to:
  /// **'Neu nummerieren'**
  String get settingsRenumberAction;

  /// No description provided for @settingsRenumbered.
  ///
  /// In de, this message translates to:
  /// **'{count} Tauchgänge neu nummeriert'**
  String settingsRenumbered(int count);

  /// No description provided for @settingsNoDevices.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Tauchcomputer verbunden.'**
  String get settingsNoDevices;

  /// No description provided for @settingsLastDive.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt: {date}'**
  String settingsLastDive(String date);

  /// No description provided for @settingsNoDivesYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Tauchgänge'**
  String get settingsNoDivesYet;

  /// No description provided for @settingsForgetTooltip.
  ///
  /// In de, this message translates to:
  /// **'{name} vergessen'**
  String settingsForgetTooltip(String name);

  /// No description provided for @settingsForgetTitle.
  ///
  /// In de, this message translates to:
  /// **'{name} vergessen?'**
  String settingsForgetTitle(String name);

  /// No description provided for @settingsForgetBody.
  ///
  /// In de, this message translates to:
  /// **'Beim nächsten Übertragen werden alle Tauchgänge erneut gelesen; Duplikate werden erkannt.'**
  String get settingsForgetBody;

  /// No description provided for @settingsForget.
  ///
  /// In de, this message translates to:
  /// **'Vergessen'**
  String get settingsForget;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get settingsThemeDark;

  /// No description provided for @settingsVersion.
  ///
  /// In de, this message translates to:
  /// **'Version {version} (Build {build})'**
  String settingsVersion(String version, String build);

  /// No description provided for @settingsLibdc.
  ///
  /// In de, this message translates to:
  /// **'libdivecomputer {version}'**
  String settingsLibdc(String version);

  /// No description provided for @settingsLicence.
  ///
  /// In de, this message translates to:
  /// **'Lizenz: GPL-3.0-or-later'**
  String get settingsLicence;

  /// No description provided for @settingsPrivacy.
  ///
  /// In de, this message translates to:
  /// **'Datenschutzerklärung'**
  String get settingsPrivacy;

  /// No description provided for @settingsSource.
  ///
  /// In de, this message translates to:
  /// **'Quellcode'**
  String get settingsSource;

  /// No description provided for @siteUseNew.
  ///
  /// In de, this message translates to:
  /// **'‚{name}‘ als neuen Tauchplatz verwenden'**
  String siteUseNew(String name);

  /// No description provided for @welcomeTitle.
  ///
  /// In de, this message translates to:
  /// **'Willkommen bei DiveDown'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In de, this message translates to:
  /// **'Wer taucht? Du kannst später weitere Taucher hinzufügen.'**
  String get welcomeBody;

  /// No description provided for @welcomeName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get welcomeName;

  /// No description provided for @welcomeNameMissing.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen Namen ein.'**
  String get welcomeNameMissing;

  /// No description provided for @welcomeStart.
  ///
  /// In de, this message translates to:
  /// **'Los geht’s'**
  String get welcomeStart;

  /// No description provided for @welcomeLocalOnly.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten bleiben auf diesem Gerät.'**
  String get welcomeLocalOnly;

  /// No description provided for @logbookEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Tauchgänge'**
  String get logbookEmptyTitle;

  /// No description provided for @logbookEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Importiere vom Tauchcomputer oder trage einen Tauchgang von Hand ein.'**
  String get logbookEmptyBody;

  /// No description provided for @logbookManualEntry.
  ///
  /// In de, this message translates to:
  /// **'Manuell eintragen'**
  String get logbookManualEntry;

  /// No description provided for @logbookLoadError.
  ///
  /// In de, this message translates to:
  /// **'Das Logbuch konnte nicht geladen werden.'**
  String get logbookLoadError;

  /// No description provided for @noSite.
  ///
  /// In de, this message translates to:
  /// **'Ohne Tauchplatz'**
  String get noSite;

  /// No description provided for @logbookTileDives.
  ///
  /// In de, this message translates to:
  /// **'Tauchgänge'**
  String get logbookTileDives;

  /// No description provided for @logbookTileUnderwater.
  ///
  /// In de, this message translates to:
  /// **'unter Wasser'**
  String get logbookTileUnderwater;

  /// No description provided for @diveNumber.
  ///
  /// In de, this message translates to:
  /// **'#{number}'**
  String diveNumber(int number);

  /// No description provided for @diveNumberSpoken.
  ///
  /// In de, this message translates to:
  /// **'Tauchgang {number}'**
  String diveNumberSpoken(int number);

  /// No description provided for @depthSpoken.
  ///
  /// In de, this message translates to:
  /// **'{depth} Meter'**
  String depthSpoken(String depth);

  /// No description provided for @durationSpoken.
  ///
  /// In de, this message translates to:
  /// **'{minutes} Minuten'**
  String durationSpoken(int minutes);

  /// No description provided for @sourceDiveComputer.
  ///
  /// In de, this message translates to:
  /// **'Tauchcomputer'**
  String get sourceDiveComputer;

  /// No description provided for @sourceFit.
  ///
  /// In de, this message translates to:
  /// **'Datei'**
  String get sourceFit;

  /// No description provided for @sourceAppleHealth.
  ///
  /// In de, this message translates to:
  /// **'Apple Watch'**
  String get sourceAppleHealth;

  /// No description provided for @sourceManual.
  ///
  /// In de, this message translates to:
  /// **'Von Hand'**
  String get sourceManual;

  /// No description provided for @sourceSpokenDiveComputer.
  ///
  /// In de, this message translates to:
  /// **'vom Tauchcomputer'**
  String get sourceSpokenDiveComputer;

  /// No description provided for @sourceSpokenFit.
  ///
  /// In de, this message translates to:
  /// **'aus einer Datei'**
  String get sourceSpokenFit;

  /// No description provided for @sourceSpokenAppleHealth.
  ///
  /// In de, this message translates to:
  /// **'von der Apple Watch'**
  String get sourceSpokenAppleHealth;

  /// No description provided for @sourceSpokenManual.
  ///
  /// In de, this message translates to:
  /// **'von Hand eingetragen'**
  String get sourceSpokenManual;

  /// No description provided for @diveDeleted.
  ///
  /// In de, this message translates to:
  /// **'Tauchgang gelöscht.'**
  String get diveDeleted;

  /// No description provided for @duplicateNumber.
  ///
  /// In de, this message translates to:
  /// **'Die Nummer {number} gibt es schon. Der Tauchgang ist trotzdem gespeichert.'**
  String duplicateNumber(int number);

  /// No description provided for @detailEdit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get detailEdit;

  /// No description provided for @detailAddSite.
  ///
  /// In de, this message translates to:
  /// **'Tauchplatz hinzufügen'**
  String get detailAddSite;

  /// No description provided for @detailNotFound.
  ///
  /// In de, this message translates to:
  /// **'Diesen Tauchgang gibt es nicht mehr.'**
  String get detailNotFound;

  /// No description provided for @metricMaxDepth.
  ///
  /// In de, this message translates to:
  /// **'Max. Tiefe'**
  String get metricMaxDepth;

  /// No description provided for @metricDuration.
  ///
  /// In de, this message translates to:
  /// **'Dauer'**
  String get metricDuration;

  /// No description provided for @metricAvgDepth.
  ///
  /// In de, this message translates to:
  /// **'Ø-Tiefe'**
  String get metricAvgDepth;

  /// No description provided for @metricMinTemperature.
  ///
  /// In de, this message translates to:
  /// **'Wassertemp. min'**
  String get metricMinTemperature;

  /// No description provided for @metricPressure.
  ///
  /// In de, this message translates to:
  /// **'Druck'**
  String get metricPressure;

  /// No description provided for @metricSac.
  ///
  /// In de, this message translates to:
  /// **'Ø-SAC'**
  String get metricSac;

  /// No description provided for @metricGas.
  ///
  /// In de, this message translates to:
  /// **'Gas'**
  String get metricGas;

  /// No description provided for @metricWaterType.
  ///
  /// In de, this message translates to:
  /// **'Wassertyp'**
  String get metricWaterType;

  /// No description provided for @waterSalt.
  ///
  /// In de, this message translates to:
  /// **'Salzwasser'**
  String get waterSalt;

  /// No description provided for @waterFresh.
  ///
  /// In de, this message translates to:
  /// **'Süßwasser'**
  String get waterFresh;

  /// No description provided for @sacNeedsPressure.
  ///
  /// In de, this message translates to:
  /// **'Für den Luftverbrauch werden Flaschendruck und Flaschengröße benötigt.'**
  String get sacNeedsPressure;

  /// No description provided for @sacAddTankSize.
  ///
  /// In de, this message translates to:
  /// **'Flaschengröße eintragen'**
  String get sacAddTankSize;

  /// No description provided for @estimatedProfile.
  ///
  /// In de, this message translates to:
  /// **'Geschätztes Profil'**
  String get estimatedProfile;

  /// No description provided for @profileSemantics.
  ///
  /// In de, this message translates to:
  /// **'Tiefenprofil: max. {depth} nach {time}, Dauer {duration}'**
  String profileSemantics(String depth, String time, String duration);

  /// No description provided for @metricWater.
  ///
  /// In de, this message translates to:
  /// **'Wasser'**
  String get metricWater;

  /// No description provided for @metricTank.
  ///
  /// In de, this message translates to:
  /// **'Flasche'**
  String get metricTank;

  /// No description provided for @sacMeasured.
  ///
  /// In de, this message translates to:
  /// **'gemessen'**
  String get sacMeasured;

  /// No description provided for @sacEstimatedFrom.
  ///
  /// In de, this message translates to:
  /// **'geschätzt aus {pressure}'**
  String sacEstimatedFrom(String pressure);

  /// No description provided for @chipTemperature.
  ///
  /// In de, this message translates to:
  /// **'Temperatur'**
  String get chipTemperature;

  /// No description provided for @chipAir.
  ///
  /// In de, this message translates to:
  /// **'Luft'**
  String get chipAir;

  /// No description provided for @chipAirEstimated.
  ///
  /// In de, this message translates to:
  /// **'Luft (geschätzt)'**
  String get chipAirEstimated;

  /// No description provided for @chipNdl.
  ///
  /// In de, this message translates to:
  /// **'NDL'**
  String get chipNdl;

  /// No description provided for @chipSac.
  ///
  /// In de, this message translates to:
  /// **'SAC'**
  String get chipSac;

  /// No description provided for @chipLayersSpoken.
  ///
  /// In de, this message translates to:
  /// **'Ebenen im Diagramm'**
  String get chipLayersSpoken;

  /// No description provided for @profileAxesLimit.
  ///
  /// In de, this message translates to:
  /// **'Höchstens zwei Werte mit eigener Achse. „{name}“ ist jetzt aus.'**
  String profileAxesLimit(String name);

  /// No description provided for @valueTime.
  ///
  /// In de, this message translates to:
  /// **'Zeit'**
  String get valueTime;

  /// No description provided for @valueDepth.
  ///
  /// In de, this message translates to:
  /// **'Tiefe'**
  String get valueDepth;

  /// No description provided for @valueTemperature.
  ///
  /// In de, this message translates to:
  /// **'Temperatur'**
  String get valueTemperature;

  /// No description provided for @valueNdl.
  ///
  /// In de, this message translates to:
  /// **'NDL'**
  String get valueNdl;

  /// No description provided for @valueAmbient.
  ///
  /// In de, this message translates to:
  /// **'Umgebung'**
  String get valueAmbient;

  /// No description provided for @valueAirNow.
  ///
  /// In de, this message translates to:
  /// **'Luft jetzt'**
  String get valueAirNow;

  /// No description provided for @valueTankLeft.
  ///
  /// In de, this message translates to:
  /// **'Noch in der Flasche'**
  String get valueTankLeft;

  /// No description provided for @valueUsed.
  ///
  /// In de, this message translates to:
  /// **'Bisher verbraucht'**
  String get valueUsed;

  /// No description provided for @valueAbout.
  ///
  /// In de, this message translates to:
  /// **'ca. {value}'**
  String valueAbout(String value);

  /// No description provided for @airEstimateNote.
  ///
  /// In de, this message translates to:
  /// **'Luftwerte geschätzt aus Start- und Enddruck ({pressure}, {volume})'**
  String airEstimateNote(String pressure, String volume);

  /// No description provided for @airEnterPressure.
  ///
  /// In de, this message translates to:
  /// **'Start- und Enddruck eintragen'**
  String get airEnterPressure;

  /// No description provided for @profileDisclaimer.
  ///
  /// In de, this message translates to:
  /// **'Werte vom Tauchcomputer, nur zur Anzeige.'**
  String get profileDisclaimer;

  /// No description provided for @profileDisclaimerEstimated.
  ///
  /// In de, this message translates to:
  /// **'Werte vom Tauchcomputer, nur zur Anzeige. Luft ist geschätzt, weil kein Flaschendruck aufgezeichnet wurde.'**
  String get profileDisclaimerEstimated;

  /// No description provided for @profileShowTable.
  ///
  /// In de, this message translates to:
  /// **'Als Tabelle anzeigen'**
  String get profileShowTable;

  /// No description provided for @profileTableTitle.
  ///
  /// In de, this message translates to:
  /// **'Minutenwerte'**
  String get profileTableTitle;

  /// No description provided for @tanksTitle.
  ///
  /// In de, this message translates to:
  /// **'Flaschen'**
  String get tanksTitle;

  /// No description provided for @tankNumber.
  ///
  /// In de, this message translates to:
  /// **'Flasche {number}'**
  String tankNumber(int number);

  /// No description provided for @eventsTitle.
  ///
  /// In de, this message translates to:
  /// **'Ereignisse'**
  String get eventsTitle;

  /// No description provided for @eventGasChange.
  ///
  /// In de, this message translates to:
  /// **'Gaswechsel'**
  String get eventGasChange;

  /// No description provided for @eventAscent.
  ///
  /// In de, this message translates to:
  /// **'Aufstieg zu schnell'**
  String get eventAscent;

  /// No description provided for @eventSafetyStop.
  ///
  /// In de, this message translates to:
  /// **'Sicherheitsstopp'**
  String get eventSafetyStop;

  /// No description provided for @eventDeco.
  ///
  /// In de, this message translates to:
  /// **'Dekostopp'**
  String get eventDeco;

  /// No description provided for @eventDeepStop.
  ///
  /// In de, this message translates to:
  /// **'Tiefenstopp'**
  String get eventDeepStop;

  /// No description provided for @eventCeiling.
  ///
  /// In de, this message translates to:
  /// **'Deko-Grenze verletzt'**
  String get eventCeiling;

  /// No description provided for @eventViolation.
  ///
  /// In de, this message translates to:
  /// **'Grenzwert überschritten'**
  String get eventViolation;

  /// No description provided for @eventBookmark.
  ///
  /// In de, this message translates to:
  /// **'Markierung'**
  String get eventBookmark;

  /// No description provided for @eventSurface.
  ///
  /// In de, this message translates to:
  /// **'Aufgetaucht'**
  String get eventSurface;

  /// No description provided for @eventRbt.
  ///
  /// In de, this message translates to:
  /// **'Restgrundzeit'**
  String get eventRbt;

  /// No description provided for @eventAirTime.
  ///
  /// In de, this message translates to:
  /// **'Luftzeit'**
  String get eventAirTime;

  /// No description provided for @eventMaxDepth.
  ///
  /// In de, this message translates to:
  /// **'Maximaltiefe'**
  String get eventMaxDepth;

  /// No description provided for @eventDiveTime.
  ///
  /// In de, this message translates to:
  /// **'Tauchzeit'**
  String get eventDiveTime;

  /// No description provided for @eventWorkload.
  ///
  /// In de, this message translates to:
  /// **'Hohe Atemarbeit'**
  String get eventWorkload;

  /// No description provided for @eventTransmitter.
  ///
  /// In de, this message translates to:
  /// **'Sender-Warnung'**
  String get eventTransmitter;

  /// No description provided for @eventTissueLevel.
  ///
  /// In de, this message translates to:
  /// **'Gewebesättigung'**
  String get eventTissueLevel;

  /// No description provided for @eventHeading.
  ///
  /// In de, this message translates to:
  /// **'Kompass-Richtung'**
  String get eventHeading;

  /// No description provided for @eventFloor.
  ///
  /// In de, this message translates to:
  /// **'Tiefengrenze'**
  String get eventFloor;

  /// No description provided for @eventOlf.
  ///
  /// In de, this message translates to:
  /// **'Sauerstoffbelastung'**
  String get eventOlf;

  /// No description provided for @eventPo2.
  ///
  /// In de, this message translates to:
  /// **'Sauerstoff-Partialdruck'**
  String get eventPo2;

  /// No description provided for @eventRgbm.
  ///
  /// In de, this message translates to:
  /// **'RGBM-Warnung'**
  String get eventRgbm;

  /// No description provided for @eventUnknown.
  ///
  /// In de, this message translates to:
  /// **'Ereignis ({code})'**
  String eventUnknown(String code);

  /// No description provided for @notesTitle.
  ///
  /// In de, this message translates to:
  /// **'Notizen'**
  String get notesTitle;

  /// No description provided for @ratingSpoken.
  ///
  /// In de, this message translates to:
  /// **'Bewertung: {stars} von 5 Sternen'**
  String ratingSpoken(int stars);

  /// No description provided for @deleteDialogTitle.
  ///
  /// In de, this message translates to:
  /// **'Tauchgang löschen?'**
  String get deleteDialogTitle;

  /// No description provided for @formNewTitle.
  ///
  /// In de, this message translates to:
  /// **'Tauchgang eintragen'**
  String get formNewTitle;

  /// No description provided for @formEditTitle.
  ///
  /// In de, this message translates to:
  /// **'Tauchgang bearbeiten'**
  String get formEditTitle;

  /// No description provided for @fieldNumber.
  ///
  /// In de, this message translates to:
  /// **'Nr.'**
  String get fieldNumber;

  /// No description provided for @fieldSite.
  ///
  /// In de, this message translates to:
  /// **'Tauchplatz'**
  String get fieldSite;

  /// No description provided for @fieldDate.
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get fieldDate;

  /// No description provided for @fieldStartTime.
  ///
  /// In de, this message translates to:
  /// **'Startzeit'**
  String get fieldStartTime;

  /// No description provided for @fieldDuration.
  ///
  /// In de, this message translates to:
  /// **'Dauer (min)'**
  String get fieldDuration;

  /// No description provided for @fieldMaxDepth.
  ///
  /// In de, this message translates to:
  /// **'Max. Tiefe (m)'**
  String get fieldMaxDepth;

  /// No description provided for @fieldAvgDepth.
  ///
  /// In de, this message translates to:
  /// **'Ø-Tiefe (m)'**
  String get fieldAvgDepth;

  /// No description provided for @fieldTemperature.
  ///
  /// In de, this message translates to:
  /// **'Wassertemp. (°C)'**
  String get fieldTemperature;

  /// No description provided for @fieldTankVolume.
  ///
  /// In de, this message translates to:
  /// **'Flasche (l)'**
  String get fieldTankVolume;

  /// No description provided for @fieldStartPressure.
  ///
  /// In de, this message translates to:
  /// **'Startdruck (bar)'**
  String get fieldStartPressure;

  /// No description provided for @fieldEndPressure.
  ///
  /// In de, this message translates to:
  /// **'Enddruck (bar)'**
  String get fieldEndPressure;

  /// No description provided for @fieldO2.
  ///
  /// In de, this message translates to:
  /// **'O₂ (%)'**
  String get fieldO2;

  /// No description provided for @fieldWaterType.
  ///
  /// In de, this message translates to:
  /// **'Wassertyp'**
  String get fieldWaterType;

  /// No description provided for @fieldNotes.
  ///
  /// In de, this message translates to:
  /// **'Notizen'**
  String get fieldNotes;

  /// No description provided for @fieldRating.
  ///
  /// In de, this message translates to:
  /// **'Bewertung'**
  String get fieldRating;

  /// No description provided for @ratingStars.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Stern} other{{count} Sterne}}'**
  String ratingStars(int count);

  /// Label of a required form field
  ///
  /// In de, this message translates to:
  /// **'{label} *'**
  String requiredField(String label);

  /// No description provided for @discardTitle.
  ///
  /// In de, this message translates to:
  /// **'Änderungen verwerfen?'**
  String get discardTitle;

  /// No description provided for @discard.
  ///
  /// In de, this message translates to:
  /// **'Verwerfen'**
  String get discard;

  /// No description provided for @keepEditing.
  ///
  /// In de, this message translates to:
  /// **'Weiter bearbeiten'**
  String get keepEditing;

  /// No description provided for @errorRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte ausfüllen.'**
  String get errorRequired;

  /// No description provided for @errorNotANumber.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib eine Zahl ein.'**
  String get errorNotANumber;

  /// No description provided for @errorNumberInvalid.
  ///
  /// In de, this message translates to:
  /// **'Die Nummer muss eine ganze Zahl ab 1 sein.'**
  String get errorNumberInvalid;

  /// No description provided for @errorDateInFuture.
  ///
  /// In de, this message translates to:
  /// **'Das Datum darf nicht in der Zukunft liegen.'**
  String get errorDateInFuture;

  /// No description provided for @errorDuration.
  ///
  /// In de, this message translates to:
  /// **'Dauer muss zwischen 1 und 1.440 min liegen.'**
  String get errorDuration;

  /// No description provided for @errorDepth.
  ///
  /// In de, this message translates to:
  /// **'Tiefe muss zwischen 0 und 350 m liegen.'**
  String get errorDepth;

  /// No description provided for @errorAvgDepthAboveMax.
  ///
  /// In de, this message translates to:
  /// **'Die Ø-Tiefe darf nicht größer als die max. Tiefe sein.'**
  String get errorAvgDepthAboveMax;

  /// No description provided for @errorTemperature.
  ///
  /// In de, this message translates to:
  /// **'Temperatur muss zwischen −5 und 45 °C liegen.'**
  String get errorTemperature;

  /// No description provided for @errorVolume.
  ///
  /// In de, this message translates to:
  /// **'Die Flaschengröße muss zwischen 0 und 30 l liegen.'**
  String get errorVolume;

  /// No description provided for @errorPressure.
  ///
  /// In de, this message translates to:
  /// **'Druck muss zwischen 0 und 400 bar liegen.'**
  String get errorPressure;

  /// No description provided for @errorEndPressure.
  ///
  /// In de, this message translates to:
  /// **'Der Enddruck muss kleiner als der Startdruck sein.'**
  String get errorEndPressure;

  /// No description provided for @errorO2.
  ///
  /// In de, this message translates to:
  /// **'Der O₂-Anteil muss zwischen 1 und 100 % liegen.'**
  String get errorO2;

  /// No description provided for @importSourceComputer.
  ///
  /// In de, this message translates to:
  /// **'Tauchcomputer'**
  String get importSourceComputer;

  /// No description provided for @importSourceComputerHint.
  ///
  /// In de, this message translates to:
  /// **'Per Bluetooth übertragen'**
  String get importSourceComputerHint;

  /// No description provided for @importSourceFit.
  ///
  /// In de, this message translates to:
  /// **'FIT-Datei'**
  String get importSourceFit;

  /// No description provided for @importSourceFitHint.
  ///
  /// In de, this message translates to:
  /// **'Datei aus der Suunto-App oder Garmin'**
  String get importSourceFitHint;

  /// No description provided for @importSourceHealth.
  ///
  /// In de, this message translates to:
  /// **'Apple Health'**
  String get importSourceHealth;

  /// No description provided for @importSourceHealthHint.
  ///
  /// In de, this message translates to:
  /// **'Tauchgänge der Apple Watch'**
  String get importSourceHealthHint;

  /// No description provided for @importComingSoon.
  ///
  /// In de, this message translates to:
  /// **'Kommt mit einem der nächsten Updates.'**
  String get importComingSoon;

  /// No description provided for @btOff.
  ///
  /// In de, this message translates to:
  /// **'Bluetooth ist ausgeschaltet.'**
  String get btOff;

  /// No description provided for @btTurnOn.
  ///
  /// In de, this message translates to:
  /// **'Bluetooth einschalten'**
  String get btTurnOn;

  /// No description provided for @btTurnOnIos.
  ///
  /// In de, this message translates to:
  /// **'Schalte Bluetooth im Kontrollzentrum ein.'**
  String get btTurnOnIos;

  /// No description provided for @btExplain.
  ///
  /// In de, this message translates to:
  /// **'DiveDown braucht Bluetooth, um Tauchgänge von deinem Tauchcomputer zu laden. Es werden keine anderen Geräte gespeichert.'**
  String get btExplain;

  /// No description provided for @btContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get btContinue;

  /// No description provided for @btDenied.
  ///
  /// In de, this message translates to:
  /// **'Ohne Bluetooth-Berechtigung kann DiveDown keine Tauchcomputer finden.'**
  String get btDenied;

  /// No description provided for @btOpenSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen öffnen'**
  String get btOpenSettings;

  /// No description provided for @scanPairHintEonCore.
  ///
  /// In de, this message translates to:
  /// **'Aktiviere Bluetooth am Tauchcomputer: EON Core → Einstellungen → Verbindungen → Koppeln.'**
  String get scanPairHintEonCore;

  /// No description provided for @scanRunning.
  ///
  /// In de, this message translates to:
  /// **'Suche nach Tauchcomputern …'**
  String get scanRunning;

  /// No description provided for @scanStop.
  ///
  /// In de, this message translates to:
  /// **'Stopp'**
  String get scanStop;

  /// No description provided for @scanAgain.
  ///
  /// In de, this message translates to:
  /// **'Erneut suchen'**
  String get scanAgain;

  /// No description provided for @scanNothing.
  ///
  /// In de, this message translates to:
  /// **'Kein Tauchcomputer gefunden.'**
  String get scanNothing;

  /// No description provided for @scanCheckBluetooth.
  ///
  /// In de, this message translates to:
  /// **'Ist Bluetooth am Tauchcomputer aktiv?'**
  String get scanCheckBluetooth;

  /// No description provided for @scanCheckDistance.
  ///
  /// In de, this message translates to:
  /// **'Liegt der Tauchcomputer nah am Handy?'**
  String get scanCheckDistance;

  /// No description provided for @scanCheckSuuntoApp.
  ///
  /// In de, this message translates to:
  /// **'Schließe die Suunto-App ganz. Sie hält sonst die Verbindung zum EON Core, auch im Hintergrund.'**
  String get scanCheckSuuntoApp;

  /// No description provided for @scanKnown.
  ///
  /// In de, this message translates to:
  /// **'Bekannt'**
  String get scanKnown;

  /// No description provided for @scanUnsupported.
  ///
  /// In de, this message translates to:
  /// **'Dieses Modell wird nicht direkt unterstützt.'**
  String get scanUnsupported;

  /// No description provided for @scanUseFit.
  ///
  /// In de, this message translates to:
  /// **'Nutze den Import per FIT-Datei.'**
  String get scanUseFit;

  /// No description provided for @scanFitGuide.
  ///
  /// In de, this message translates to:
  /// **'Zur FIT-Anleitung'**
  String get scanFitGuide;

  /// No description provided for @fitGuideTitle.
  ///
  /// In de, this message translates to:
  /// **'So exportierst du aus der Suunto-App'**
  String get fitGuideTitle;

  /// No description provided for @fitGuideSteps.
  ///
  /// In de, this message translates to:
  /// **'1. Öffne die Suunto-App und wähle den Tauchgang.\n2. Tippe auf ⋯ → ‚Exportieren‘ bzw. ‚Teilen‘ und wähle FIT.\n3. Wähle DiveDown oder speichere die Datei und öffne sie hier.'**
  String get fitGuideSteps;

  /// No description provided for @ok.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @transferConnecting.
  ///
  /// In de, this message translates to:
  /// **'Verbinde mit {name} …'**
  String transferConnecting(String name);

  /// No description provided for @transferFound.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 neuer Tauchgang gefunden …} other{{count} neue Tauchgänge gefunden …}}'**
  String transferFound(int count);

  /// No description provided for @transferKeepClose.
  ///
  /// In de, this message translates to:
  /// **'Halte den Tauchcomputer in der Nähe. Das kann einige Minuten dauern.'**
  String get transferKeepClose;

  /// No description provided for @transferUpToDate.
  ///
  /// In de, this message translates to:
  /// **'Alles auf dem neuesten Stand. Keine neuen Tauchgänge auf dem Tauchcomputer.'**
  String get transferUpToDate;

  /// No description provided for @transferDone.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get transferDone;

  /// No description provided for @transferLost.
  ///
  /// In de, this message translates to:
  /// **'Die Verbindung wurde unterbrochen.'**
  String get transferLost;

  /// No description provided for @transferPartial.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Tauchgang wurde übertragen.} other{{count} Tauchgänge wurden übertragen.}}'**
  String transferPartial(int count);

  /// No description provided for @transferCheckReceived.
  ///
  /// In de, this message translates to:
  /// **'Übertragene prüfen'**
  String get transferCheckReceived;

  /// No description provided for @transferReconnect.
  ///
  /// In de, this message translates to:
  /// **'Erneut verbinden'**
  String get transferReconnect;

  /// No description provided for @transferCancelled.
  ///
  /// In de, this message translates to:
  /// **'Übertragung abgebrochen.'**
  String get transferCancelled;

  /// No description provided for @transferFailed.
  ///
  /// In de, this message translates to:
  /// **'Die Übertragung ist fehlgeschlagen.'**
  String get transferFailed;

  /// No description provided for @errorCode.
  ///
  /// In de, this message translates to:
  /// **'Fehlercode: {code}'**
  String errorCode(String code);

  /// No description provided for @pinTitle.
  ///
  /// In de, this message translates to:
  /// **'Code eingeben'**
  String get pinTitle;

  /// No description provided for @pinBody.
  ///
  /// In de, this message translates to:
  /// **'{name} (••{id}) fragt nach einem Code. Gib den Code ein, der auf dem Tauchcomputer angezeigt wird.'**
  String pinBody(String name, String id);

  /// No description provided for @pinField.
  ///
  /// In de, this message translates to:
  /// **'Code'**
  String get pinField;

  /// No description provided for @pinConfirm.
  ///
  /// In de, this message translates to:
  /// **'Bestätigen'**
  String get pinConfirm;

  /// No description provided for @pinTimeout.
  ///
  /// In de, this message translates to:
  /// **'Zeit abgelaufen. Bitte erneut verbinden.'**
  String get pinTimeout;

  /// No description provided for @serialTitle.
  ///
  /// In de, this message translates to:
  /// **'Andere Seriennummer'**
  String get serialTitle;

  /// No description provided for @serialBody.
  ///
  /// In de, this message translates to:
  /// **'Dieses Gerät meldet eine andere Seriennummer als dein gespeicherter ‚{product}‘. Wenn du das Gerät nicht kennst, brich ab.'**
  String serialBody(String product);

  /// No description provided for @serialUseAsNew.
  ///
  /// In de, this message translates to:
  /// **'Als neues Gerät verwenden'**
  String get serialUseAsNew;

  /// No description provided for @previewSourceComputer.
  ///
  /// In de, this message translates to:
  /// **'Vom Tauchcomputer: {name}'**
  String previewSourceComputer(String name);

  /// No description provided for @previewSimilar.
  ///
  /// In de, this message translates to:
  /// **'Ähnlicher Tauchgang vorhanden ({date}, {depth}, {duration})'**
  String previewSimilar(String date, String depth, String duration);

  /// No description provided for @previewSameIdOtherData.
  ///
  /// In de, this message translates to:
  /// **'Gleiche Kennung, aber abweichende Daten'**
  String get previewSameIdOtherData;

  /// No description provided for @previewAlreadyThere.
  ///
  /// In de, this message translates to:
  /// **'Bereits im Logbuch'**
  String get previewAlreadyThere;

  /// No description provided for @previewRejected.
  ///
  /// In de, this message translates to:
  /// **'Unplausible Werte, kann nicht importiert werden.'**
  String get previewRejected;

  /// No description provided for @previewImport.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Tauchgang importieren} other{{count} Tauchgänge importieren}}'**
  String previewImport(int count);

  /// No description provided for @previewNothing.
  ///
  /// In de, this message translates to:
  /// **'Nichts ausgewählt'**
  String get previewNothing;

  /// No description provided for @importedSnack.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Tauchgang importiert} other{{count} Tauchgänge importiert}}'**
  String importedSnack(int count);

  /// No description provided for @fitReading.
  ///
  /// In de, this message translates to:
  /// **'Datei wird gelesen …'**
  String get fitReading;

  /// No description provided for @fitTooLarge.
  ///
  /// In de, this message translates to:
  /// **'Die Datei ist zu groß (max. 10 MB).'**
  String get fitTooLarge;

  /// No description provided for @fitUnreadable.
  ///
  /// In de, this message translates to:
  /// **'Diese Datei konnte nicht gelesen werden. Ist es eine FIT-Datei aus der Suunto- oder Garmin-App?'**
  String get fitUnreadable;

  /// No description provided for @fitNoDive.
  ///
  /// In de, this message translates to:
  /// **'Die Datei enthält keinen Tauchgang (sondern z. B. Laufen oder Radfahren).'**
  String get fitNoDive;

  /// No description provided for @fitTimeout.
  ///
  /// In de, this message translates to:
  /// **'Das Lesen hat zu lange gedauert. Die Datei ist möglicherweise beschädigt.'**
  String get fitTimeout;

  /// Shown above every file preview and error; the name is only shown, never used as a path
  ///
  /// In de, this message translates to:
  /// **'Aus Datei: {name}'**
  String previewSourceFile(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
