// T10.8-T10.12: ring buffer, export, plugin events and crashes
// (design.md §9, security.md G5).
import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:divedown/data/diagnostics/file_diagnostic_log.dart';
import 'package:divedown/domain/diagnostics/diagnostic_log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _header = DiagnosticHeader(
  appVersion: '1.0.0',
  build: '42',
  os: 'Android 17 (SDK 37)',
  model: 'samsung SM-S938B',
  libdivecomputer: '0.10.0',
);

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('divedown_log_');
    file = File(p.join(dir.path, 'logs', 'diagnostic.log'));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('entries are stored filtered, one per line, oldest first', () async {
    final log = FileDiagnosticLog(file, release: true);
    await log.log('BLE', LogLevel.info, 'scan started');
    await log.log('health', LogLevel.info, 'pulse 120'); // not allowed
    await log.log('BLE', LogLevel.warn, 'addr AA:BB:CC:DD:EE:FF lost');

    final lines = await log.lines();
    expect(lines, hasLength(2));
    expect(lines.first, endsWith('INFO BLE scan started'));
    expect(lines.last, endsWith('WARN BLE addr ••:EE:FF lost'));
    expect(DateTime.parse(lines.first.split(' ').first).isUtc, isTrue);
  });

  test('T10.8 above the size limit the oldest entries go', () async {
    final log = FileDiagnosticLog(file, release: true, maxBytes: 2000);
    for (var i = 0; i < 100; i++) {
      await log.log('BLE', LogLevel.info, 'line $i ${'x' * 40}');
    }
    expect(file.lengthSync(), lessThanOrEqualTo(2000));
    final lines = await log.lines();
    expect(lines.last, contains('line 99 '));
    expect(lines.any((l) => l.contains('line 0 ')), isFalse);
  });

  test('T10.9 entries older than 7 days are removed on start', () async {
    final log = FileDiagnosticLog(file, release: true);
    await withClock(Clock.fixed(DateTime.utc(2026, 11, 1)), () async {
      await log.log('app', LogLevel.info, 'old');
    });
    await withClock(Clock.fixed(DateTime.utc(2026, 11, 20)), () async {
      await log.log('app', LogLevel.info, 'new');
    });

    await withClock(Clock.fixed(DateTime.utc(2026, 11, 23)), log.prune);

    final lines = await log.lines();
    expect(lines, hasLength(1));
    expect(lines.single, endsWith('INFO app new'));
  });

  test(
    'T10.10 export: header with versions and device, then entries',
    () async {
      final log = FileDiagnosticLog(file, release: true);
      await log.log('import', LogLevel.info, '3 dives saved');

      final text = await log.export(_header);
      final lines = text.split('\n');
      expect(lines.first, 'DiveDown 1.0.0 (Build 42)');
      expect(text, contains('System: Android 17 (SDK 37)'));
      expect(text, contains('Gerät: samsung SM-S938B'));
      expect(text, contains('libdivecomputer: 0.10.0'));
      expect(lines.last, endsWith('INFO import 3 dives saved'));
    },
  );

  test('T10.10 an empty or missing log exports only the header', () async {
    final log = FileDiagnosticLog(file, release: true);
    expect(await log.lines(), isEmpty);
    expect(await log.export(_header), startsWith('DiveDown 1.0.0 (Build 42)'));
  });

  test('T10.11 plugin log events end up in the log, filtered', () async {
    final log = FileDiagnosticLog(file, release: true);
    final events =
        StreamController<({String category, String level, String message})>();
    connectPluginLogs(events.stream, log);

    events
      ..add((category: 'BLE', level: 'INFO', message: 'connected'))
      ..add((
        category: 'BLE',
        level: 'DEBUG',
        message: 'Unmatched device 11:22:33:44:55:66 (Annas AirPods) rssi=-60',
      ))
      ..add((category: 'LDC', level: 'WARN', message: 'timeout'));
    await events.close();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final lines = await log.lines();
    expect(lines, hasLength(2));
    expect(lines.first, endsWith('INFO BLE connected'));
    expect(lines.last, endsWith('WARN LDC timeout'));
  });

  test(
    'T10.12 a crash is written with its stack, without user paths',
    () async {
      final log = FileDiagnosticLog(file, release: true);
      await recordError(
        log,
        StateError('boom'),
        StackTrace.fromString(
          '#0 main (file:///C:/Users/anna/dev/app/lib/main.dart:10:3)',
        ),
      );

      final text = (await log.lines()).join('\n');
      expect(text, contains('ERROR error Bad state: boom'));
      expect(text, contains('#0 main'));
      expect(text, isNot(contains('anna')));
    },
  );
}
