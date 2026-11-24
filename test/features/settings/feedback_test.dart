// T35.2-T35.5: „Fehler melden“ and „Verbesserung vorschlagen“ (ui-spec §5.14).
import 'dart:convert';

import 'package:divedown/app/providers.dart';
import 'package:divedown/domain/feedback/feedback_mail.dart';
import 'package:divedown/features/settings/diagnostics_screen.dart';
import 'package:divedown/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

class _FakeMailer implements FeedbackMailer {
  final mails = <FeedbackMail>[];
  MailResult result = MailResult.opened;

  @override
  Future<MailResult> compose(FeedbackMail mail) async {
    mails.add(mail);
    return result;
  }
}

Finder _field(String label) => find.byWidgetPredicate(
  (w) =>
      w is TextField && (w.decoration?.labelText?.startsWith(label) ?? false),
  description: 'TextField „$label“',
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<_FakeMailer> _open(
  WidgetTester tester, {
  List<String> log = const ['INFO ble connected'],
}) async {
  final db = newTestDatabase();
  addTearDown(db.close);
  await seedActiveDiver(db);
  final mailer = _FakeMailer();
  await pumpTestApp(
    tester,
    db: db,
    size: const Size(400, 2200),
    location: SettingsScreen.path,
    diagnosticLog: MemoryDiagnosticLog([...log]),
    overrides: [
      appInfoProvider.overrideWith(
        (ref) async => const AppInfo(
          version: '1.0.0',
          build: '1',
          libdivecomputer: '0.10.0',
        ),
      ),
      feedbackMailerProvider.overrideWithValue(mailer),
    ],
  );
  return mailer;
}

void main() {
  testWidgets('T35.2 HILFE: Fehler melden, Verbesserung vorschlagen, '
      'then Diagnose-Logs teilen', (tester) async {
    await _open(tester);

    final y = {
      for (final t in [
        'HILFE',
        'Fehler melden',
        'Verbesserung vorschlagen',
        'Diagnose-Logs teilen',
      ])
        t: tester.getTopLeft(find.text(t)).dy,
    };
    final order = y.keys.toList()..sort((a, b) => y[a]!.compareTo(y[b]!));
    expect(order, y.keys.toList());
  });

  group('T35.3 Fehler melden', () {
    testWidgets('text required; then a draft with device data and the log', (
      tester,
    ) async {
      final mailer = await _open(tester);
      await _tap(tester, find.text('Fehler melden'));
      expect(find.text('Fehler melden'), findsWidgets); // title

      await _tap(tester, find.text('Mail vorbereiten'));
      expect(
        find.text('Bitte beschreibe kurz, was passiert ist.'),
        findsOneWidget,
      );
      expect(mailer.mails, isEmpty);

      expect(find.text('Diagnose-Protokoll anhängen'), findsOneWidget);
      expect(
        find.text('Enthält keine Orte, Namen oder Gesundheitswerte.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Deine Mail-App öffnet sich mit der Nachricht an '
          'divedown-app@proton.ch. Gesendet wird erst, wenn du dort auf '
          'Senden tippst.',
        ),
        findsOneWidget,
      );

      await tester.enterText(_field('Was ist passiert?'), 'App stürzt ab.');
      await _tap(tester, find.text('Mail vorbereiten'));

      final mail = mailer.mails.single;
      expect(mail.to, 'divedown-app@proton.ch');
      expect(mail.subject, 'DiveDown: Fehler');
      expect(mail.body, startsWith('App stürzt ab.\n\n--\n'));
      expect(mail.body, contains('DiveDown 1.0.0 (Build 1)'));
      expect(mail.body, contains('Android 17 (SDK 37) · samsung SM-S938B'));
      expect(
        mail.attachment?.name,
        matches(RegExp(r'^DiveDown-Diagnose-\d{4}-\d{2}-\d{2}\.txt$')),
      );
      final log = utf8.decode(mail.attachment!.bytes);
      expect(log, startsWith('DiveDown 1.0.0 (Build 1)'));
      expect(log, contains('INFO ble connected'));

      // Back from the mail app: the page stays with the text.
      expect(find.text('App stürzt ab.'), findsOneWidget);
    });

    testWidgets('switch off: no attachment', (tester) async {
      final mailer = await _open(tester);
      await _tap(tester, find.text('Fehler melden'));
      await _tap(tester, find.text('Diagnose-Protokoll anhängen'));
      await tester.enterText(_field('Was ist passiert?'), 'Falsche Tiefe.');
      await _tap(tester, find.text('Mail vorbereiten'));

      expect(mailer.mails.single.attachment, isNull);
    });

    testWidgets('empty log: no switch, no attachment', (tester) async {
      final mailer = await _open(tester, log: const []);
      await _tap(tester, find.text('Fehler melden'));
      expect(find.text('Diagnose-Protokoll anhängen'), findsNothing);
      await tester.enterText(_field('Was ist passiert?'), 'Falsche Tiefe.');
      await _tap(tester, find.text('Mail vorbereiten'));

      expect(mailer.mails.single.attachment, isNull);
    });

    testWidgets('„Protokoll ansehen“ opens the log preview', (tester) async {
      await _open(tester);
      await _tap(tester, find.text('Fehler melden'));
      await _tap(tester, find.text('Protokoll ansehen'));

      expect(find.byType(DiagnosticsScreen), findsOneWidget);
    });
  });

  testWidgets('T35.4 Verbesserung vorschlagen: text required, no attachment', (
    tester,
  ) async {
    final mailer = await _open(tester);
    await _tap(tester, find.text('Verbesserung vorschlagen'));

    await _tap(tester, find.text('Mail vorbereiten'));
    expect(find.text('Bitte beschreibe deine Idee kurz.'), findsOneWidget);
    expect(mailer.mails, isEmpty);
    expect(find.text('Diagnose-Protokoll anhängen'), findsNothing);

    await tester.enterText(_field('Deine Idee'), 'Sichtweite eintragen.');
    await _tap(tester, find.text('Mail vorbereiten'));

    final mail = mailer.mails.single;
    expect(mail.subject, 'DiveDown: Verbesserungsvorschlag');
    expect(mail.body, startsWith('Sichtweite eintragen.\n\n--\n'));
    expect(mail.attachment, isNull);
  });

  testWidgets('T35.5 no mail app: dialog, address copied', (tester) async {
    (await _open(tester)).result = MailResult.noMailApp;
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await _tap(tester, find.text('Verbesserung vorschlagen'));
    await tester.enterText(_field('Deine Idee'), 'Sichtweite eintragen.');
    await _tap(tester, find.text('Mail vorbereiten'));

    expect(find.text('Keine Mail-App gefunden'), findsOneWidget);
    expect(find.text('Schreib an divedown-app@proton.ch.'), findsOneWidget);
    await _tap(tester, find.text('Adresse kopieren'));

    expect(copied, 'divedown-app@proton.ch');
    expect(find.text('Adresse kopiert'), findsOneWidget);
  });
}
