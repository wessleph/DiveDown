// T34.1-T34.3: iOS builds use Xcode 27 / the iOS 27 SDK, which App Store
// Connect requires from April 2027 (ITMS-90725, mail of 2026-11-24).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

YamlMap _job(String workflow, String job) =>
    ((loadYaml(File('.github/workflows/$workflow').readAsStringSync())
                as YamlMap)['jobs']
            as YamlMap)[job]
        as YamlMap;

void main() {
  test('T34.1 the iOS jobs run on the Xcode 27 runner image', () {
    expect(_job('ci.yml', 'ios')['runs-on'], 'xcode-27');
    expect(_job('ios-release.yml', 'testflight')['runs-on'], 'xcode-27');
  });

  test('T34.2 both select Xcode 27 before building', () {
    for (final (workflow, job) in [
      ('ci.yml', 'ios'),
      ('ios-release.yml', 'testflight'),
    ]) {
      final steps = (_job(workflow, job)['steps'] as YamlList).cast<YamlMap>();
      final select = steps.where((s) => s['name'] == 'Select Xcode 27');
      expect(select, hasLength(1), reason: workflow);
      expect(select.single['run'], 'tool/ci/select_xcode.sh', reason: workflow);
    }
  });

  test('T34.3 select_xcode.sh picks Xcode 27 and fails without it', () {
    final script = File('tool/ci/select_xcode.sh').readAsStringSync();
    expect(script, contains('/Applications/Xcode_27'));
    expect(script, isNot(contains('Xcode_26')));
    expect(script, contains('No Xcode 27'));
  });
}
