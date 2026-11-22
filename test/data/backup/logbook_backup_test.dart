// T11.1-T11.8: backup and restore of the logbook (security.md O1 a),
// ui-spec §5.12). Real database files in a temporary folder.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:divedown/app/startup.dart';
import 'package:divedown/data/backup/logbook_backup.dart';
import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/dive/diver.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('divedown_backup_'));
  tearDown(() => root.deleteSync(recursive: true));

  Directory folder(String name) =>
      Directory(p.join(root.path, name, databaseFolderName))
        ..createSync(recursive: true);

  AppDatabase open(Directory dir) =>
      AppDatabase(NativeDatabase(File(p.join(dir.path, databaseFileName))));

  /// One diver with ten dives (one diver per app, ui-spec §2).
  Future<AppDatabase> seeded(Directory dir) async {
    final db = open(dir);
    final diver = await DriftDiverRepository(db)
        .create(const Diver(name: 'Anna', firstDiveNumber: 101));
    final dives = DriftDiveRepository(db);
    for (var i = 0; i < 10; i++) {
      await dives.save(
        Dive(
          diverId: diver.id!,
          source: DiveSource.manual,
          siteName: 'Platz $i',
          start: DateTime.utc(2026, 11, 1 + i, 9),
          durationS: 2400 + i,
          maxDepthM: 10.0 + i,
          samples: [
            for (var t = 0; t <= 600; t += 60) DiveSample(timeS: t, depthM: 5),
          ],
        ),
      );
    }
    return db;
  }

  LogbookBackup backupFor(Directory dir, {int? maxBytes, DatabaseWriter? w}) =>
      LogbookBackup(
        folder: dir,
        appVersion: '1.0.0',
        maxBytes: maxBytes ?? maxBackupBytes,
        writeDatabase: w,
      );

  Archive unzip(Uint8List bytes) => ZipDecoder().decodeBytes(bytes);

  Uint8List zip(Map<String, List<int>> entries) {
    final archive = Archive();
    for (final e in entries.entries) {
      archive.addFile(ArchiveFile.bytes(e.key, e.value));
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  Map<String, Object?> manifestOf(Uint8List bytes) {
    final file = unzip(bytes).findFile('manifest.json')!;
    return jsonDecode(utf8.decode(file.content)) as Map<String, Object?>;
  }

  List<int> dbOf(Uint8List bytes) =>
      unzip(bytes).findFile('divedown.sqlite')!.content;

  test('T11.1 the backup is a ZIP with the database and a manifest', () async {
    final dir = folder('a');
    final db = await seeded(dir);
    addTearDown(db.close);

    final bytes = await backupFor(dir).create(db);

    final names = {for (final f in unzip(bytes).files) f.name};
    expect(names, {'manifest.json', 'divedown.sqlite'});
    final manifest = manifestOf(bytes);
    expect(manifest['format'], 1);
    expect(manifest['appVersion'], '1.0.0');
    expect(manifest['schemaVersion'], db.schemaVersion);
    expect(manifest['diveCount'], 10);
    expect(DateTime.parse(manifest['createdAt']! as String).isUtc, isTrue);
    expect(manifest['sha256'], sha256.convert(dbOf(bytes)).toString());
    expect(utf8.decode(dbOf(bytes).sublist(0, 15)), 'SQLite format 3');

    final check = backupFor(dir).inspect(bytes);
    expect(check, isA<BackupReadable>());
    expect((check as BackupReadable).manifest.diveCount, 10);
  });

  test('T11.2 restore into an empty app gives the same logbook', () async {
    final source = folder('source');
    final db = await seeded(source);
    final bytes = await backupFor(source).create(db);
    await db.close();

    final target = folder('target');
    final empty = open(target);
    await DriftDiverRepository(empty).list(); // creates the empty schema
    var closed = false;

    final result = await backupFor(target).restore(
      bytes,
      closeDatabase: () async {
        closed = true;
        await empty.close();
      },
    );

    expect(result, isA<Restored>());
    expect(closed, isTrue);
    final restored = open(target);
    addTearDown(restored.close);
    final divers = await DriftDiverRepository(restored).list();
    expect(divers.single.name, 'Anna');
    expect(divers.single.firstDiveNumber, 101);
    final dives = await DriftDiveRepository(restored)
        .listForDiver(divers.single.id!);
    expect(dives, hasLength(10));
    expect(
      [for (final d in dives.reversed) d.number],
      [for (var n = 101; n <= 110; n++) n],
    );
    expect(dives.first.siteName, 'Platz 9');
    expect(dives.first.samples, hasLength(11));
  });

  test(
    'T11.3 wrong checksum: corrupt, the live database is untouched',
    () async {
      final dir = folder('a');
      final db = await seeded(dir);
      addTearDown(db.close);
      final good = await backupFor(dir).create(db);
      final broken = Uint8List.fromList(dbOf(good));
      broken[broken.length ~/ 2] ^= 0xFF;
      final bytes = zip({
        'manifest.json': utf8.encode(jsonEncode(manifestOf(good))),
        'divedown.sqlite': broken,
      });

      expect(
        (backupFor(dir).inspect(bytes) as BackupRejected).problem,
        BackupProblem.corrupt,
      );
      var closed = false;
      final result = await backupFor(dir)
          .restore(bytes, closeDatabase: () async => closed = true);
      expect((result as RestoreRejected).problem, BackupProblem.corrupt);
      expect(closed, isFalse);
      expect(await DriftDiverRepository(db).list(), hasLength(1));
    },
  );

  test('T11.4 schema newer than the app: newerVersion', () async {
    final dir = folder('a');
    final db = await seeded(dir);
    addTearDown(db.close);
    final good = await backupFor(dir).create(db);
    final manifest = manifestOf(good)..['schemaVersion'] = db.schemaVersion + 1;
    final bytes = zip({
      'manifest.json': utf8.encode(jsonEncode(manifest)),
      'divedown.sqlite': dbOf(good),
    });

    expect(
      (backupFor(dir).inspect(bytes) as BackupRejected).problem,
      BackupProblem.newerVersion,
    );
  });

  group('T11.5 invalid files', () {
    test('an entry named ../evil: invalid, nothing written outside', () async {
      final dir = folder('a');
      final db = await seeded(dir);
      addTearDown(db.close);
      final good = await backupFor(dir).create(db);
      final bytes = zip({
        'manifest.json': utf8.encode(jsonEncode(manifestOf(good))),
        'divedown.sqlite': dbOf(good),
        '../evil': utf8.encode('x'),
      });

      final result = await backupFor(dir)
          .restore(bytes, closeDatabase: () async {});
      expect((result as RestoreRejected).problem, BackupProblem.invalid);
      expect(File(p.join(dir.parent.path, 'evil')).existsSync(), isFalse);
      expect(File(p.join(dir.path, 'evil')).existsSync(), isFalse);
    });

    test('not a ZIP, or no manifest: invalid', () {
      final backup = backupFor(folder('a'));
      expect(
        (backup.inspect(
          Uint8List.fromList(utf8.encode('hello')),
        ) as BackupRejected).problem,
        BackupProblem.invalid,
      );
      expect(
        (backup.inspect(
          zip({
            'divedown.sqlite': [1, 2, 3],
          }),
        ) as BackupRejected).problem,
        BackupProblem.invalid,
      );
    });
  });

  test('T11.6 writing fails: the previous logbook comes back', () async {
    final source = folder('source');
    final other = await seeded(source);
    final bytes = await backupFor(source).create(other);
    await other.close();

    final dir = folder('live');
    final live = open(dir);
    final anna = await DriftDiverRepository(live)
        .create(const Diver(name: 'Lena'));
    await DriftDiveRepository(live).save(
      Dive(
        diverId: anna.id!,
        source: DiveSource.manual,
        start: DateTime.utc(2026, 1, 1),
        durationS: 60,
        maxDepthM: 3,
      ),
    );

    final failing = backupFor(
      dir,
      w: (target, data) async {
        await target.writeAsBytes(data.sublist(0, data.length ~/ 3));
        throw const FileSystemException('disk full');
      },
    );
    final result = await failing.restore(bytes, closeDatabase: live.close);

    expect(result, isA<RestoreFailed>());
    final reopened = open(dir);
    addTearDown(reopened.close);
    final divers = await DriftDiverRepository(reopened).list();
    expect(divers.single.name, 'Lena');
    expect(
      await DriftDiveRepository(reopened).listForDiver(divers.single.id!),
      hasLength(1),
    );
  });

  test('T11.7 larger than the limit: tooLarge before reading', () {
    final backup = backupFor(folder('a'), maxBytes: 1000);
    final check = backup.inspect(Uint8List(1001));
    expect((check as BackupRejected).problem, BackupProblem.tooLarge);
  });

  group('T11.8 reminder', () {
    final now = DateTime.utc(2026, 12, 20, 12);

    test('more than 30 days after the last backup', () {
      expect(
        backupReminderDue(
          now: now,
          lastBackup: now.subtract(const Duration(days: 31)),
        ),
        isTrue,
      );
      expect(
        backupReminderDue(
          now: now,
          lastBackup: now.subtract(const Duration(days: 29)),
        ),
        isFalse,
      );
    });

    test('never backed up: counts from the first start', () {
      expect(
        backupReminderDue(
          now: now,
          baseline: now.subtract(const Duration(days: 34)),
        ),
        isTrue,
      );
      expect(
        backupReminderDue(
          now: now,
          baseline: now.subtract(const Duration(days: 3)),
        ),
        isFalse,
      );
    });

    test('snoozed for 7 days, and never without dives', () {
      final old = now.subtract(const Duration(days: 60));
      expect(
        backupReminderDue(
          now: now,
          lastBackup: old,
          snoozedUntil: now.add(const Duration(days: 1)),
        ),
        isFalse,
      );
      expect(
        backupReminderDue(
          now: now,
          lastBackup: old,
          snoozedUntil: now.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
      expect(
        backupReminderDue(now: now, lastBackup: old, hasDives: false),
        isFalse,
      );
    });
  });
}
