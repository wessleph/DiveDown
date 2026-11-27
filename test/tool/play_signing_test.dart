// T42.1-T42.3: app bundles for the internal test of Google Play are signed
// with an own upload key from android/upload-key.properties; APKs keep the
// app signing key from android/key.properties (ADR 0005, addendum
// 2026-11-27; security.md G6).
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
  test('T42.1 app bundles use the upload key, APKs the release key', () {
    expect(_gradle, contains('rootProject.file("upload-key.properties")'));
    expect(_gradle, contains('create("upload")'));
    for (final key in [
      'storeFile',
      'storePassword',
      'keyAlias',
      'keyPassword',
    ]) {
      expect(_gradle, contains('uploadKeyProperties["$key"]'), reason: key);
    }
    // Flutter runs bundleRelease for `flutter build appbundle`.
    expect(_gradle, contains('gradle.startParameter.taskNames'));
    expect(_gradle, contains('"bundle"'));
    final release = _releaseBuildType();
    expect(release, contains('buildsBundle'));
    expect(release, contains('signingConfigs.getByName("upload")'));
    expect(release, contains('signingConfigs.getByName("release")'));
  });

  test('T42.2 without upload-key.properties only bundles fail, with a pointer '
      'to the guide', () {
    expect(_gradle, contains('uploadKeyPropertiesFile.exists()'));
    expect(_gradle, contains('upload-key.properties fehlt'));
    expect(_gradle, contains('docs/entwickler/play-interner-test.md'));
    expect(File('docs/entwickler/play-interner-test.md').existsSync(), isTrue);
  });

  test('T42.3 upload-key.properties and .p12 keystores stay out of git', () {
    final ignore = File('android/.gitignore').readAsStringSync();
    for (final pattern in ['upload-key.properties', '**/*.p12']) {
      expect(ignore, contains(pattern), reason: pattern);
    }
    for (final path in [
      'android/upload-key.properties',
      'android/app/divedown-play-upload.p12',
    ]) {
      final result = Process.runSync('git', ['check-ignore', '-q', path]);
      expect(result.exitCode, 0, reason: '$path is ignored');
    }
  });
}
