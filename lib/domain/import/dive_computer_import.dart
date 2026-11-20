import 'dive_computer_registry.dart';
import 'dive_computer_source.dart';
import 'import_service.dart';
import 'imported_dive.dart';

/// How a download ended (ui-spec §5.7).
enum DownloadEnd { completed, cancelled, connectionLost, failed }

/// Everything one download delivered, for the preview (§5.9).
class DownloadResult {
  const DownloadResult({
    required this.session,
    required this.dives,
    required this.end,
    this.errorCode,
    this.serial,
    this.firmware,
    this.serialMismatch,
  });

  final DownloadSession session;

  /// In the order the computer sent them.
  final List<ImportedDive> dives;
  final DownloadEnd end;
  final String? errorCode;
  final String? serial;
  final String? firmware;

  /// The stored device whose serial differs from the reported one
  /// (security A1, T3.4). The UI warns before the preview.
  final KnownDiveComputer? serialMismatch;
}

class SaveResult {
  const SaveResult(this.results, this.device);

  /// One per selected dive, in the order of the download.
  final List<ImportResult> results;

  /// What happened to the device and its fingerprint.
  final DownloadOutcome device;

  int get savedCount => results.whereType<Saved>().length;
}

/// One BLE import from the picked computer to the logbook (design.md §4.1):
/// plugin download → [ImportService] → [DiveComputerRegistry].
class DiveComputerImport {
  DiveComputerImport({
    required this._source,
    required this._registry,
    required this._importService,
  });

  // ignore: unused_field
  final DiveComputerSource _source;
  // ignore: unused_field
  final DiveComputerRegistry _registry;
  // ignore: unused_field
  final ImportService _importService;

  /// Downloads only dives newer than the stored fingerprint. [onEvent] sees
  /// progress, dives and PIN requests while the download runs.
  Future<DownloadResult> download(
    DiscoveredComputer computer, {
    void Function(TransferEvent event)? onEvent,
  }) => throw UnimplementedError('DiveComputerImport.download');

  Future<void> submitPin(String pin) =>
      throw UnimplementedError('DiveComputerImport.submitPin');

  Future<void> cancel() =>
      throw UnimplementedError('DiveComputerImport.cancel');

  /// What saving would do, per dive of [result] (duplicates, T2).
  Future<List<ImportResult>> preview(String diverId, DownloadResult result) =>
      throw UnimplementedError('DiveComputerImport.preview');

  /// Saves the dives at [selected] (indices into [DownloadResult.dives]);
  /// those in [confirmed] also when they need confirmation. Then stores the
  /// device and, only after a completed download, its fingerprint.
  /// [asNewDevice]: „Als neues Gerät verwenden“ after a serial mismatch.
  Future<SaveResult> save(
    String diverId,
    DownloadResult result, {
    required Set<int> selected,
    Set<int> confirmed = const {},
    bool asNewDevice = false,
  }) => throw UnimplementedError('DiveComputerImport.save');
}
