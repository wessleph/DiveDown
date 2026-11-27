// T23.1-T23.5: data behind the settings (ui-spec §5.11, decisions of
// 2026-11-22: one diver, renumber on request, shift with the start number).
import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_app_settings.dart';
import 'package:divedown/data/local/drift_dive_computer_repository.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/dive/diver.dart';
import 'package:divedown/domain/import/dive_computer_registry.dart';
import 'package:divedown/domain/settings/app_settings.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Dive _dive(String diverId, {required int number, required DateTime start}) =>
    Dive(
      diverId: diverId,
      number: number,
      source: DiveSource.manual,
      start: start,
      durationS: 2820,
      maxDepthM: 18.4,
    );

void main() {
  late AppDatabase db;
  late DriftDiverRepository divers;
  late DriftDiveRepository dives;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    divers = DriftDiverRepository(db);
    dives = DriftDiveRepository(db);
  });

  tearDown(() => db.close());

  Future<List<int>> numbersByDate(String diverId) async {
    final list = await dives.listForDiver(diverId); // newest first
    return [for (final d in list.reversed) d.number!];
  }

  test('T23.1 the diver can be renamed and keeps the start number', () async {
    final anna = await divers.create(
      const Diver(name: 'Anna', firstDiveNumber: 5),
    );
    await divers.update(anna.copyWith(name: 'Lena'));
    final stored = await divers.findById(anna.id!);
    expect(stored!.name, 'Lena');
    expect(stored.firstDiveNumber, 5);
  });

  test('T23.2 shifting moves every number by the difference', () async {
    final anna = await divers.create(const Diver(name: 'Anna'));
    await dives.save(
      _dive(anna.id!, number: 1, start: DateTime.utc(2026, 3, 1)),
    );
    await dives.save(
      _dive(anna.id!, number: 2, start: DateTime.utc(2026, 5, 1)),
    );

    await dives.shiftNumbers(anna.id!, 100);
    await divers.update(anna.copyWith(firstDiveNumber: 101));

    expect(await numbersByDate(anna.id!), [101, 102]);
    expect(await dives.nextNumber(anna.id!), 103);
  });

  group('T23.3 renumber by date', () {
    test('gives start, start + 1, … from the oldest dive', () async {
      final anna = await divers.create(const Diver(name: 'Anna'));
      // Imported later: the March dive got #3 after the November ones.
      await dives.save(
        _dive(anna.id!, number: 1, start: DateTime.utc(2026, 11, 13, 6)),
      );
      await dives.save(
        _dive(anna.id!, number: 2, start: DateTime.utc(2026, 11, 13, 8)),
      );
      await dives.save(
        _dive(anna.id!, number: 3, start: DateTime.utc(2026, 3, 26, 11)),
      );
      expect(await dives.numbersFollowDates(anna.id!), isFalse);

      final count = await dives.renumberByDate(anna.id!, start: 1);

      expect(count, 3);
      expect(await numbersByDate(anna.id!), [1, 2, 3]);
      final march = (await dives.listForDiver(anna.id!)).last;
      expect(march.start.month, 3);
      expect(march.number, 1);
      expect(await dives.numbersFollowDates(anna.id!), isTrue);
    });

    test('deleted dives keep their number out of the way', () async {
      final anna = await divers.create(const Diver(name: 'Anna'));
      final gone = await dives.save(
        _dive(anna.id!, number: 1, start: DateTime.utc(2026, 1, 1)),
      );
      await dives.save(
        _dive(anna.id!, number: 2, start: DateTime.utc(2026, 2, 1)),
      );
      await dives.delete(gone.dive.id!);

      expect(await dives.renumberByDate(anna.id!, start: 1), 1);
      expect(await numbersByDate(anna.id!), [1]);
    });

    test('no dives: nothing to do, and it counts as in order', () async {
      final anna = await divers.create(const Diver(name: 'Anna'));
      expect(await dives.numbersFollowDates(anna.id!), isTrue);
      expect(await dives.renumberByDate(anna.id!, start: 1), 0);
    });
  });

  test('T23.4 the theme choice is stored, system by default', () async {
    final settings = DriftAppSettings(db);
    expect(await settings.themeMode(), AppThemeMode.system);
    await settings.setThemeMode(AppThemeMode.dark);
    expect(await DriftAppSettings(db).themeMode(), AppThemeMode.dark);
  });

  test('T38.2 the profile layers are stored, null until changed', () async {
    final settings = DriftAppSettings(db);
    expect(await settings.profileLayers(), isNull);
    await settings.setProfileLayers([
      ProfileLayer.pressure,
      ProfileLayer.consumption,
    ]);
    expect(await DriftAppSettings(db).profileLayers(), [
      ProfileLayer.pressure,
      ProfileLayer.consumption,
    ]);
    await settings.setProfileLayers(const []);
    expect(await DriftAppSettings(db).profileLayers(), isEmpty);
  });

  test('T38.2 unknown names from an older or newer app are skipped', () async {
    await db
        .into(db.appMeta)
        .insertOnConflictUpdate(
          AppMetaCompanion.insert(
            key: profileLayersKey,
            value: 'ndl,temperature,something',
          ),
        );
    expect(await DriftAppSettings(db).profileLayers(), [
      ProfileLayer.temperature,
    ]);
  });

  test('T23.5 known dive computers: list and forget, dives stay', () async {
    final repo = DriftDiveComputerRepository(db);
    final eon = await repo.create(
      const KnownDiveComputer(
        id: '',
        vendor: 'Suunto',
        product: 'EON Core',
        address: 'D4:22:CD:00:3F:7A',
      ),
    );
    final anna = await divers.create(const Diver(name: 'Anna'));
    final dive = await dives.save(
      _dive(
        anna.id!,
        number: 1,
        start: DateTime.utc(2026, 11, 13),
      ).copyWith(diveComputerId: eon.id),
    );

    expect([for (final c in await repo.listAll()) c.product], ['EON Core']);
    await repo.forget(eon.id);
    expect(await repo.listAll(), isEmpty);
    expect(await repo.findByAddress('D4:22:CD:00:3F:7A'), isNull);
    expect(await dives.findById(dive.dive.id!), isNotNull);
  });
}
