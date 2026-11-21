// T20.13: iOS hands a shared file over as a path in Documents/Inbox
// (SharedFileInbox.swift). Dart reads it through readSharedFile (T5.9):
// into memory, name only shown, copy deleted, nothing outside the Inbox.
import 'dart:io';

import 'package:divedown/data/platform/share_channel.dart';
import 'package:divedown/domain/import/file_import.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(ChannelSharedFiles.channelName);
  late Directory root;
  late Directory inbox;

  setUp(() {
    root = Directory.systemTemp.createTempSync('divedown_inbox_');
    inbox = Directory(p.join(root.path, 'Documents', 'Inbox'))
      ..createSync(recursive: true);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    root.deleteSync(recursive: true);
  });

  Future<PickResult> initial(Map<String, Object?> message) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => call.method == 'initial' ? message : null,
        );
    final shared = ChannelSharedFiles(channel, () async => [inbox]);
    return shared.incoming.first;
  }

  test('T20.13 file in the Inbox: read, name shown, copy deleted', () async {
    final file = File(p.join(inbox.path, 'Tauchgang.fit'))
      ..writeAsBytesSync([1, 2, 3]);

    final result = await initial({'name': 'Tauchgang.fit', 'path': file.path});

    expect(result, isA<Picked>());
    final picked = (result as Picked).file;
    expect(picked.displayName, 'Tauchgang.fit');
    expect(picked.bytes, [1, 2, 3]);
    expect(file.existsSync(), isFalse);
  });

  test('T20.13 path outside the Inbox is refused and left alone', () async {
    final outside = File(p.join(root.path, 'Documents', 'divedown.sqlite'))
      ..writeAsBytesSync([9]);

    final result = await initial({'name': 'x.fit', 'path': outside.path});

    expect(result, isA<PickFailed>());
    expect((result as PickFailed).reason, FileImportFailure.unreadable);
    expect(outside.existsSync(), isTrue);
  });
}
