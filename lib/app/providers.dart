import 'dart:io';

import 'package:clock/clock.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:libdivecomputer_plugin/libdivecomputer_plugin.dart' as dc;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/backup/logbook_backup.dart';
import '../data/diagnostics/file_diagnostic_log.dart';
import '../data/import/divecomputer/plugin_dive_computer_source.dart';
import '../data/import/fit/fit_dive_parser.dart';

import '../data/local/database.dart';
import '../data/local/drift_app_settings.dart';
import '../data/local/drift_dive_computer_repository.dart';
import '../data/local/drift_dive_repository.dart';
import '../data/local/drift_equipment_repository.dart';
import '../data/local/drift_site_repository.dart';
import '../data/platform/device_channel.dart';
import '../data/platform/permission_bluetooth_access.dart';
import '../data/platform/share_channel.dart';
import '../data/platform/share_folder.dart';
import '../data/platform/system_file_picker.dart';
import '../domain/diagnostics/diagnostic_log.dart';
import '../domain/dive/dive.dart';
import '../domain/dive/dive_repository.dart';
import '../domain/dive/diver.dart';
import '../domain/equipment/equipment.dart';
import '../domain/feedback/feedback_mail.dart';
import '../domain/import/bluetooth_access.dart';
import '../domain/import/dive_computer_import.dart';
import '../domain/import/dive_computer_registry.dart';
import '../domain/import/dive_computer_source.dart';
import '../domain/import/file_import.dart';
import '../domain/import/import_service.dart';
import '../domain/settings/app_settings.dart';
import '../domain/sites/site_repository.dart';
import '../domain/sites/site_suggestions.dart';
import 'startup.dart' show databaseFolderName;

/// The open database. Set by [AppStartupGate] once the file is open;
/// tests override it with an in-memory database.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);

final diveRepositoryProvider = Provider<DiveRepository>(
  (ref) => DriftDiveRepository(ref.watch(appDatabaseProvider)),
);

final diverRepositoryProvider = Provider<DiverRepository>(
  (ref) => DriftDiverRepository(ref.watch(appDatabaseProvider)),
);

final appSettingsProvider = Provider<AppSettings>(
  (ref) => DriftAppSettings(ref.watch(appDatabaseProvider)),
);

/// What „Über DiveDown“ shows (ui-spec §5.11).
class AppInfo {
  const AppInfo({
    required this.version,
    required this.build,
    required this.libdivecomputer,
  });

  final String version;
  final String build;
  final String libdivecomputer;
}

final appInfoProvider = FutureProvider<AppInfo>((ref) async {
  final info = await PackageInfo.fromPlatform();
  var libdc = '–';
  try {
    libdc = await dc.DiveComputerHostApi().getLibdivecomputerVersion();
  } on Exception {
    // Shown as „–“; the rest of the page still works.
  }
  return AppInfo(
    version: info.version,
    build: info.buildNumber,
    libdivecomputer: libdc,
  );
});

/// Opens a web address in the browser (ui-spec §5.11, `url_launcher`). The
/// app itself needs no internet permission for that.
final urlOpenerProvider = Provider<Future<void> Function(Uri)>(
  (ref) => (uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  },
);

/// „Darstellung“ (ui-spec §5.11), read from and written to [AppSettings].
final themeModeProvider = AsyncNotifierProvider<ThemeModeSetting, AppThemeMode>(
  ThemeModeSetting.new,
);

class ThemeModeSetting extends AsyncNotifier<AppThemeMode> {
  @override
  Future<AppThemeMode> build() => ref.watch(appSettingsProvider).themeMode();

  Future<void> set(AppThemeMode mode) async {
    state = AsyncData(mode);
    await ref.read(appSettingsProvider).setThemeMode(mode);
  }
}

/// Known dive computers with the start of their newest dive in the
/// logbook (ui-spec §5.11 „Zuletzt: …“).
final knownComputersProvider =
    FutureProvider<List<({KnownDiveComputer computer, DateTime? lastDive})>>((
      ref,
    ) async {
      final computers = await ref
          .watch(diveComputerRepositoryProvider)
          .listAll();
      final dives = await ref.watch(logbookProvider.future);
      DateTime? last(String id) {
        DateTime? newest;
        for (final d in dives) {
          if (d.diveComputerId != id) continue;
          if (newest == null || d.start.isAfter(newest)) newest = d.start;
        }
        return newest;
      }

      return [for (final c in computers) (computer: c, lastDive: last(c.id))];
    });

