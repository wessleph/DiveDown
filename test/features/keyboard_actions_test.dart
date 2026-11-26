// T36: the main action of a form stays reachable while the on-screen
// keyboard is open, and dragging the page closes the keyboard (iPhone test,
// 2026-11-26: on iOS a multi-line field has no key to close the keyboard,
// so „Mail vorbereiten“ was hidden behind it).
import 'package:divedown/app/providers.dart';
import 'package:divedown/domain/feedback/feedback_mail.dart';
import 'package:divedown/features/logbook/manual_dive_screen.dart';
import 'package:divedown/features/settings/equipment_edit_screen.dart';
import 'package:divedown/features/settings/feedback_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

/// Logical size of an iPhone 15 and the height of its German keyboard with
/// the suggestion bar.
const _phone = Size(390, 844);
const _keyboard = 336.0;

class _FakeMailer implements FeedbackMailer {
  final mails = <FeedbackMail>[];

  @override
  Future<MailResult> compose(FeedbackMail mail) async {
    mails.add(mail);
    return MailResult.opened;
  }
}

Finder _field(String label) => find.byWidgetPredicate(
  (w) =>
      w is TextField && (w.decoration?.labelText?.startsWith(label) ?? false),
  description: 'TextField „$label“',
);

Finder _button(String text) => find
    .ancestor(
      of: find.text(text),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    )
    .first;

bool _hasFocus(WidgetTester tester, Finder field) => tester
    .widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    )
    .focusNode
    .hasFocus;

Future<_FakeMailer> _open(WidgetTester tester, String location) async {
  final db = newTestDatabase();
  addTearDown(db.close);
  await seedActiveDiver(db);
  final mailer = _FakeMailer();
  await pumpTestApp(
    tester,
    db: db,
    size: _phone,
    location: location,
    overrides: [feedbackMailerProvider.overrideWithValue(mailer)],
  );
  return mailer;
}

/// Types into [field] and opens the keyboard over the bottom of the screen.
Future<void> _typeWithKeyboard(
  WidgetTester tester,
  Finder field,
  String text,
) async {
  await tester.enterText(field, text);
  tester.view.viewInsets = const FakeViewPadding(bottom: _keyboard);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpAndSettle();
}

void _expectAboveKeyboard(WidgetTester tester, String text) {
  final rect = tester.getRect(_button(text));
  expect(
    rect.bottom,
    lessThanOrEqualTo(_phone.height - _keyboard),
    reason: '„$text“ must not lie under the keyboard',
  );
  expect(rect.height, greaterThanOrEqualTo(56));
}

void main() {
  final iOS = TargetPlatformVariant.only(TargetPlatform.iOS);

  testWidgets('T36.1 Fehler melden: „Mail vorbereiten“ above the keyboard', (
    tester,
  ) async {
    final mailer = await _open(tester, FeedbackScreen.bugPath);
    final field = _field('Was ist passiert?');
    await _typeWithKeyboard(tester, field, 'App stürzt ab.');

    _expectAboveKeyboard(tester, 'Mail vorbereiten');
    await tester.tap(_button('Mail vorbereiten'));
    await tester.pumpAndSettle();
    expect(mailer.mails.single.body, startsWith('App stürzt ab.'));
  }, variant: iOS);

  testWidgets('T36.2 Verbesserung vorschlagen: button above the keyboard', (
    tester,
  ) async {
    final mailer = await _open(tester, FeedbackScreen.ideaPath);
    await _typeWithKeyboard(tester, _field('Deine Idee'), 'Sichtweite.');

    _expectAboveKeyboard(tester, 'Mail vorbereiten');
    await tester.tap(_button('Mail vorbereiten'));
    await tester.pumpAndSettle();
    expect(mailer.mails, hasLength(1));
  }, variant: iOS);

  testWidgets('T36.3 Manuell eintragen: „Speichern“ above the keyboard', (
    tester,
  ) async {
    await _open(tester, ManualDiveScreen.newPath);
    await _typeWithKeyboard(tester, _field('Dauer'), '45');

    _expectAboveKeyboard(tester, 'Speichern');
  }, variant: iOS);

  testWidgets('T36.4 Ausrüstung hinzufügen: „Speichern“ above the keyboard', (
    tester,
  ) async {
    await _open(tester, EquipmentEditScreen.newPath);
    await _typeWithKeyboard(tester, _field('Bezeichnung'), 'Hydros Pro');

    _expectAboveKeyboard(tester, 'Speichern');
  }, variant: iOS);

  group('T36.5 dragging the page closes the keyboard', () {
    for (final (name, location, label) in [
      ('Fehler melden', FeedbackScreen.bugPath, 'Was ist passiert?'),
      ('Verbesserung vorschlagen', FeedbackScreen.ideaPath, 'Deine Idee'),
      ('Manuell eintragen', ManualDiveScreen.newPath, 'Dauer'),
      ('Ausrüstung hinzufügen', EquipmentEditScreen.newPath, 'Bezeichnung'),
    ]) {
      testWidgets(name, (tester) async {
        await _open(tester, location);
        final field = _field(label);
        await _typeWithKeyboard(tester, field, '4');
        expect(_hasFocus(tester, field), isTrue);

        await tester.drag(find.byType(ListView).first, const Offset(0, -120));
        await tester.pumpAndSettle();

        expect(_hasFocus(tester, field), isFalse);
      }, variant: iOS);
    }
  });
}
