// T3.1-T3.7: device identity and fingerprint (security A1, design.md §4.1).
import 'dart:typed_data';

import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_dive_computer_repository.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/import/dive_computer_registry.dart';
import 'package:divedown/domain/import/imported_dive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _address = 'AA:BB:CC:DD:CC:2D';

ImportedDive _dive(int day, List<int> fingerprint) => ImportedDive(
  source: DiveSource.diveComputer,
  sourceId: 'EON Core:$day',
  start: DateTime.utc(2026, 11, day, 9),
  durationS: 2820,
  maxDepthM: 18,
  fingerprint: Uint8List.fromList(fingerprint),
);

void main() {
  late AppDatabase db;
  late DriftDiveComputerRepository computers;
  late DiveComputerRegistry registry;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    computers = DriftDiveComputerRepository(db);
    registry = DiveComputerRegistry(computers);
  });

  tearDown(() => db.close());

  Future<DownloadSession> begin() => registry.begin(
    vendor: 'Suunto',
    product: 'EON Core',
    model: 1,
    address: _address,
  );

  /// Stores EON Core S with fingerprint F, as after an earlier download.
  Future<KnownDiveComputer> seedKnown() async {
    final session = await begin();
    await registry.finish(
      session,
      completed: true,
      serial: 'S',
      firmware: '4.0.1131',
      savedDives: [
        _dive(1, [0xF0]),
      ],
    );
    return (await computers.findByAddress(_address))!;
  }

  test(
    'T3.1 unknown device: stored with the newest saved fingerprint',
    () async {
      final session = await begin();
      expect(session.known, isNull);
      expect(session.sinceFingerprint, isNull);

      final outcome = await registry.finish(
        session,
        completed: true,
        serial: 'S',
        firmware: '4.0.1131',
        // Not sorted: newest is day 13.
        savedDives: [
          _dive(10, [1]),
          _dive(13, [3]),
          _dive(12, [2]),
        ],
      );

      final stored = (outcome as FingerprintStored).computer;
      expect(stored.serial, 'S');
      expect(stored.firmware, '4.0.1131');
      expect(stored.address, _address);
      expect(stored.vendor, 'Suunto');
      expect(stored.product, 'EON Core');
      expect(stored.model, 1);
      expect(stored.lastFingerprint, [3]);
      expect((await computers.findBySerial('Suunto', 'S'))!.id, stored.id);
    },
  );

  test('T3.2 known device: the plugin gets its fingerprint', () async {
    await seedKnown();

    final session = await begin();
    expect(session.known, isNotNull);
    expect(session.sinceFingerprint, [0xF0]);
  });

  test('T3.3 cancelled after 2 dives: fingerprint unchanged', () async {
    await seedKnown();
    final session = await begin();

    final outcome = await registry.finish(
      session,
      completed: false,
      serial: 'S',
      savedDives: [
        _dive(14, [4]),
        _dive(15, [5]),
      ],
    );

    expect(outcome, isA<FingerprintKept>());
    expect((await computers.findByAddress(_address))!.lastFingerprint, [0xF0]);
  });

  test(
    'T3.4 other serial at the same address: warning, nothing written',
    () async {
      final known = await seedKnown();
      final session = await begin();

      final outcome = await registry.finish(
        session,
        completed: true,
        serial: 'S2',
        savedDives: [
          _dive(14, [4]),
        ],
      );

      final mismatch = outcome as SerialMismatch;
      expect(mismatch.known.id, known.id);
      expect(mismatch.reportedSerial, 'S2');
      final after = (await computers.findByAddress(_address))!;
      expect(after.lastFingerprint, [0xF0]);
      expect(after.serial, 'S');
    },
  );

  test(
    'T3.5 „Als neues Gerät verwenden“: new device, old one untouched',
    () async {
      final known = await seedKnown();
      final session = await begin();

      final added = await registry.registerAsNew(
        session,
        serial: 'S2',
        savedDives: [
          _dive(14, [4]),
        ],
      );

      expect(added.id, isNot(known.id));
      expect(added.serial, 'S2');
      expect(added.lastFingerprint, [4]);
      final old = (await computers.findBySerial('Suunto', 'S'))!;
      expect(old.lastFingerprint, [0xF0]);
      // The address now belongs to the new device for the next download.
      expect((await computers.findByAddress(_address))!.id, added.id);
    },
  );

  test('T3.6 preview left without saving: no fingerprint', () async {
    await seedKnown();
    final session = await begin();

    final outcome = await registry.finish(
      session,
      completed: true,
      serial: 'S',
      savedDives: const [],
    );

    expect(outcome, isA<FingerprintKept>());
    expect((await computers.findByAddress(_address))!.lastFingerprint, [0xF0]);
  });

  test('T3.6 nothing saved from an unknown device: nothing stored', () async {
    final session = await begin();
    final outcome = await registry.finish(
      session,
      completed: true,
      serial: 'S',
      savedDives: const [],
    );

    expect(outcome, isA<FingerprintKept>());
    expect(await computers.findByAddress(_address), isNull);
  });

  test('T3.7 known serial at a new address (new phone): same device', () async {
    final known = await seedKnown();
    final session = await registry.begin(
      vendor: 'Suunto',
      product: 'EON Core',
      model: 1,
      address: '11:22:33:44:55:66',
    );
    expect(session.known, isNull, reason: 'address unknown before download');

    final outcome = await registry.finish(
      session,
      completed: true,
      serial: 'S',
      savedDives: [
        _dive(14, [4]),
      ],
    );

    final stored = (outcome as FingerprintStored).computer;
    expect(stored.id, known.id);
    expect(stored.address, '11:22:33:44:55:66');
    expect(stored.lastFingerprint, [4]);
  });
}
