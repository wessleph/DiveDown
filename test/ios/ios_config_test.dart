// T20.1-T20.8: iOS configuration checked on the PC, because there is no Mac
// (security.md §4, A2, A3; ADR 0005). The Swift side runs in CI (T20.9-T20.12).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

/// Info.plist as key → value, values as XmlElement (`string`, `true`, …).
Map<String, XmlElement> _plist(String path) {
  final doc = XmlDocument.parse(File(path).readAsStringSync());
  return _dict(doc.findAllElements('dict').first);
}

Map<String, XmlElement> _dict(XmlElement dict) {
  final out = <String, XmlElement>{};
  final children = dict.childElements.toList();
  for (var i = 0; i + 1 < children.length; i += 2) {
    out[children[i].innerText] = children[i + 1];
  }
  return out;
}

List<String> _strings(XmlElement? array) =>
    array == null ? [] : array.childElements.map((e) => e.innerText).toList();

void main() {
  const infoPlist = 'ios/Runner/Info.plist';
  const podfile = 'ios/Podfile';
  late Map<String, XmlElement> info;

  setUpAll(() => info = _plist(infoPlist));

  test('T20.1 I1 Bluetooth text present, German, no "Submersion"', () {
    final text = info['NSBluetoothAlwaysUsageDescription']?.innerText ?? '';
    expect(text, contains('Tauchcomputer'));
    expect(File(infoPlist).readAsStringSync(), isNot(contains('Submersion')));
  });

  // Health write: Apple requires the purpose string whenever the HealthKit
  // entitlement is present (ITMS-90683, 2026-11-27); write access is never
  // requested, which T6.13 checks (`toShare: nil`).
  test('T20.2 I2 no location, camera, contacts, microphone', () {
    final forbidden = info.keys.where(
      (k) =>
          k.startsWith('NSLocation') ||
          k == 'NSCameraUsageDescription' ||
          k == 'NSContactsUsageDescription' ||
          k == 'NSMicrophoneUsageDescription',
    );
    expect(forbidden, isEmpty);
  });

  // T43.12: the share photo comes from the PHPicker, which needs no access
  // to the photo library (security.md G7).
  test('T43.12 no photo library access', () {
    expect(info.keys.where((k) => k.startsWith('NSPhotoLibrary')), isEmpty);
  });

  test('T20.3 I3 FIT is an imported type with extension .fit', () {
    final imported = info['UTImportedTypeDeclarations'];
    expect(imported, isNotNull, reason: 'UTImportedTypeDeclarations missing');
    final fit = imported!.childElements.map(_dict).where((t) {
      final tags = t['UTTypeTagSpecification'];
      final ext = tags == null
          ? null
          : _dict(tags)['public.filename-extension'];
      final exts = ext == null
          ? <String>[]
          : ext.name.local == 'array'
          ? _strings(ext)
          : [ext.innerText];
      return exts.map((e) => e.toLowerCase()).contains('fit');
    }).toList();
    expect(fit, hasLength(1));
    expect(_strings(fit.single['UTTypeConformsTo']), contains('public.data'));
  });

  test('T20.4 I3 DiveDown opens FIT files as an alternate handler', () {
    final imported = info['UTImportedTypeDeclarations'];
    final fitUti = imported?.childElements
        .map(_dict)
        .map((t) => t['UTTypeIdentifier']?.innerText)
        .firstOrNull;
    final types = info['CFBundleDocumentTypes'];
    expect(types, isNotNull, reason: 'CFBundleDocumentTypes missing');
    final entries = types!.childElements
        .map(_dict)
        .where((d) => _strings(d['LSItemContentTypes']).contains(fitUti));
    expect(entries, hasLength(1));
    expect(entries.single['LSHandlerRank']?.innerText, 'Alternate');
    expect(entries.single['CFBundleTypeRole']?.innerText, 'Viewer');
  });

  test('T20.5 I3 shared files are copied to Inbox, not opened in place', () {
    expect(info['LSSupportsOpeningDocumentsInPlace']?.name.local, 'false');
    expect(info['UIFileSharingEnabled']?.name.local ?? 'false', 'false');
  });

  test('T20.6 I4 export compliance: no non-exempt encryption', () {
    expect(info['ITSAppUsesNonExemptEncryption']?.name.local, 'false');
  });

  group('T20.7 I5 Podfile', () {
    test('exists, iOS 15, only PERMISSION_BLUETOOTH=1', () {
      final file = File(podfile);
      expect(file.existsSync(), isTrue, reason: 'ios/Podfile missing');
      final text = file.readAsStringSync();
      expect(text, contains("platform :ios, '15.0'"));
      final enabled = RegExp(r'PERMISSION_[A-Z_]+=1')
          .allMatches(text)
          .map((m) => m.group(0))
          .toSet();
      expect(enabled, {'PERMISSION_BLUETOOTH=1'});
    });

    test('Podfile.lock is checked in (security.md G6)', () {
      expect(File('ios/Podfile.lock').existsSync(), isTrue);
    });
  });

  test('T20.8 I6 iOS 15.0 everywhere', () {
    final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final targets = RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);')
        .allMatches(pbx)
        .map((m) => m.group(1))
        .toSet();
    expect(targets, {'15.0'});
    final podspec = File(
      'packages/libdivecomputer_plugin/ios/libdivecomputer_plugin.podspec',
    ).readAsStringSync();
    expect(podspec, contains("s.platform         = :ios, '15.0'"));
    final pod = File(podfile);
    expect(pod.existsSync(), isTrue, reason: 'ios/Podfile missing');
    expect(pod.readAsStringSync(), contains("platform :ios, '15.0'"));
  });
}
