// T32.1-T32.2: new dives are highlighted after an import (ui-spec §5.2).
import 'package:divedown/app/providers.dart';
import 'package:divedown/domain/import/file_import.dart';
import 'package:divedown/features/import/import_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_file_import.dart';
import '../../support/test_app.dart';

Future<void> _importFit(
  WidgetTester tester, {
  List<int> dives = const [14],
}) async {
  final db = newTestDatabase();
  addTearDown(db.close);
  final anna = await seedActiveDiver(db);
  await seedDive(db, exampleDive(anna.id!, number: 1));
  final source = FakeFileDiveSource()
    ..result = FileDives([for (final n in dives) fitDive(n)]);
  await pumpTestApp(
    tester,
    db: db,
    location: ImportScreen.path,
    overrides: [
      importFilePickerProvider.overrideWithValue(FakeFilePicker()),
      sharedFilesProvider.overrideWithValue(FakeSharedFiles()),
      fileDiveSourceProvider.overrideWithValue(source),
    ],
  );
  await tester.tap(find.text('FIT-Datei'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.tap(find.textContaining('importieren').last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('T32.1 the imported dive is marked „Neu“ for 3 s, the old one '
      'not; afterwards no mark', (tester) async {
    await _importFit(tester);

    expect(find.text('1 Tauchgang importiert'), findsOneWidget);
    expect(find.text('Neu'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Neu importiert')), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.text('Neu'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Neu'), findsNothing);
  });

  testWidgets('T32.2 a second visit of the logbook shows no mark', (
    tester,
  ) async {
    await _importFit(tester);
    expect(find.text('Neu'), findsOneWidget);

    Finder tab(String label) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );
    await tester.tap(tab('Einstellungen'));
    await tester.pumpAndSettle();
    await tester.tap(tab('Logbuch'));
    await tester.pumpAndSettle();
    expect(find.text('Neu'), findsNothing);
  });
}
