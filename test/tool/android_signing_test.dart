// T33.1-T33.4: release APKs are signed with the own upload key from
// android/key.properties, never with the debug key (security.md S, A3).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _gradle = File('android/app/build.gradle.kts').readAsStringSync();

/// The `release { … }` block inside `buildTypes`.
String _releaseBuildType() {
  final start = _gradle.indexOf('buildTypes');
  expect(start, isNot(-1));
  final release = _gradle.indexOf('release {', start);
  final end = _gradle.indexOf('}', release);
  return _gradle.substring(release, end);
}

void main() {
  test('T33.1 the release build type does not use the debug key', () {
    final release = _releaseBuildType();
    expect(release, isNot(contains('getByName("debug")')));
    expect(release, contains('signingConfigs.getByName("release")'));
  });

  test('T33.2 the release signing config reads android/key.properties', () {
    expect(_gradle, contains('rootProject.file("key.properties")'));
    for (final key in [
      'storeFile',
      'storePassword',
      'keyAlias',
      'keyPassword',
    ]) {
      expect(_gradle, contains('["$key"]'), reason: key);
    }
  });

  test('T33.3 without key.properties only release packaging fails, with a '
      'pointer to the guide; configuring (CI manifest check) still works', () {
    expect(_gradle, contains('GradleException'));
    expect(_gradle, contains('docs/entwickler/android-release-einrichtung.md'));
    // The check runs when a release package is built, not while Gradle
    // configures the project (ci.yml runs processReleaseMainManifest).
    expect(_gradle, contains('doFirst'));
    expect(
      File('docs/entwickler/android-release-einrichtung.md').existsSync(),
      isTrue,
    );
  });

  test('T33.4 key.properties and keystores stay out of git', () {
    final ignore = File('android/.gitignore').readAsStringSync();
    for (final pattern in ['key.properties', '**/*.jks', '**/*.keystore']) {
      expect(ignore, contains(pattern), reason: pattern);
    }
    final result = Process.runSync('git', [
      'check-ignore',
      '-q',
      'android/key.properties',
    ]);
    expect(result.exitCode, 0, reason: 'android/key.properties is ignored');
  });
}
