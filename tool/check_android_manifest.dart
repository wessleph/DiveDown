// Checks the merged release manifest against security.md §4 (T14.4).
//
//   cd android && ./gradlew :app:processReleaseMainManifest
//   dart run tool/check_android_manifest.dart
//
// Without an argument it looks for the manifest under build/app/.
import 'dart:io';

import 'android_manifest_policy.dart';

void main(List<String> args) {
  final path = args.isNotEmpty ? args.first : _find();
  if (path == null) {
    stderr.writeln(
      'No merged release manifest found. Run '
      '`./gradlew :app:processReleaseMainManifest` in android/ first.',
    );
    exit(2);
  }
  final problems = checkAndroidManifest(File(path).readAsStringSync());
  if (problems.isEmpty) {
    stdout.writeln('OK $path');
    return;
  }
  stderr.writeln('Manifest $path breaks security.md §4:');
  problems.forEach(stderr.writeln);
  exit(1);
}

String? _find() {
  final root = Directory('build/app/intermediates/merged_manifest/release');
  if (!root.existsSync()) return null;
  for (final f in root.listSync(recursive: true)) {
    if (f is File && f.path.endsWith('AndroidManifest.xml')) return f.path;
  }
  return null;
}
