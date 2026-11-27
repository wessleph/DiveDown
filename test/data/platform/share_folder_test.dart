// T11.16: a shared backup stays until the next share or app start (found
// on the phone: Drive or Gmail read the file after the dialog closed).
import 'dart:io';
import 'dart:typed_data';

import 'package:divedown/data/platform/share_folder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory cache;

  setUp(() => cache = Directory.systemTemp.createTempSync('divedown_cache_'));
  tearDown(() => cache.deleteSync(recursive: true));

  test('T11.16 the file stays, the next share removes the old one', () async {
    final first = await prepareShareFile(
      cache,
      'DiveDown-Sicherung-2026-11-22.divedown',
      Uint8List.fromList([1, 2, 3]),
    );
    expect(first.path, p.join(cache.path, 'share', p.basename(first.path)));
    expect(first.readAsBytesSync(), [1, 2, 3]);

    final second = await prepareShareFile(
      cache,
      'DiveDown-Sicherung-2026-11-23.divedown',
      Uint8List.fromList([4]),
    );
    expect(first.existsSync(), isFalse);
    expect(second.existsSync(), isTrue);
  });

  test('T11.16 the name is only a name, never a path', () async {
    final file = await prepareShareFile(
      cache,
      '../../evil.divedown',
      Uint8List.fromList([1]),
    );
    expect(p.dirname(file.path), p.join(cache.path, 'share'));
    expect(
      File(p.join(cache.path, '..', 'evil.divedown')).existsSync(),
      isFalse,
    );
  });

  test('T11.16 app start clears the folder, also when it is missing', () async {
    await clearShareFolder(cache); // nothing there yet
    final file = await prepareShareFile(cache, 'x.divedown', Uint8List(1));
    await clearShareFolder(cache);
    expect(file.existsSync(), isFalse);
  });

  test('T10.15 the media type follows the file', () {
    expect(shareMimeType('DiveDown-Diagnose-2026-11-23.txt'), 'text/plain');
    expect(
      shareMimeType('DiveDown-Sicherung-2026-11-23.divedown'),
      'application/zip',
    );
    expect(shareMimeType('x.bin'), 'application/octet-stream');
  });

  test('T43.7 a share image is a PNG, so Instagram offers itself', () {
    expect(shareMimeType('DiveDown-2026-11-14-42.png'), 'image/png');
  });
}
