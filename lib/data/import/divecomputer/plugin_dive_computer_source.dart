import 'dart:async';
import 'dart:typed_data';

import 'package:libdivecomputer_plugin/libdivecomputer_plugin.dart' as dc;

import '../../../domain/import/dive_computer_source.dart';
import 'parsed_dive_adapter.dart';

/// [DiveComputerSource] over the libdivecomputer plugin (ADR 0002).
/// Translates only; dives go through [importedFromParsedDive].
class PluginDiveComputerSource implements DiveComputerSource {
  PluginDiveComputerSource(this._service);

  final dc.DiveComputerService _service;

  /// Plugin error codes that mean the connection failed or broke off.
  static const connectionErrorCodes = {
    'connect_failed',
    'bond_failed',
    'not_found',
    'download_error',
  };

  StreamController<DiscoveredComputer>? _scan;
  StreamController<TransferEvent>? _transfer;

  @override
  Stream<DiscoveredComputer> discover() {
    final seen = <String>{};
    final subscriptions = <StreamSubscription<Object?>>[];
    late final StreamController<DiscoveredComputer> scan;
    scan = _scan = StreamController<DiscoveredComputer>(
      onListen: () {
        subscriptions
          ..add(
            _service.discoveredDevices.listen((d) {
              if (d.transport != dc.TransportType.ble || !seen.add(d.address)) {
                return;
              }
              scan.add(
                DiscoveredComputer(
                  name: d.name ?? d.product,
                  vendor: d.vendor,
                  product: d.product,
                  model: d.model,
                  address: d.address,
                ),
              );
            }),
          )
          // A separate stream: let devices still queued arrive first.
          ..add(
            _service.discoveryComplete.listen((_) => Timer.run(scan.close)),
          );
        _service.startDiscovery(dc.TransportType.ble).catchError((Object e) {
          if (!scan.isClosed) {
            scan.addError(e);
            scan.close();
          }
        });
      },
      onCancel: () async {
        for (final s in subscriptions) {
          await s.cancel();
        }
      },
    );
    return scan.stream;
  }

  @override
  Future<void> stopDiscovery() async {
    await _service.stopDiscovery();
    await _scan?.close();
  }

  @override
  Stream<TransferEvent> download(
    DiscoveredComputer computer, {
    Uint8List? sinceFingerprint,
  }) {
    StreamSubscription<dc.DownloadEvent>? subscription;
    late final StreamController<TransferEvent> transfer;

    void finish(TransferEvent last) {
      if (transfer.isClosed) return;
      transfer.add(last);
      transfer.close();
    }

    transfer = _transfer = StreamController<TransferEvent>(
      onCancel: () => subscription?.cancel(),
    );
    // Starts at once, not on listen: the scan has already been stopped.
    subscription = _service.downloadEvents.listen((event) {
      if (transfer.isClosed) return;
      switch (event) {
        case dc.DownloadProgressEvent(:final progress):
          transfer.add(TransferProgress(progress.current, progress.total));
        case dc.DiveDownloadedEvent(:final dive):
          transfer.add(
            DiveReceived(
              importedFromParsedDive(dive, product: computer.product),
            ),
          );
        case dc.PinCodeRequestEvent():
          transfer.add(const PinRequested());
        case dc.DownloadCompleteEvent():
          finish(
            TransferCompleted(
              serial: event.serialNumber,
              firmware: event.firmwareVersion,
            ),
          );
        case dc.DownloadErrorEvent(:final error):
          finish(
            TransferFailed(
              error.code,
              error.message,
              connectionLost: connectionErrorCodes.contains(error.code),
            ),
          );
      }
    });
    _service
        .startDownload(
          dc.DiscoveredDevice(
            vendor: computer.vendor,
            product: computer.product,
            model: computer.model,
            address: computer.address,
            name: computer.name,
            transport: dc.TransportType.ble,
          ),
          fingerprint: sinceFingerprint == null ? null : _hex(sinceFingerprint),
        )
        .catchError((Object e) {
          finish(TransferFailed('start_failed', '$e', connectionLost: false));
        });
    return transfer.stream;
  }

  @override
  Future<void> submitPin(String pin) => _service.submitPinCode(pin);

  /// Ends the stream once the plugin took the cancel: over BLE it reports
  /// nothing afterwards, and late events (USB flush) are not waited for.
  @override
  Future<void> cancel() async {
    await _service.cancelDownload();
    final transfer = _transfer;
    if (transfer != null && !transfer.isClosed) {
      transfer.add(const TransferCancelled());
      await transfer.close();
    }
  }

  static String _hex(Uint8List bytes) =>
      [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
}
