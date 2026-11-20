// T17.1-T17.9: BLE import from download to logbook (design.md §4.1).
import 'dart:typed_data';

import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_dive_computer_repository.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/domain/dive/diver.dart';
import 'package:divedown/domain/import/dive_computer_import.dart';
import 'package:divedown/domain/import/dive_computer_registry.dart';
import 'package:divedown/domain/import/dive_computer_source.dart';
import 'package:divedown/domain/import/import_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dive_computer.dart';

void main() {
  late AppDatabase db;
  late DriftDiveRepository dives;
  late DriftDiveComputerRepository computers;
  late FakeDiveComputerSource source;
  late DiveComputerImport import;
  late String anna;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dives = DriftDiveRepository(db);
    computers = DriftDiveComputerRepository(db);
    source = FakeDiveComputerSource();
    import = DiveComputerImport(
      source: source,
      registry: DiveComputerRegistry(computers),
      importService: ImportService(dives),
    );
    anna = (await DriftDiverRepository(db).create(Diver(name: 'Anna'))).id!;
  });

  tearDown(() => db.close());

  /// EON Core with serial S and fingerprint [0xF0], as after an earlier import.
  Future<KnownDiveComputer> seedKnown({String serial = 'S'}) =>
      computers.create(
        KnownDiveComputer(
          id: '',
          vendor: 'Suunto',
          product: 'EON Core',
          model: 1,
          serial: serial,
          address: eonCore.address,
          lastFingerprint: Uint8List.fromList([0xF0]),
        ),
      );

  Set<int> all(DownloadResult r) => {
    for (var i = 0; i < r.dives.length; i++) i,
  };

  test(
    'T17.1 completed download: dives in order, serial, events seen',
    () async {
      await seedKnown();
      source.script = [
        const TransferProgress(100, 400),
        DiveReceived(computerDive(12)),
        DiveReceived(computerDive(13)),
        const TransferCompleted(serial: 'S', firmware: '4.0.1131'),
      ];
      final seen = <TransferEvent>[];

      final result = await import.download(eonCore, onEvent: seen.add);

      expect(source.downloads.single.since, [0xF0]);
      expect(result.end, DownloadEnd.completed);
      expect(result.dives.map((d) => d.sourceId), [
        'EON Core:12',
        'EON Core:13',
      ]);
      expect(result.serial, 'S');
      expect(result.firmware, '4.0.1131');
      expect(result.serialMismatch, isNull);
      expect(seen.whereType<TransferProgress>(), hasLength(1));
      expect(seen.whereType<DiveReceived>(), hasLength(2));
    },
  );

  test('T17.2 first import: saved, linked to the new device, '
      'next download starts after the newest dive', () async {
    source.script = [
      DiveReceived(computerDive(13)),
      DiveReceived(computerDive(12)),
      const TransferCompleted(serial: 'S', firmware: '4.0.1131'),
    ];
    final result = await import.download(eonCore);

    final saved = await import.save(anna, result, selected: all(result));

    expect(saved.savedCount, 2);
    final device = (saved.device as FingerprintStored).computer;
    expect(device.serial, 'S');
    expect(device.lastFingerprint, [13]);
    final logbook = await dives.listForDiver(anna);
    expect(logbook, hasLength(2));
    expect(logbook.map((d) => d.diveComputerId).toSet(), {device.id});

    source.script = [const TransferCompleted(serial: 'S')];
    await import.download(eonCore);
    expect(source.downloads.last.since, [13]);
  });

  test('T17.3 cancelled after 2 dives: both can be saved, '
      'fingerprint unchanged', () async {
    final known = await seedKnown();
    source.script = [
      DiveReceived(computerDive(12)),
      DiveReceived(computerDive(13)),
    ];
    final running = import.download(eonCore);
    await pumpEventQueue();
    await import.cancel();
    final result = await running;

    expect(source.cancelCalls, 1);
    expect(result.end, DownloadEnd.cancelled);
    expect(result.dives, hasLength(2));

    final saved = await import.save(anna, result, selected: all(result));
    expect(saved.savedCount, 2);
    expect(saved.device, isA<FingerprintKept>());
    final stored = await computers.findByAddress(eonCore.address);
    expect(stored!.lastFingerprint, known.lastFingerprint);
    expect(
      (await dives.listForDiver(anna)).map((d) => d.diveComputerId).toSet(),
      {known.id},
    );
  });

  test('T17.4 connection lost after 1 dive: dive kept, '
      'fingerprint unchanged', () async {
    final known = await seedKnown();
    source.script = [
      DiveReceived(computerDive(12)),
      const TransferFailed('download_error', 'GATT 133', connectionLost: true),
    ];

    final result = await import.download(eonCore);

    expect(result.end, DownloadEnd.connectionLost);
    expect(result.errorCode, 'download_error');
    expect(result.dives, hasLength(1));
    await import.save(anna, result, selected: all(result));
    final stored = await computers.findByAddress(eonCore.address);
    expect(stored!.lastFingerprint, known.lastFingerprint);
  });

  test('T17.5 unexpected error is not a lost connection', () async {
    source.script = [
      const TransferFailed('download_crashed', 'x', connectionLost: false),
    ];

    final result = await import.download(eonCore);

    expect(result.end, DownloadEnd.failed);
    expect(result.errorCode, 'download_crashed');
  });

  group('T17.6 serial mismatch (security A1)', () {
    test('reported before the preview', () async {
      final known = await seedKnown();
      source.script = [
        DiveReceived(computerDive(12)),
        const TransferCompleted(serial: 'OTHER'),
      ];

      final result = await import.download(eonCore);

      expect(result.serialMismatch?.id, known.id);
      expect(result.serial, 'OTHER');
    });

    test(
      '„Als neues Gerät verwenden“: new device, old one untouched',
      () async {
        final known = await seedKnown();
        source.script = [
          DiveReceived(computerDive(12)),
          const TransferCompleted(serial: 'OTHER'),
        ];
        final result = await import.download(eonCore);

        final saved = await import.save(
          anna,
          result,
          selected: all(result),
          asNewDevice: true,
        );

        final fresh = (saved.device as FingerprintStored).computer;
        expect(fresh.id, isNot(known.id));
        expect(fresh.serial, 'OTHER');
        expect(fresh.lastFingerprint, [12]);
        final old = await computers.findBySerial('Suunto', 'S');
        expect(old!.lastFingerprint, [0xF0]);
        expect(
          (await dives.listForDiver(anna)).single.diveComputerId,
          fresh.id,
        );
      },
    );
  });

  test(
    'T17.7 nothing selected: nothing saved, fingerprint unchanged',
    () async {
      final known = await seedKnown();
      source.script = [
        DiveReceived(computerDive(12)),
        const TransferCompleted(serial: 'S'),
      ];
      final result = await import.download(eonCore);

      final saved = await import.save(anna, result, selected: const {});

      expect(saved.results, isEmpty);
      expect(saved.device, isA<FingerprintKept>());
      expect(await dives.listForDiver(anna), isEmpty);
      final stored = await computers.findByAddress(eonCore.address);
      expect(stored!.lastFingerprint, known.lastFingerprint);
    },
  );

  test('T17.8 preview and save with duplicates', () async {
    // Already in the logbook: day 12 exactly, and one close to day 13.
    source.script = [
      DiveReceived(computerDive(12)),
      const TransferCompleted(serial: 'S'),
    ];
    final first = await import.download(eonCore);
    await import.save(anna, first, selected: all(first));
    await dives.save(computerDive(13, fingerprint: 99).toDive(diverId: anna));

    source.script = [
      DiveReceived(computerDive(12)),
      DiveReceived(computerDive(13)),
      DiveReceived(computerDive(14)),
      const TransferCompleted(serial: 'S'),
    ];
    final result = await import.download(eonCore);
    final preview = await import.preview(anna, result);

    expect(preview[0], isA<SkippedDuplicate>());
    expect(preview[1], isA<NeedsConfirmation>());
    expect(preview[2], isA<Saved>());

    final saved = await import.save(
      anna,
      result,
      selected: {1, 2},
      confirmed: {1},
    );
    expect(saved.savedCount, 2);
    expect(await dives.listForDiver(anna), hasLength(4));
  });

  test('T17.9 no new dives, and the PIN goes to the computer', () async {
    source.script = [const PinRequested(), const TransferCompleted()];
    final seen = <TransferEvent>[];

    final result = await import.download(
      eonCore,
      onEvent: (e) {
        seen.add(e);
        if (e is PinRequested) import.submitPin('1234');
      },
    );

    expect(seen.first, isA<PinRequested>());
    expect(source.pins, ['1234']);
    expect(result.end, DownloadEnd.completed);
    expect(result.dives, isEmpty);
  });
}