/// Whether the active diver's numbers already follow the dates; hides
/// „Nummern nach Datum neu vergeben“ (ui-spec §5.11).
final numbersFollowDatesProvider = FutureProvider<bool>((ref) async {
  final diver = await ref.watch(activeDiverProvider.future);
  ref.watch(logbookProvider);
  if (diver == null) return true;
  return ref.watch(diveNumberingProvider).numbersFollowDates(diver.id!);
});

/// Backup and restore (ui-spec §5.12, T11).
final backupActionsProvider = Provider<BackupActions>(
  (ref) => AppBackupActions(ref.watch(appDatabaseProvider)),
);

/// Opens the system share dialog for a file (`share_plus`). The file stays
/// in `<cache>/share/` until the next share or app start (T11.16).
final shareFileProvider =
    Provider<Future<void> Function(String name, Uint8List bytes)>(
      (ref) => (name, bytes) async {
        final file = await prepareShareFile(
          await getTemporaryDirectory(),
          name,
          bytes,
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: shareMimeType(file.path))],
            fileNameOverrides: [p.basename(file.path)],
          ),
        );
      },
    );

/// The file dialog for „Logbuch wiederherstellen“ (up to 200 MB).
final backupFilePickerProvider = Provider<ImportFilePicker>(
  (ref) => const SystemFilePicker(maxBytes: maxBackupBytes),
);

/// The backup reminder of the logbook (ui-spec §5.2, T11.8): whether it
/// shows, and the last backup for its text.
final backupReminderProvider =
    FutureProvider<({bool due, DateTime? lastBackup})>((ref) async {
      final settings = ref.watch(appSettingsProvider);
      final dives = await ref.watch(logbookProvider.future);
      final last = await settings.lastBackupAt();
      final due = backupReminderDue(
        now: clock.now().toUtc(),
        lastBackup: last,
        baseline: await settings.backupBaseline(),
        snoozedUntil: await settings.backupReminderSnoozedUntil(),
        hasDives: dives.isNotEmpty,
      );
      return (due: due, lastBackup: last);
    });

/// Reopens the database after a restore; [AppStartupGate] replaces it.
final restartAppProvider = Provider<void Function()>((ref) => () {});

/// [BackupActions] on the open database in `<support>/db/` (T11, T16.1).
class AppBackupActions implements BackupActions {
  AppBackupActions(this._db);

  final AppDatabase _db;

  Future<LogbookBackup> _backup() async {
    final support = await getApplicationSupportDirectory();
    final info = await PackageInfo.fromPlatform();
    return LogbookBackup(
      folder: Directory(p.join(support.path, databaseFolderName)),
      appVersion: info.version,
    );
  }

  @override
  Future<BackupFile> create() async {
    final bytes = await (await _backup()).create(_db);
    final day = DateFormat('yyyy-MM-dd').format(clock.now());
    return BackupFile('DiveDown-Sicherung-$day.$backupFileExtension', bytes);
  }

  @override
  BackupCheck inspect(Uint8List bytes) => LogbookBackup(
    folder: Directory.systemTemp,
    appVersion: '',
  ).inspect(bytes);

  @override
  Future<RestoreResult> restore(Uint8List bytes) async =>
      (await _backup()).restore(bytes, closeDatabase: _db.close);
}

/// The diagnostic log of the app (design.md §9, T10).
/// `main` replaces it with the file log in the app cache; without that
/// (some tests) nothing is kept.
final diagnosticLogProvider = Provider<DiagnosticLog>(
  (ref) => const DiscardingDiagnosticLog(),
);

/// Header of the exported log: versions, OS and device model (T10.10).
/// The device name the user gave (e.g. „Annas iPhone“) is never read.
final diagnosticHeaderProvider = FutureProvider<DiagnosticHeader>((ref) async {
  final app = await ref.watch(appInfoProvider.future);
  final device = DeviceInfoPlugin();
  var os = Platform.operatingSystem;
  var model = '–';
  try {
    if (Platform.isAndroid) {
      final a = await device.androidInfo;
      os = 'Android ${a.version.release} (SDK ${a.version.sdkInt})';
      model = '${a.manufacturer} ${a.model}';
    } else if (Platform.isIOS) {
      final i = await device.iosInfo;
      os = 'iOS ${i.systemVersion}';
      model = i.modelName;
    }
  } on Exception {
    // The header still has the app versions.
  }
  return DiagnosticHeader(
    appVersion: app.version,
    build: app.build,
    os: os,
    model: model,
    libdivecomputer: app.libdivecomputer,
  );
});

