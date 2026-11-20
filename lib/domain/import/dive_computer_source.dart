import 'dart:typed_data';

import 'imported_dive.dart';

/// A dive computer found by the BLE scan (design.md §4.1).
class DiscoveredComputer {
  const DiscoveredComputer({
    required this.name,
    required this.vendor,
    required this.product,
    required this.model,
    required this.address,
  });

  /// Model code for a computer the scan recognises but libdivecomputer
  /// cannot read, e.g. the Suunto Ocean (ui-spec §5.6, T12.7).
  static const unsupportedModel = -1;

  /// Advertised BLE name, e.g. „EON Core“.
  final String name;
  final String vendor;
  final String product;
  final int model;

  /// BLE address (Android) or identifier (iOS).
  final String address;

  bool get supported => model != unsupportedModel;

  /// Last four hex digits of the address, for the PIN dialog: „3F7A“
  /// (security.md: say which device asks).
  String get shortId => throw UnimplementedError('shortId');
}

/// What a download reports, in order. Ends with exactly one of
/// [TransferCompleted], [TransferCancelled] or [TransferFailed].
sealed class TransferEvent {
  const TransferEvent();
}

/// Bytes read so far; [total] is 0 when unknown.
class TransferProgress extends TransferEvent {
  const TransferProgress(this.current, this.total);

  final int current;
  final int total;
}

class DiveReceived extends TransferEvent {
  const DiveReceived(this.dive);

  final ImportedDive dive;
}

/// The computer asks for the code it shows on its display.
class PinRequested extends TransferEvent {
  const PinRequested();
}

class TransferCompleted extends TransferEvent {
  const TransferCompleted({this.serial, this.firmware});

  final String? serial;
  final String? firmware;
}

/// The user cancelled; dives received before stay valid (ui-spec §5.7).
class TransferCancelled extends TransferEvent {
  const TransferCancelled();
}

class TransferFailed extends TransferEvent {
  const TransferFailed(this.code, this.message, {required this.connectionLost});

  final String code;
  final String message;

  /// Connection could not be made or broke off (ui-spec §5.7 „Verbindung
  /// abgebrochen“); otherwise an unexpected error (§4).
  final bool connectionLost;
}

/// The BLE import source (design.md §3).
abstract interface class DiveComputerSource {
  /// Scans until the platform ends the scan or [stopDiscovery] is called;
  /// the stream then closes. Each address is reported once.
  Stream<DiscoveredComputer> discover();

  Future<void> stopDiscovery();

  /// Reads only dives newer than [sinceFingerprint] (T3.2).
  Stream<TransferEvent> download(
    DiscoveredComputer computer, {
    Uint8List? sinceFingerprint,
  });

  Future<void> submitPin(String pin);

  /// Ends the running download with [TransferCancelled].
  Future<void> cancel();
}
