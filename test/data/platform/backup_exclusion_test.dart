// T11.9: database folder excluded from iCloud backup (security.md O1 a)).
// The Swift side in AppDelegate.swift can only run on iOS (CI/TestFlight);
// this test covers the call from Dart.
import 'package:divedown/data/platform/backup_exclusion.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(BackupExclusion.channelName);
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('T11.9 iOS: asks the platform to exclude the folder', () async {
    await BackupExclusion(platform: TargetPlatform.iOS)
        .excludeDirectory('/var/mobile/App/Library/Application Support/db');

    expect(calls, hasLength(1));
    expect(calls.single.method, BackupExclusion.excludeMethod);
    expect(calls.single.arguments, {
      'path': '/var/mobile/App/Library/Application Support/db',
    });
  });

  test('T11.9 iOS: a platform error is not swallowed', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'exclude_failed');
        });

    await expectLater(
      BackupExclusion(platform: TargetPlatform.iOS).excludeDirectory('/x/db'),
      throwsA(isA<PlatformException>()),
    );
  });

  test('T11.10 Android: no channel call, the manifest rules do it', () async {
    await BackupExclusion(platform: TargetPlatform.android)
        .excludeDirectory('/data/user/0/io.github.wessleph.divedown/files/db');

    expect(calls, isEmpty);
  });
}
