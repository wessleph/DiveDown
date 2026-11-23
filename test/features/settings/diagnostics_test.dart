// T10.13: Diagnose-Logs teilen (ui-spec §5.13, design.md §9).
import 'dart:convert';
import 'dart:typed_data';

import 'package:divedown/app/providers.dart';
import 'package:divedown/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

Future<List<(String, Uint8List)>> _open(
  WidgetTester tester, {
  required MemoryDiagnosticLog log,
}) async {
  final db = newTestDatabase();
  addTearDown(db.close);
  await seedActiveDiver(db);
  final shared = <(String, Uint8List)>[];
  await pumpTestApp(
    tester,
    db: db,
    size: const Size(400, 2200),
    location: SettingsScreen.path,
    diagnosticLog: log,
    overrides: [
      appInfoProvider.overrideWith(
        (ref) async => const AppInfo(
          version: '1.0.0',
          build: '1',
          libdivecomputer: '0.10.0',
        ),
      ),
      shareFileProvider.overrideWithValue(
        (name, bytes) async => shared.add((name, bytes)),
      ),
    ],
  );
  return shared;
}

void main() {
  testWidgets('T10.13 HILFE opens the preview, „Teilen“ shares the text', (
    tester,
  ) async {
    final log = MemoryDiagnosticLog([
      for (var i = 0; i < 250; i++) 'INFO BLE step $i',
    ]);
    final shared = await _open(tester, log: log);

    expect(find.text('HILFE'), findsOneWidget);
    await tester.tap(find.text('Diagnose-Logs teilen'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Hilf bei der Fehlersuche: Schicke das Protokoll an den Entwickler. '
        'Es enthält keine Orte, Namen oder Gesundheitswerte.',
      ),
      findsOneWidget,
    );
    // The first 200 lines, then the rest counted.
    expect(find.textContaining('INFO BLE step 0'), findsOneWidget);
    expect(find.textContaining('INFO BLE step 199'), findsOneWidget);
    expect(find.textContaining('INFO BLE step 200'), findsNothing);
    expect(find.text('… 50 weitere Zeilen'), findsOneWidget);
    expect(find.text('Am besten per Mail.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Teilen'));
    await tester.pumpAndSettle();

    expect(shared, hasLength(1));
    final (name, bytes) = shared.single;
    expect(
      name,
      matches(RegExp(r'^DiveDown-Diagnose-\d{4}-\d{2}-\d{2}\.txt$')),
    );
    final text = utf8.decode(bytes);
    expect(text, startsWith('DiveDown 1.0.0 (Build 1)'));
    expect(text, contains('INFO BLE step 249'));
  });

  testWidgets('T10.13 empty log: hint, nothing to share', (tester) async {
    final shared = await _open(tester, log: MemoryDiagnosticLog());

    await tester.tap(find.text('Diagnose-Logs teilen'));
    await tester.pumpAndSettle();

    expect(find.text('Noch keine Einträge im Protokoll.'), findsOneWidget);
    final share = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Teilen'),
    );
    expect(share.onPressed, isNull);
    expect(shared, isEmpty);
  });
}
