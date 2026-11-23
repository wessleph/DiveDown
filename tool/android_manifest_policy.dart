/// Rules for the merged release manifest (security.md §4, T14.4), checked
/// in CI on `processReleaseMainManifest` output by
/// `tool/check_android_manifest.dart`:
///
/// M1 no `INTERNET` permission (v1.0 sends nothing)
/// M2 location (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`) and the
///    old `BLUETOOTH`/`BLUETOOTH_ADMIN` only with `maxSdkVersion` ≤ 30
/// M3 `BLUETOOTH_SCAN` with `usesPermissionFlags="neverForLocation"`
/// M4 never: background location, camera, contacts, microphone, storage
/// M5 the application has `dataExtractionRules` and `fullBackupContent`
library;

import 'package:xml/xml.dart';

const _android = 'http://schemas.android.com/apk/res/android';

const _limitedToSdk30 = {
  'android.permission.ACCESS_FINE_LOCATION',
  'android.permission.ACCESS_COARSE_LOCATION',
  'android.permission.BLUETOOTH',
  'android.permission.BLUETOOTH_ADMIN',
};

const _never = {
  'android.permission.ACCESS_BACKGROUND_LOCATION',
  'android.permission.CAMERA',
  'android.permission.READ_CONTACTS',
  'android.permission.WRITE_CONTACTS',
  'android.permission.RECORD_AUDIO',
  'android.permission.READ_EXTERNAL_STORAGE',
  'android.permission.WRITE_EXTERNAL_STORAGE',
  'android.permission.MANAGE_EXTERNAL_STORAGE',
};

/// Problems in [manifestXml]; empty when it follows the rules.
List<String> checkAndroidManifest(String manifestXml) {
  final doc = XmlDocument.parse(manifestXml);
  final problems = <String>[];
  String? attr(XmlElement e, String name) =>
      e.getAttribute(name, namespaceUri: _android);

  for (final p in doc.findAllElements('uses-permission')) {
    final name = attr(p, 'name') ?? '';
    if (name == 'android.permission.INTERNET') {
      problems.add('M1 $name is not allowed');
    }
    if (_limitedToSdk30.contains(name)) {
      final max = int.tryParse(attr(p, 'maxSdkVersion') ?? '');
      if (max == null || max > 30) {
        problems.add('M2 $name needs maxSdkVersion ≤ 30');
      }
    }
    if (name == 'android.permission.BLUETOOTH_SCAN' &&
        !(attr(p, 'usesPermissionFlags') ?? '').contains('neverForLocation')) {
      problems.add('M3 $name needs usesPermissionFlags="neverForLocation"');
    }
    if (_never.contains(name)) {
      problems.add('M4 $name is never needed');
    }
  }

  final app = doc.findAllElements('application').firstOrNull;
  for (final a in ['dataExtractionRules', 'fullBackupContent']) {
    if (app == null || attr(app, a) == null) {
      problems.add('M5 application needs android:$a');
    }
  }
  return problems;
}
