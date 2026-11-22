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
  Future<KnownDiveComputer?> findById(String id);

  /// Known dive computers that are not forgotten, newest first (§5.11).
  Future<List<KnownDiveComputer>> listAll();

  /// „Vergessen“ (ui-spec §5.11): soft delete, the dives stay.
  Future<void> forget(String id);
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

  final DiveComputerRepository _computers;

  Future<DownloadSession> begin({
    required String vendor,
    required String product,
    required int model,
    required String address,
  }) async => DownloadSession(
    vendor: vendor,
    product: product,
    model: model,
    address: address,
    known: await _computers.findByAddress(address),
  );

  /// The device the dives of [session] belong to, found by address or, from
  /// a new phone, by [serial] (T3.7). Unknown devices are created without a
  /// fingerprint, so dives can point to them before [finish] runs.
  Future<KnownDiveComputer> ensure(
    DownloadSession session, {
    String? serial,
    String? firmware,
  }) async {
    final known =
        session.known ??
        (serial == null
            ? null
            : await _computers.findBySerial(session.vendor, serial));
    if (known != null) return known;
    return _computers.create(
      KnownDiveComputer(
        id: '',
        vendor: session.vendor,
        product: session.product,
        model: session.model,
        serial: serial,
        firmware: firmware,
        address: session.address,
      ),
    );
  }

  /// Call when the download ended. Writes the fingerprint of the newest of
  /// [savedDives] only if the download [completed], something was saved and
  /// the serial matches.
  Future<DownloadOutcome> finish(
    DownloadSession session, {
    required bool completed,
    required String? serial,
    String? firmware,
    required List<ImportedDive> savedDives,
  }) async {
    if (!completed || savedDives.isEmpty) return const FingerprintKept();
    final fingerprint = _newest(savedDives).fingerprint;

    final known = session.known;
    if (known != null) {
      final stored = known.serial;
      if (serial != null && stored != null && serial != stored) {
        return SerialMismatch(known, serial);
      }
      return FingerprintStored(
        await _store(known, session, serial, firmware, fingerprint),
      );
    }

    // Unknown address: maybe a known device seen from a new phone (T3.7).
    final bySerial = serial == null
        ? null
        : await _computers.findBySerial(session.vendor, serial);
    if (bySerial != null) {
      return FingerprintStored(
        await _store(bySerial, session, serial, firmware, fingerprint),
      );
    }
    return FingerprintStored(
      await _computers.create(
        KnownDiveComputer(
          id: '',
          vendor: session.vendor,
          product: session.product,
          model: session.model,
          serial: serial,
          firmware: firmware,
          address: session.address,
          lastFingerprint: fingerprint,
        ),
      ),
    );
  }

  /// After [SerialMismatch], „Als neues Gerät verwenden“ (T3.5): stores the
  /// device as a new one; the old device stays untouched.
  Future<KnownDiveComputer> registerAsNew(
    DownloadSession session, {
    required String serial,
    String? firmware,
    required List<ImportedDive> savedDives,
  }) async {
    final old = session.known;
    if (old != null) {
      // The address now belongs to the new device; the old one keeps its
      // serial and fingerprint for when it shows up again.
      await _computers.update(_with(old, address: null));
    }
    return _computers.create(
      KnownDiveComputer(
        id: '',
        vendor: session.vendor,
        product: session.product,
        model: session.model,
        serial: serial,
        firmware: firmware,
        address: session.address,
        lastFingerprint: savedDives.isEmpty
            ? null
            : _newest(savedDives).fingerprint,
      ),
    );
  }

  Future<KnownDiveComputer> _store(
    KnownDiveComputer computer,
    DownloadSession session,
    String? serial,
    String? firmware,
    Uint8List? fingerprint,
  ) async {
    final updated = KnownDiveComputer(
      id: computer.id,
      vendor: computer.vendor,
      product: computer.product,
      model: computer.model ?? session.model,
      serial: serial ?? computer.serial,
      firmware: firmware ?? computer.firmware,
      address: session.address,
      lastFingerprint: fingerprint ?? computer.lastFingerprint,
    );
    await _computers.update(updated);
    return updated;
  }

  static KnownDiveComputer _with(KnownDiveComputer c, {String? address}) =>
      KnownDiveComputer(
        id: c.id,
        vendor: c.vendor,
        product: c.product,
        model: c.model,
        serial: c.serial,
        firmware: c.firmware,
        address: address,
        lastFingerprint: c.lastFingerprint,
      );

  /// The dive with the latest wall-clock start.
  static ImportedDive _newest(List<ImportedDive> dives) =>
      dives.reduce((a, b) => b.start.isAfter(a.start) ? b : a);
}
