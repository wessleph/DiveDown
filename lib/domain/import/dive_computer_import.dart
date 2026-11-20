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

  /// One per selected dive, oldest first.
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

  final DiveComputerSource _source;
  final DiveComputerRegistry _registry;
  final ImportService _importService;

  /// Downloads only dives newer than the stored fingerprint. [onEvent] sees
  /// progress, dives and PIN requests while the download runs.
  Future<DownloadResult> download(
    DiscoveredComputer computer, {
    void Function(TransferEvent event)? onEvent,
  }) async {
    final session = await _registry.begin(
      vendor: computer.vendor,
      product: computer.product,
      model: computer.model,
      address: computer.address,
    );
    final dives = <ImportedDive>[];
    var end = DownloadEnd.failed;
    String? errorCode;
    String? serial;
    String? firmware;

    await for (final event in _source.download(
      computer,
      sinceFingerprint: session.sinceFingerprint,
    )) {
      onEvent?.call(event);
      switch (event) {
        case DiveReceived(:final dive):
          dives.add(dive);
        case TransferCompleted():
          end = DownloadEnd.completed;
          serial = event.serial;
          firmware = event.firmware;
        case TransferCancelled():
          end = DownloadEnd.cancelled;
        case TransferFailed(:final code, :final connectionLost):
          end = connectionLost
              ? DownloadEnd.connectionLost
              : DownloadEnd.failed;
          errorCode = code;
        case TransferProgress() || PinRequested():
          break;
      }
    }

    final stored = session.known?.serial;
    return DownloadResult(
      session: session,
      dives: dives,
      end: end,
      errorCode: errorCode,
      serial: serial,
      firmware: firmware,
      serialMismatch: serial != null && stored != null && serial != stored
          ? session.known
          : null,
    );
  }

  Future<void> submitPin(String pin) => _source.submitPin(pin);

  Future<void> cancel() => _source.cancel();

  /// What saving would do, per dive of [result] (duplicates, T2).
  Future<List<ImportResult>> preview(String diverId, DownloadResult result) =>
      _importService.preview(diverId, result.dives);

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
  }) async {
    // Oldest first, so the logbook numbers follow the dive order even when
    // the computer sends the newest dive first.
    final indices = selected.toList()
      ..sort((a, b) => result.dives[a].start.compareTo(result.dives[b].start));
    if (indices.isEmpty) return const SaveResult([], FingerprintKept());

    final session = result.session;
    // The device exists before the dives, so they can point to it (T17.2).
    final device = asNewDevice
        ? await _registry.registerAsNew(
            session,
            serial: result.serial!,
            firmware: result.firmware,
            savedDives: const [],
          )
        : await _registry.ensure(
            session,
            serial: result.serial,
            firmware: result.firmware,
          );

    final results = await _importService.importDives(
      diverId,
      [for (final i in indices) result.dives[i]],
      diveComputerId: device.id,
      confirmed: {
        for (final (pos, i) in indices.indexed)
          if (confirmed.contains(i)) pos,
      },
    );

    final outcome = await _registry.finish(
      DownloadSession(
        vendor: session.vendor,
        product: session.product,
        model: session.model,
        address: session.address,
        known: device,
      ),
      completed: result.end == DownloadEnd.completed,
      serial: result.serial,
      firmware: result.firmware,
      savedDives: [
        for (final r in results)
          if (r is Saved) r.dive,
      ],
    );
    return SaveResult(results, outcome);
  }
}
