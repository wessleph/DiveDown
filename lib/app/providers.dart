import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libdivecomputer_plugin/libdivecomputer_plugin.dart' as dc;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/import/divecomputer/plugin_dive_computer_source.dart';
import '../data/import/fit/fit_dive_parser.dart';

import '../data/local/database.dart';
import '../data/local/drift_app_settings.dart';
import '../data/local/drift_dive_computer_repository.dart';
import '../data/local/drift_dive_repository.dart';
import '../data/local/drift_site_repository.dart';
import '../data/platform/device_channel.dart';
import '../data/platform/permission_bluetooth_access.dart';
import '../data/platform/share_channel.dart';
import '../data/platform/system_file_picker.dart';
import '../domain/dive/dive.dart';
import '../domain/dive/dive_repository.dart';
import '../domain/dive/diver.dart';
import '../domain/import/bluetooth_access.dart';
import '../domain/import/dive_computer_import.dart';
import '../domain/import/dive_computer_registry.dart';
import '../domain/import/dive_computer_source.dart';
import '../domain/import/file_import.dart';
import '../domain/import/import_service.dart';
import '../domain/settings/app_settings.dart';
import '../domain/sites/site_repository.dart';
import '../domain/sites/site_suggestions.dart';

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
    .family<({Dive dive, String? diverName})?, String>((ref, id) async {
      final dive = await ref.watch(diveRepositoryProvider).findById(id);
      if (dive == null) return null;
      final diver = await ref
          .watch(diverRepositoryProvider)
          .findById(dive.diverId);
      return (dive: dive, diverName: diver?.name);
    });

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
  ref.onDispose(() {
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
    if (diveId != null) invalidate(diveDetailProvider(diveId));
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
