import 'dart:typed_data';

import 'imported_dive.dart';

/// A dive computer the app has downloaded from before (ADR 0004).
class KnownDiveComputer {
  const KnownDiveComputer({
    required this.id,
    required this.vendor,
    required this.product,
    this.model,
    this.serial,
    this.firmware,
    this.address,
    this.lastFingerprint,
  });

  final String id;
  final String vendor;
  final String product;
  final int? model;
  final String? serial;
  final String? firmware;

  /// BLE address (Android) or identifier (iOS).
  final String? address;
  final Uint8List? lastFingerprint;
}

abstract interface class DiveComputerRepository {
  Future<KnownDiveComputer?> findByAddress(String address);
  Future<KnownDiveComputer?> findBySerial(String vendor, String serial);
  Future<KnownDiveComputer> create(KnownDiveComputer computer);
  Future<void> update(KnownDiveComputer computer);
}

/// The device the user picked for one download.
class DownloadSession {
  const DownloadSession({
    required this.vendor,
    required this.product,
    required this.model,
    required this.address,
    this.known,
  });

  final String vendor;
  final String product;
  final int model;
  final String address;

  /// Stored device with this address, if any.
  final KnownDiveComputer? known;

  /// Passed to the plugin so only newer dives come (T3.2).
  Uint8List? get sinceFingerprint => known?.lastFingerprint;
}

sealed class DownloadOutcome {
  const DownloadOutcome();
}

/// Device stored or updated, fingerprint of the newest saved dive written.
class FingerprintStored extends DownloadOutcome {
  const FingerprintStored(this.computer);

  final KnownDiveComputer computer;
}

/// Nothing written: download cancelled or no dive saved (T3.3, T3.6).
class FingerprintKept extends DownloadOutcome {
  const FingerprintKept();
}

/// The device reports another serial than stored for this address
/// (security A1, T3.4). Nothing written; the app warns.
class SerialMismatch extends DownloadOutcome {
  const SerialMismatch(this.known, this.reportedSerial);

  final KnownDiveComputer known;
  final String reportedSerial;
}

/// Binds dive computers to their serial number and keeps the fingerprint
/// of the last saved dive (security.md A1, design.md §4.1).
class DiveComputerRegistry {
  DiveComputerRegistry(this._computers);

  // ignore: unused_field
  final DiveComputerRepository _computers;

  Future<DownloadSession> begin({
    required String vendor,
    required String product,
    required int model,
    required String address,
  }) => throw UnimplementedError('T3: DiveComputerRegistry.begin');

  /// Call when the download ended. Writes the fingerprint of the newest of
  /// [savedDives] only if the download [completed], something was saved and
  /// the serial matches.
  Future<DownloadOutcome> finish(
    DownloadSession session, {
    required bool completed,
    required String? serial,
    String? firmware,
    required List<ImportedDive> savedDives,
  }) => throw UnimplementedError('T3: DiveComputerRegistry.finish');

  /// After [SerialMismatch], „Als neues Gerät verwenden“ (T3.5): stores the
  /// device as a new one; the old device stays untouched.
  Future<KnownDiveComputer> registerAsNew(
    DownloadSession session, {
    required String serial,
    String? firmware,
    required List<ImportedDive> savedDives,
  }) => throw UnimplementedError('T3.5: DiveComputerRegistry.registerAsNew');
}
