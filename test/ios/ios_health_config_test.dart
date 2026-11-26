// T6.13: HealthKit configuration of the iOS app, read only (security.md G3,
// §4). Checked on the PC, because there is no Mac (ADR 0005).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

Map<String, XmlElement> _plist(String path) {
  final doc = XmlDocument.parse(File(path).readAsStringSync());
  final dict = doc.findAllElements('dict').first;
  final out = <String, XmlElement>{};
  final children = dict.childElements.toList();
  for (var i = 0; i + 1 < children.length; i += 2) {
    out[children[i].innerText] = children[i + 1];
  }
  return out;
}

void main() {
  const entitlements = 'ios/Runner/Runner.entitlements';
  final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

  test('T6.13 Info.plist explains reading, in German', () {
    final info = _plist('ios/Runner/Info.plist');
    final text = info['NSHealthShareUsageDescription']?.innerText ?? '';
    expect(text, contains('Apple Health'));
    expect(text, contains('Tiefe, Wassertemperatur und Puls'));
    expect(text, contains('schreibt nichts'));
    expect(info.containsKey('NSHealthUpdateUsageDescription'), isFalse);
  });

  test('T6.13 entitlements: HealthKit only, no clinical records, no '
      'background delivery', () {
    expect(File(entitlements).existsSync(), isTrue, reason: entitlements);
    final keys = _plist(entitlements);
    expect(keys.keys.toSet(), {'com.apple.developer.healthkit'});
    expect(keys['com.apple.developer.healthkit']!.name.local, 'true');
  });

  test('T6.13 the Runner target signs with the entitlements', () {
    // Debug, Release and Profile of the app target.
    final configs = RegExp(
      r'buildSettings = \{[^}]*PRODUCT_BUNDLE_IDENTIFIER = '
      r'io\.github\.wessleph\.divedown;[^}]*\}',
    ).allMatches(pbx).map((m) => m.group(0)!).toList();
    expect(configs, hasLength(3));
    for (final c in configs) {
      expect(
        c,
        contains('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'),
      );
    }
    // Test targets get none.
    expect(RegExp('CODE_SIGN_ENTITLEMENTS').allMatches(pbx).length, 3);
  });

  test('T6.13 HealthDiveChannel.swift is compiled into Runner', () {
    expect(File('ios/Runner/HealthDiveChannel.swift').existsSync(), isTrue);
    expect(pbx, contains('HealthDiveChannel.swift in Sources'));
    final swift = File('ios/Runner/HealthDiveChannel.swift').readAsStringSync();
    // Read only: never ask to share (write) anything.
    expect(swift, contains('toShare: nil'));
    expect(swift, contains('HKWorkoutActivityType.underwaterDiving'));
    // The diving workout type exists from iOS 17 (CI run 45898807045).
    expect(swift, isNot(contains('available(iOS 16')));
    expect(swift, contains('#available(iOS 17.0, *)'));
  });
}
