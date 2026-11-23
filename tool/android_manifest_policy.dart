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

/// Problems in [manifestXml]; empty when it follows the rules.
List<String> checkAndroidManifest(String manifestXml) =>
    throw UnimplementedError('checkAndroidManifest');
