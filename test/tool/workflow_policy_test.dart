// T19.1-T19.12: CI rules for the public repo (security.md G6/A3, ADR 0005).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../../tool/workflow_policy.dart';

const _sha = 'de0fac2e4500dabe0009e67214ff5f5447ce83dd';

/// A workflow that follows every rule; the cases below break one at a time.
String _good({
  String on = '''
on:
  push:
    tags: ['v*']
  workflow_dispatch:
''',
  String permissions = '''
permissions:
  contents: read
''',
  String jobExtra = '''
    environment: release
    if: github.repository == 'wessleph/DiveDown' && (startsWith(github.ref, 'refs/tags/v') || github.ref == 'refs/heads/main')
    timeout-minutes: 30
''',
  String steps =
      '''
      - uses: actions/checkout@$_sha
        with:
          persist-credentials: false
      - run: echo "\$KEY" > key.p8
        env:
          KEY: \${{ secrets.ASC_KEY_P8_BASE64 }}
''',
}) =>
    '''
name: sample
$on$permissions
jobs:
  build:
    runs-on: macos-15
$jobExtra    steps:
$steps''';

List<String> _rules(String yaml) =>
    checkWorkflow('sample.yml', yaml).map((v) => v.rule).toList();

void main() {
  group('policy check finds each violation', () {
    test('T19.1 a rule-abiding workflow passes', () {
      expect(checkWorkflow('sample.yml', _good()), isEmpty);
    });

    test('T19.2 W1 action not pinned to a commit SHA', () {
      final tag = _good(
        steps: '''
      - uses: actions/checkout@v4
        with:
          persist-credentials: false
''',
      );
      final shortSha = tag.replaceAll('@v4', '@de0fac2');
      final local = _good(
        steps: '''
      - uses: ./.github/actions/setup
''',
      );
      expect(_rules(tag), ['W1']);
      expect(_rules(shortSha), ['W1']);
      expect(_rules(local), isEmpty);
    });

    test('T19.3 W2 pull_request_target and workflow_run', () {
      expect(_rules(_good(on: 'on: pull_request_target\n')), contains('W2'));
      expect(
        _rules(_good(on: 'on:\n  workflow_run:\n    workflows: [ci]\n')),
        contains('W2'),
      );
    });

    test('T19.4 W3 permissions missing or write-all', () {
      expect(_rules(_good(permissions: '')), ['W3']);
      expect(_rules(_good(permissions: 'permissions: write-all\n')), ['W3']);
      final jobWriteAll = _good(
        jobExtra: '''
    environment: release
    if: github.repository == 'wessleph/DiveDown' && startsWith(github.ref, 'refs/tags/v')
    timeout-minutes: 30
    permissions: write-all
''',
      );
      expect(_rules(jobWriteAll), ['W3']);
    });

    test('T19.5 W4 secret outside the release environment', () {
      final noEnv = _good(jobExtra: '    timeout-minutes: 30\n');
      expect(_rules(noEnv), ['W4']);
      final token = _good(
        jobExtra: '    timeout-minutes: 30\n',
        steps: '''
      - run: gh release view
        env:
          GH_TOKEN: \${{ secrets.GITHUB_TOKEN }}
''',
      );
      expect(_rules(token), isEmpty);
    });

    test('T19.6 W4 secret in a workflow that pull requests can trigger', () {
      final pr = _good(on: 'on:\n  pull_request:\n  push:\n');
      expect(_rules(pr), contains('W4'));
    });

    test('T19.7 W5 release job without ref or repository guard', () {
      final noIf = _good(
        jobExtra: '''
    environment: release
    timeout-minutes: 30
''',
      );
      final anyBranch = _good(
        jobExtra: '''
    environment: release
    if: github.repository == 'wessleph/DiveDown'
    timeout-minutes: 30
''',
      );
      final anyRepo = _good(
        jobExtra: '''
    environment: release
    if: startsWith(github.ref, 'refs/tags/v')
    timeout-minutes: 30
''',
      );
      expect(_rules(noIf), ['W5']);
      expect(_rules(anyBranch), ['W5']);
      expect(_rules(anyRepo), ['W5']);
    });

    test('T19.8 W6 checkout keeps the token', () {
      final keeps = _good(
        steps:
            '''
      - uses: actions/checkout@$_sha
''',
      );
      expect(_rules(keeps), ['W6']);
    });

    test('T19.9 W7 event data interpolated into a script', () {
      final injected = _good(
        steps:
            '''
      - uses: actions/checkout@$_sha
        with:
          persist-credentials: false
      - run: echo "\${{ github.event.head_commit.message }}"
      - run: git log \${{ github.head_ref }}
''',
      );
      expect(_rules(injected), ['W7', 'W7']);
      final viaEnv = _good(
        steps:
            '''
      - uses: actions/checkout@$_sha
        with:
          persist-credentials: false
      - run: echo "\$MSG"
        env:
          MSG: \${{ github.event.head_commit.message }}
''',
      );
      expect(_rules(viaEnv), isEmpty);
    });

    test('T19.10 W8 Flutter version written into the workflow', () {
      final clone = _good(
        steps: '''
      - run: git clone --branch 3.47.0 --depth 1 https://github.com/flutter/flutter.git
''',
      );
      final input = _good(
        steps: '''
      - uses: ./.github/actions/setup-flutter
        with:
          flutter-version: '3.47.0'
''',
      );
      expect(_rules(clone), ['W8']);
      expect(_rules(input), ['W8']);
    });

    test('T19.11 W9 job without timeout', () {
      final noTimeout = _good(
        jobExtra: '''
    environment: release
    if: github.repository == 'wessleph/DiveDown' && startsWith(github.ref, 'refs/tags/v')
''',
      );
      expect(_rules(noTimeout), ['W9']);
    });
  });

  group('T19.12 workflows in this repo', () {
    final dir = Directory('.github/workflows');
    File wf(String name) => File(p.join(dir.path, name));
    YamlMap load(String name) =>
        loadYaml(wf(name).readAsStringSync()) as YamlMap;

    test('Flutter version file says 3.47.0 (ADR 0005)', () {
      final file = File('.github/flutter-version.txt');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync().trim(), '3.47.0');
    });

    test('ci.yml and ios-release.yml exist', () {
      expect(wf('ci.yml').existsSync(), isTrue);
      expect(wf('ios-release.yml').existsSync(), isTrue);
    });

    test('every workflow follows W1-W9', () {
      final files = dir.existsSync()
          ? dir
                .listSync()
                .whereType<File>()
                .where(
                  (f) => f.path.endsWith('.yml') || f.path.endsWith('.yaml'),
                )
                .toList()
          : <File>[];
      expect(files, isNotEmpty);
      for (final f in files) {
        expect(
          checkWorkflow(p.basename(f.path), f.readAsStringSync()),
          isEmpty,
          reason: f.path,
        );
      }
    });

    test('ci.yml runs on push and pull request and uses no secrets', () {
      final on = load('ci.yml')['on'] as YamlMap;
      expect(on.keys, containsAll(['push', 'pull_request']));
      expect(wf('ci.yml').readAsStringSync(), isNot(contains('secrets.')));
    });

    test('ci.yml builds iOS only on main or by hand (ADR 0005)', () {
      final jobs = load('ci.yml')['jobs'] as YamlMap;
      final ios = jobs['ios'] as YamlMap;
      expect(ios['runs-on'].toString(), startsWith('macos-'));
      expect(ios['if'].toString(), contains("refs/heads/main"));
      expect(ios['if'].toString(), contains('workflow_dispatch'));
    });

    test('ios-release.yml: tags, by hand and monthly, never pull requests', () {
      final on = load('ios-release.yml')['on'] as YamlMap;
      expect(on.keys, containsAll(['push', 'workflow_dispatch', 'schedule']));
      expect(on.keys, isNot(contains('pull_request')));
      expect(((on['push'] as YamlMap)['tags'] as YamlList), ['v*']);
    });

    test('ios-release.yml signs only in the release environment', () {
      final jobs = load('ios-release.yml')['jobs'] as YamlMap;
      final withSecrets = jobs.entries.where(
        (e) => (e.value as YamlMap).toString().contains('secrets.'),
      );
      expect(withSecrets, isNotEmpty);
      for (final job in withSecrets) {
        expect(
          (job.value as YamlMap)['environment'],
          'release',
          reason: job.key.toString(),
        );
      }
    });
  });
}
