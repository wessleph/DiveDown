// T14.4: rules for the merged release manifest (security.md §4).
import 'package:flutter_test/flutter_test.dart';

import '../../tool/android_manifest_policy.dart';

String _manifest({String permissions = '', String app = _app}) =>
    '''
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    package="io.github.wessleph.divedown">
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission
        android:name="android.permission.BLUETOOTH_SCAN"
        android:usesPermissionFlags="neverForLocation" />
    <uses-permission
        android:name="android.permission.BLUETOOTH"
        android:maxSdkVersion="30" />
    <uses-permission
        android:name="android.permission.BLUETOOTH_ADMIN"
        android:maxSdkVersion="30" />
    <uses-permission
        android:name="android.permission.ACCESS_FINE_LOCATION"
        android:maxSdkVersion="30" />
$permissions
    $app
</manifest>
''';

const _app =
    '<application android:dataExtractionRules="@xml/data_extraction_rules" '
    'android:fullBackupContent="@xml/backup_rules" />';

void main() {
  test('T14.4 the manifest as intended passes', () {
    expect(checkAndroidManifest(_manifest()), isEmpty);
  });

  test('T14.4 M1 INTERNET is refused', () {
    final problems = checkAndroidManifest(
      _manifest(
        permissions:
            '<uses-permission android:name="android.permission.INTERNET" />',
      ),
    );
    expect(problems.single, startsWith('M1'));
  });

  test('T14.4 M2 location or old Bluetooth without the SDK limit', () {
    final fine = _manifest().replaceFirst(
      '''
        android:name="android.permission.ACCESS_FINE_LOCATION"
        android:maxSdkVersion="30" />''',
      '''
        android:name="android.permission.ACCESS_FINE_LOCATION" />''',
    );
    expect(checkAndroidManifest(fine).single, startsWith('M2'));

    final admin = _manifest().replaceFirst(
      '''
        android:name="android.permission.BLUETOOTH_ADMIN"
        android:maxSdkVersion="30" />''',
      '''
        android:name="android.permission.BLUETOOTH_ADMIN"
        android:maxSdkVersion="31" />''',
    );
    expect(checkAndroidManifest(admin).single, startsWith('M2'));
  });

  test('T14.4 M3 BLUETOOTH_SCAN must say neverForLocation', () {
    final scan = _manifest().replaceFirst(
      '\n        android:usesPermissionFlags="neverForLocation"',
      '',
    );
    expect(checkAndroidManifest(scan).single, startsWith('M3'));
  });

  test('T14.4 M4 permissions DiveDown never needs', () {
    for (final p in [
      'ACCESS_BACKGROUND_LOCATION',
      'CAMERA',
      'READ_CONTACTS',
      'RECORD_AUDIO',
      'READ_EXTERNAL_STORAGE',
    ]) {
      final problems = checkAndroidManifest(
        _manifest(
          permissions:
              '<uses-permission android:name="android.permission.$p" />',
        ),
      );
      expect(problems.single, startsWith('M4'), reason: p);
    }
  });

  test('T14.4 M5 backup rules must be set', () {
    final problems = checkAndroidManifest(_manifest(app: '<application />'));
    expect(problems, hasLength(2));
    expect(problems.every((p) => p.startsWith('M5')), isTrue);
  });
}