/// Renumbering and shifting of dive numbers (ui-spec §5.11).
final diveNumberingProvider = Provider<DiveNumbering>(
  (ref) => DriftDiveRepository(ref.watch(appDatabaseProvider)),
);

/// The diver logbook and import work for (ui-spec §2); null before §5.1.
final activeDiverProvider = FutureProvider<Diver?>((ref) async {
  final id = await ref.watch(appSettingsProvider).activeDiverId();
  if (id == null) return null;
  return ref.watch(diverRepositoryProvider).findById(id);
});

/// Dives of the active diver, newest first. Invalidate after changes.
final logbookProvider = FutureProvider<List<Dive>>((ref) async {
  final diver = await ref.watch(activeDiverProvider.future);
  if (diver == null) return const [];
  return ref.watch(diveRepositoryProvider).listForDiver(diver.id!);
});

/// One dive with all samples, and the name of its diver.
final diveDetailProvider = FutureProvider.autoDispose
    .family<({Dive dive, String? diverName, String? computerLabel})?, String>((
      ref,
      id,
    ) async {
      final dive = await ref.watch(diveRepositoryProvider).findById(id);
      if (dive == null) return null;
      final diver = await ref
          .watch(diverRepositoryProvider)
          .findById(dive.diverId);
      final computerId = dive.diveComputerId;
      final computer = computerId == null
          ? null
          : await ref
                .watch(diveComputerRepositoryProvider)
                .findById(computerId);
      return (
        dive: dive,
        diverName: diver?.name,
        computerLabel: computer == null ? null : computerLabel(computer),
      );
    });

/// „Suunto EON Core ••3F7A“ (ui-spec §5.3): model and the last four hex
/// digits of the address, else of the serial.
String computerLabel(KnownDiveComputer c) {
  String lastFour(String s) {
    final hex = s.replaceAll(RegExp('[^0-9A-Za-z]'), '').toUpperCase();
    return hex.length <= 4 ? hex : hex.substring(hex.length - 4);
  }

  final id = c.address ?? c.serial;
  final name = '${c.vendor} ${c.product}';
  return id == null || id.isEmpty ? name : '$name ••${lastFour(id)}';
}

/// Opens the mail app with a feedback draft (ui-spec §5.14, T35).
final feedbackMailerProvider = Provider<FeedbackMailer>(
  (ref) => throw UnimplementedError('T35: mail app'),
);

final equipmentRepositoryProvider = Provider<EquipmentRepository>(
  (ref) => DriftEquipmentRepository(ref.watch(appDatabaseProvider)),
);

/// The active diver's equipment, not deleted (ui-spec §5.11, ADR 0007).
final equipmentListProvider = FutureProvider<List<Equipment>>((ref) async {
  final diver = await ref.watch(activeDiverProvider.future);
  if (diver == null) return const [];
  return ref.watch(equipmentRepositoryProvider).list(diver.id!);
});

/// The pieces used on one dive, deleted ones included (ui-spec §5.3).
final diveEquipmentProvider = FutureProvider.autoDispose
    .family<List<Equipment>, String>(
      (ref, diveId) => ref.watch(equipmentRepositoryProvider).forDive(diveId),
    );

/// Ids of the dives saved by the last import; the logbook highlights them
/// once and then clears the set (ui-spec §5.2, T32).
final recentlyImportedProvider =
    NotifierProvider<RecentlyImported, Set<String>>(RecentlyImported.new);

class RecentlyImported extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void mark(Set<String> ids) => state = ids;

  void clear() => state = const {};
}

final siteRepositoryProvider = Provider<SiteRepository>(
  (ref) => DriftSiteRepository(ref.watch(appDatabaseProvider)),
);

/// Built once from the catalogue table and kept for every keystroke.
final siteSuggesterProvider = FutureProvider<SiteSuggester>(
  (ref) async =>
      SiteSuggester(await ref.watch(siteRepositoryProvider).catalogue()),
);

/// Site names already used on this device, newest first.
final ownSitesProvider = FutureProvider<List<OwnSite>>(
  (ref) => ref.watch(siteRepositoryProvider).ownSites(),
);

