// T4.5 support: the embedded fixtures match test/fixtures/ (see tool/).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/embed_fixtures.dart' as embed;

void main() {
  test('integration_test/eon_core_fixtures.g.dart is up to date', () {
    final file = File(embed.outputPath);
    expect(file.existsSync(), isTrue, reason: 'run tool/embed_fixtures.dart');
    expect(
      file.readAsStringSync(),
      embed.generate(),
      reason: 'fixtures changed: run `dart run tool/embed_fixtures.dart`',
    );
  });
}
