// Feedback by mail (ui-spec §5.14, T35). The app has no internet permission:
// it only prepares a draft that the phone's mail app opens. Pure Dart.
import 'dart:typed_data';

import '../diagnostics/diagnostic_log.dart';

/// Address in the privacy policy (docs/datenschutz.md, section 2).
const feedbackAddress = 'divedown-app@proton.ch';

enum FeedbackKind { bug, idea }

class FeedbackMail {
  const FeedbackMail({
    required this.subject,
    required this.body,
    this.attachment,
  });

  String get to => feedbackAddress;
  final String subject;
  final String body;

  /// The diagnostic log for bug reports, if the user kept it on.
  final ({String name, Uint8List bytes})? attachment;
}

/// Subject „DiveDown: Fehler“ / „DiveDown: Verbesserungsvorschlag“; body is
/// [text], a separator line and the device data of [header].
FeedbackMail buildFeedbackMail(
  FeedbackKind kind,
  String text,
  DiagnosticHeader header, {
  ({String name, Uint8List bytes})? attachment,
}) => FeedbackMail(
  subject: switch (kind) {
    FeedbackKind.bug => 'DiveDown: Fehler',
    FeedbackKind.idea => 'DiveDown: Verbesserungsvorschlag',
  },
  body:
      '${text.trim()}\n'
      '\n'
      '--\n'
      'DiveDown ${header.appVersion} (Build ${header.build})\n'
      '${header.os} · ${header.model}\n'
      'libdivecomputer ${header.libdivecomputer}\n',
  attachment: attachment,
);

enum MailResult { opened, noMailApp }

/// Opens the mail app with a draft; sends nothing by itself.
abstract interface class FeedbackMailer {
  Future<MailResult> compose(FeedbackMail mail);
}
