// T10.1-T10.7: what may be written into the diagnostic log
// (security.md A4, §3).
import 'package:divedown/data/diagnostics/log_sanitizer.dart';
import 'package:divedown/domain/diagnostics/diagnostic_log.dart';
import 'package:flutter_test/flutter_test.dart';

LogEntry _e(String message, {String category = 'BLE'}) => LogEntry(
  time: DateTime.utc(2026, 11, 23, 10),
  category: category,
  level: LogLevel.info,
  message: message,
);

String? _clean(
  String message, {
  String category = 'BLE',
  bool release = true,
}) => sanitizeLogEntry(
  _e(message, category: category),
  release: release,
)?.message;

void main() {
  test('T10.1 MAC addresses keep only the last two bytes', () {
    expect(
      _clean('Connecting to AA:BB:CC:DD:EE:FF (gatt)'),
      'Connecting to ••:EE:FF (gatt)',
    );
    expect(_clean('addr=d4:22:cd:00:3f:7a'), 'addr=••:3f:7a');
  });

  test('T10.2 serial numbers keep only the last four characters', () {
    expect(
      _clean('devinfo serial=12345678 fw=1.2'),
      'devinfo serial=••5678 fw=1.2',
    );
    expect(_clean('serial=0x2219801234'), 'serial=••1234');
    expect(_clean('serial=123'), 'serial=••');
  });

  test('T10.3 HEXDUMP lines of libdivecomputer: dropped in release', () {
    const line = 'INFO: Read: size=20, data=0102030405060708090A';
    expect(
      sanitizeLogEntry(_e('[HEXDUMP] $line', category: 'LDC'), release: true),
      isNull,
    );
    expect(
      sanitizeLogEntry(
        _e('HEXDUMP: Write: size=4, data=DEADBEEF', category: 'LDC'),
        release: true,
      ),
      isNull,
    );
    // Debug builds keep them for the developer.
    expect(
      sanitizeLogEntry(_e('[HEXDUMP] $line', category: 'LDC'), release: false),
      isNotNull,
    );
  });

  test('T10.4 BLE devices that are not dive computers: dropped in release', () {
    const line = 'Unmatched device 11:22:33:44:55:66 (Annas AirPods) rssi=-60';
    expect(sanitizeLogEntry(_e(line), release: true), isNull);
    expect(sanitizeLogEntry(_e(line), release: false), isNotNull);
  });

  test('T10.5 decimal coordinates are removed', () {
    expect(
      _clean('site at 27.8123, 33.9201 saved', category: 'import'),
      'site at [Ort entfernt] saved',
    );
    expect(
      _clean('lat=-8.27512 lon=115.59341', category: 'import'),
      'lat=[Ort entfernt] lon=[Ort entfernt]',
    );
    // Depths, durations and versions stay.
    expect(
      _clean('dive 18.4 m 47 min fw 1.2.3', category: 'import'),
      'dive 18.4 m 47 min fw 1.2.3',
    );
  });

  test('T10.6 e-mail addresses and paths with a user name are removed', () {
    expect(
      _clean('sent to anna.muster@example.org', category: 'error'),
      'sent to [entfernt]',
    );
    expect(
      _clean(r'at C:\Users\anna\Documents\x.fit line 3', category: 'error'),
      'at [entfernt] line 3',
    );
    expect(
      _clean('at /Users/anna/Library/x.dart:12', category: 'error'),
      'at [entfernt]',
    );
    expect(
      _clean('at /home/anna/app/x.dart:12', category: 'error'),
      'at [entfernt]',
    );
  });

  test('T10.7 categories not on the positive list are dropped', () {
    expect(
      sanitizeLogEntry(_e('hello', category: 'health'), release: true),
      isNull,
    );
    expect(
      sanitizeLogEntry(_e('hello', category: 'notes'), release: false),
      isNull,
    );
    for (final c in allowedLogCategories) {
      expect(
        sanitizeLogEntry(_e('ok', category: c), release: true),
        isNotNull,
        reason: c,
      );
    }
  });
}