/// Countries the active diver has dived in (ADR 0006: ranked first).
final visitedCountriesProvider = FutureProvider<Set<String>>((ref) async {
  final diver = await ref.watch(activeDiverProvider.future);
  if (diver == null) return const {};
  return ref.watch(siteRepositoryProvider).visitedCountries(diver.id!);
});

final diveComputerRepositoryProvider = Provider<DiveComputerRepository>(
  (ref) => DriftDiveComputerRepository(ref.watch(appDatabaseProvider)),
);

/// The plugin; receives the native callbacks while the app runs.
final diveComputerServiceProvider = Provider<dc.DiveComputerService>((ref) {
  final service = dc.DiveComputerService();
  dc.DiveComputerFlutterApi.setUp(service);
  // BLE details for the diagnostic log, filtered there (design.md §9).
  final logs = connectPluginLogs(
    service.logEvents,
    ref.read(diagnosticLogProvider),
  );
  ref.onDispose(() {
    logs.cancel();
    dc.DiveComputerFlutterApi.setUp(null);
    service.dispose();
  });
  return service;
});

/// The plugin behind [DiveComputerSource]; tests override it with a fake.
final diveComputerSourceProvider = Provider<DiveComputerSource>(
  (ref) => PluginDiveComputerSource(ref.watch(diveComputerServiceProvider)),
);

/// Runtime permissions and the radio (permission_handler, security.md §4).
final bluetoothAccessProvider = Provider<BluetoothAccess>(
  (ref) => PermissionBluetoothAccess(),
);

final screenAwakeProvider = Provider<ScreenAwake>(
  (ref) => const ChannelScreenAwake(),
);

final diveComputerImportProvider = Provider<DiveComputerImport>(
  (ref) => DiveComputerImport(
    source: ref.watch(diveComputerSourceProvider),
    registry: DiveComputerRegistry(ref.watch(diveComputerRepositoryProvider)),
    importService: ref.watch(importServiceProvider),
  ),
);

/// FIT files (ui-spec §5.8); parses in an isolate.
final fileDiveSourceProvider = Provider<FileDiveSource>(
  (ref) => FitDiveParser(),
);

/// The system dialog „Datei wählen“ (file_picker).
final importFilePickerProvider = Provider<ImportFilePicker>(
  (ref) => const SystemFilePicker(),
);

/// Files shared with DiveDown from other apps (own channel, T5.9). On iOS
/// they arrive as a copy in Documents/Inbox (T20.13).
final sharedFilesProvider = Provider<SharedFiles>(
  (ref) => ChannelSharedFiles(
    const MethodChannel(ChannelSharedFiles.channelName),
    () async {
      final documents = await getApplicationDocumentsDirectory();
      return [Directory(p.join(documents.path, 'Inbox'))];
    },
  ),
);

/// Each file shared with DiveDown, as it arrives.
final sharedFileEventsProvider = StreamProvider<PickResult>(
  (ref) => ref.watch(sharedFilesProvider).incoming,
);

final importServiceProvider = Provider<ImportService>(
  (ref) => ImportService(ref.watch(diveRepositoryProvider)),
);

/// The file the FIT screen works on: picked in §5.5 or shared.
final pendingImportFileProvider =
    NotifierProvider<PendingImportFile, PickResult?>(PendingImportFile.new);

class PendingImportFile extends Notifier<PickResult?> {
  @override
  PickResult? build() => null;

  void set(PickResult? file) => state = file;
}

extension RefreshDives on WidgetRef {
  /// Call after a dive was saved, deleted or restored.
  void refreshDives({String? diveId}) {
    invalidate(logbookProvider);
    invalidate(ownSitesProvider);
    invalidate(visitedCountriesProvider);
    if (diveId != null) {
      invalidate(diveDetailProvider(diveId));
      invalidate(diveEquipmentProvider(diveId));
    }
  }
}

/// Like [RefreshDives.refreshDives], for callbacks that outlive the widget
/// (e.g. the undo action of a snackbar).
void refreshDivesIn(ProviderContainer container, {String? diveId}) {
  container.invalidate(logbookProvider);
  container.invalidate(ownSitesProvider);
  container.invalidate(visitedCountriesProvider);
  if (diveId != null) container.invalidate(diveDetailProvider(diveId));
}
