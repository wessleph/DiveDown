// T5.9: a file shared from another app („Teilen → DiveDown“, security A2).
import 'dart:io';
import 'dart:typed_data';

import 'package:divedown/data/import/fit/shared_file_reader.dart';
import 'package:divedown/domain/import/file_import.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory cache;
  late Directory databases;

  setUp(() {
    root = Directory.systemTemp.createTempSync('divedown_share_');
    cache = Directory(p.join(root.path, 'cache'))..createSync();
    databases = Directory(p.join(root.path, 'databases'))..createSync();
  });

  tearDown(() => root.deleteSync(recursive: true));

  test(
    'file in the cache: read into memory, name shown, copy removed',
    () async {
      final file = File(p.join(cache.path, 'Tauchgang 14.11.fit'))
        ..writeAsBytesSync([1, 2, 3]);

      final result = await readSharedFile(file.path, allowedDirs: [cache]);

      final picked = (result as Picked).file;
      expect(picked.displayName, 'Tauchgang 14.11.fit');
      expect(picked.bytes, Uint8List.fromList([1, 2, 3]));
      expect(file.existsSync(), isFalse);
    },
  );

  test('T5.9 name with ../: never used as a path, nothing outside the cache '
      'read, written or deleted', () async {
    final outside = File(p.join(databases.path, 'x.fit'))
      ..writeAsBytesSync([9, 9]);
    final sneaky = p.join(
      cache.path,
      '..',
      '..',
      p.basename(root.path),
      'databases',
      'x.fit',
    );

    final result = await readSharedFile(sneaky, allowedDirs: [cache]);

    expect(result, isA<PickFailed>());
    expect((result as PickFailed).reason, FileImportFailure.unreadable);
    expect(result.displayName, 'x.fit');
    expect(outside.readAsBytesSync(), [9, 9]);
    expect(databases.listSync(), hasLength(1));
  });

  test('larger than 10 MB: tooLarge, copy removed', () async {
    final file = File(p.join(cache.path, 'big.fit'))
      ..writeAsBytesSync(Uint8List(11));

    final result = await readSharedFile(
      file.path,
      allowedDirs: [cache],
      maxBytes: 10,
    );

    expect((result as PickFailed).reason, FileImportFailure.tooLarge);
    expect(file.existsSync(), isFalse);
  });

  test('missing file: unreadable', () async {
    final result = await readSharedFile(
      p.join(cache.path, 'gone.fit'),
      allowedDirs: [cache],
    );

    expect((result as PickFailed).reason, FileImportFailure.unreadable);
  });
}
