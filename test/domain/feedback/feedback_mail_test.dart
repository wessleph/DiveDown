// T35.1: the feedback mail draft (ui-spec §5.14).
import 'dart:convert';

import 'package:divedown/domain/diagnostics/diagnostic_log.dart';
import 'package:divedown/domain/feedback/feedback_mail.dart';
import 'package:flutter_test/flutter_test.dart';

const _header = DiagnosticHeader(
  appVersion: '1.0.0',
  build: '85',
  os: 'iOS 27.1',
  model: 'iPhone17,1',
  libdivecomputer: '0.10.0',
);

void main() {
  test('T35.1 bug report: subject, text, separator, device data', () {
    final mail = buildFeedbackMail(
      FeedbackKind.bug,
      'Übertragung bricht nach drei Tauchgängen ab.',
      _header,
    );
    expect(mail.to, 'divedown-app@proton.me');
    expect(mail.subject, 'DiveDown: Fehler');
    expect(
      mail.body,
      'Übertragung bricht nach drei Tauchgängen ab.\n'
      '\n'
      '--\n'
      'DiveDown 1.0.0 (Build 85)\n'
      'iOS 27.1 · iPhone17,1\n'
      'libdivecomputer 0.10.0\n',
    );
    expect(mail.attachment, isNull);
  });

  test('T35.1 idea: own subject, text trimmed, no attachment', () {
    final mail = buildFeedbackMail(
      FeedbackKind.idea,
      '  Sichtweite pro Tauchgang eintragen  \n',
      _header,
    );
    expect(mail.subject, 'DiveDown: Verbesserungsvorschlag');
    expect(mail.body, startsWith('Sichtweite pro Tauchgang eintragen\n\n--\n'));
  });

  test('T35.1 the attachment is passed through', () {
    final log = (
      name: 'DiveDown-Diagnose-2026-11-24.txt',
      bytes: utf8.encode('INFO ble connected'),
    );
    final mail = buildFeedbackMail(
      FeedbackKind.bug,
      'Absturz',
      _header,
      attachment: log,
    );
    expect(mail.attachment?.name, 'DiveDown-Diagnose-2026-11-24.txt');
    expect(utf8.decode(mail.attachment!.bytes), 'INFO ble connected');
  });
}
