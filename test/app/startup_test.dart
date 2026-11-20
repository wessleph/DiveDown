// T16.1, T16.3, T11.10: opening the database file at app start.
import 'dart:convert';
import 'dart:io';

import 'package:divedown/app/startup.dart';
import 'package:divedown/data/local/catalogue_loader.dart';
import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/data/platform/backup_exclusion.dart';
import 'package:divedown/domain/dive/diver.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class _RecordingExclusion extends BackupExclusion {
  _RecordingExclusion({this.fail = false});

  final bool fail;
  final excluded = <String>[];

  @override
  Future<void> excludeDirectory(String path) async {
    excluded.add(path);
    if (fail) throw PlatformException(code: 'exclude_failed');
  }
}

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.files);

  final Map<String, List<int>> files;
  final loaded = <String>[];

  @override
  Future<ByteData> load(String key) async {
    loaded.add(key);
    final bytes = files[key];
    if (bytes == null) throw StateError('missing asset $key');
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

List<int> _catalogue(int count) => gzip.encode(
  utf8.encode(
    jsonEncode({
      'metadata': {'format': 1, 'count': count},
      'sites': [
        for (var i = 0; i < count; i++)
          {
            'id': 'osm_$i',
            'name': 'Platz $i',
            'country_code': 'EG',
            'lat': 27.8,
            'lon': 33.9,
          },
      ],
    }),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T16.1 database file', () {
    late Directory support;

    setUp(() async {
      support = await Directory.systemTemp.createTemp('divedown_test_');
    });

    tearDown(() => support.delete(recursive: true));

    test('lives in <Application Support>/db/divedown.sqlite', () async {
      final db = await openAppDatabase(
        supportDirectory: support,
        backupExclusion: _RecordingExclusion(),
      );
      await DriftDiverRepository(db).create(const Diver(name: 'Anna'));
      await db.close();

      expect(
        File(p.join(support.path, 'db', 'divedown.sqlite')).existsSync(),
        isTrue,
      );
      expect(support.listSync().map((e) => p.basename(e.path)), [
        'db',
      ], reason: 'nothing else next to the db folder');
    });

    test('keeps data when opened again', () async {
      var db = await openAppDatabase(
        supportDirectory: support,
        backupExclusion: _RecordingExclusion(),
      );
      await DriftDiverRepository(db).create(const Diver(name: 'Anna'));
      await db.close();

      db = await openAppDatabase(
        supportDirectory: support,
        backupExclusion: _RecordingExclusion(),
      );
      expect((await DriftDiverRepository(db).list()).single.name, 'Anna');
      await db.close();
    });

    test('T11.9: excludes the db folder on every start', () async {
      final exclusion = _RecordingExclusion();
      for (var i = 0; i < 2; i++) {
        final db = await openAppDatabase(
          supportDirectory: support,
          backupExclusion: exclusion,
        );
        await db.close();
      }
      expect(exclusion.excluded, [
        p.join(support.path, 'db'),
        p.join(support.path, 'db'),
      ]);
    });

    test(
      'T16.2: a failed exclusion does not keep the logbook closed',
      () async {
        final db = await openAppDatabase(
          supportDirectory: support,
          backupExclusion: _RecordingExclusion(fail: true),
        );
        expect(await DriftDiverRepository(db).list(), isEmpty);
        await db.close();
      },
    );
  });

  group('T16.3 bundled catalogue', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('is loaded from the assets with the trimmed version', () async {
      final bundle = _FakeBundle({
        catalogueVersionAsset: utf8.encode('V1\n'),
        catalogueAsset: _catalogue(3),
      });

      await loadBundledCatalogue(db, bundle);

      expect(await CatalogueLoader(db).count(), 3);
      final again = _FakeBundle({
        catalogueVersionAsset: utf8.encode('V1'),
        catalogueAsset: _catalogue(5),
      });
      await loadBundledCatalogue(db, again);
      expect(await CatalogueLoader(db).count(), 3);
      expect(again.loaded, isNot(contains(catalogueAsset)));
    });

    test('the real assets are declared in pubspec and load', () async {
      // Uses the bundle flutter_test builds from pubspec.yaml.
      await loadBundledCatalogue(db, rootBundle);
      expect(await CatalogueLoader(db).count(), greaterThan(5000));
    });
  });

  group('T11.10 Android backup rules', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    String xml(String name) =>
        File('android/app/src/main/res/xml/$name.xml').readAsStringSync();

    /// The part of [doc] between `<tag` and `</tag>`.
    String section(String doc, String tag) {
      final m = RegExp('<$tag[\\s>][\\s\\S]*?</$tag>').firstMatch(doc);
      expect(m, isNotNull, reason: '<$tag> missing');
      return m!.group(0)!;
    }

    final excludeDb = RegExp(r'<exclude\s+domain="file"\s+path="db/?"\s*/>');

    test('manifest points to both rule files', () {
      expect(
        manifest,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      );
      expect(
        manifest,
        contains('android:fullBackupContent="@xml/backup_rules"'),
      );
    });

    test('Android 12+: db excluded from cloud backup and device transfer', () {
      final rules = xml('data_extraction_rules');
      expect(section(rules, 'cloud-backup'), matches(excludeDb));
      expect(section(rules, 'device-transfer'), matches(excludeDb));
    });

    test('Android 8-11 (minSdk 26): db excluded from full backup', () {
      expect(
        section(xml('backup_rules'), 'full-backup-content'),
        matches(excludeDb),
      );
    });
  });
}
