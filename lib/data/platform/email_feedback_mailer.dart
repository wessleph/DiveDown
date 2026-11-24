import 'package:flutter_email_sender/flutter_email_sender.dart';

import '../../domain/feedback/feedback_mail.dart';

/// Opens the phone's mail app with the draft (ui-spec §5.14, T35):
/// Android by intent, iOS with the system mail composer. The user sends it.
class EmailSenderFeedbackMailer implements FeedbackMailer {
  const EmailSenderFeedbackMailer();

  @override
  Future<MailResult> compose(FeedbackMail mail) async {
    try {
      await FlutterEmailSender.send(
        Email(
          subject: mail.subject,
          recipients: [mail.to],
          body: mail.body,
          attachments: [
            if (mail.attachment case final a?)
              EmailAttachment.data(
                a.bytes,
                fileName: a.name,
                mimeType: 'text/plain',
              ),
          ],
        ),
      );
      return MailResult.opened;
    } on FlutterEmailSenderException {
      // No mail app, or none that takes this draft: the screen offers the
      // address instead.
      return MailResult.noMailApp;
    }
  }
}
