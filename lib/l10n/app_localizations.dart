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
  /// **'Tiefenprofil: max. {depth}, Dauer {duration}'**
  String profileSemantics(String depth, String duration);

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
