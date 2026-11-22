// T12.28-T12.34, T12.14 (FIT): FIT import from the file dialog or shared
// from another app (ui-spec §5.5, §5.8, §5.9).
import 'dart:async';

import 'package:divedown/app/providers.dart';
import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/dive/diver.dart';
import 'package:divedown/domain/import/file_import.dart';
import 'package:divedown/features/import/fit_import_screen.dart';
import 'package:divedown/features/import/import_screen.dart';
import 'package:divedown/features/logbook/logbook_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_file_import.dart';
import '../../support/test_app.dart';

class _Harness {
  _Harness(this.db, this.anna);

  final AppDatabase db;
  final Diver anna;
  final picker = FakeFilePicker();
  final shared = FakeSharedFiles();
  final source = FakeFileDiveSource();
}

Future<_Harness> _open(WidgetTester tester, {String? location}) async {
  final db = newTestDatabase();
  addTearDown(db.close);
  final h = _Harness(db, await seedActiveDiver(db));
  await pumpTestApp(
    tester,
    db: db,
    location: location ?? ImportScreen.path,
    overrides: [
      importFilePickerProvider.overrideWithValue(h.picker),
      sharedFilesProvider.overrideWithValue(h.shared),
      fileDiveSourceProvider.overrideWithValue(h.source),
    ],
  );
  return h;
}

Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _pickFit(WidgetTester tester) async {
  await tester.tap(find.text('FIT-Datei'));
  await _frames(tester);
}

void main() {
  testWidgets('T12.28 Suunto export guide under the FIT card (§5.5)', (
    tester,
  ) async {
    await _open(tester);

    await tester.tap(find.text('So exportierst du aus der Suunto-App'));
    await _frames(tester);

    expect(
      find.textContaining('Öffne die Suunto-App und wähle den Tauchgang.'),
      findsOneWidget,
    );
  });

  testWidgets('T12.29 dialog closed without a file: nothing happens', (
    tester,
  ) async {
    final h = await _open(tester);
    h.picker.next = null;

    await _pickFit(tester);

    expect(h.picker.calls, 1);
    expect(currentLocation(tester), ImportScreen.path);
    expect(h.source.parsed, isEmpty);
  });

  testWidgets('T12.30 while reading: „Datei wird gelesen …“', (tester) async {
    final h = await _open(tester);
    h.source.pending = Completer<void>();

    await _pickFit(tester);

    expect(currentLocation(tester), FitImportScreen.path);
    expect(find.text('Datei wird gelesen …'), findsOneWidget);
    h.source.pending!.complete();
    await _frames(tester);
    expect(find.text('Datei wird gelesen …'), findsNothing);
  });

  testWidgets('T12.31 preview with file name and diver; import saves '
      'and goes to the logbook', (tester) async {
    final h = await _open(tester);

    await _pickFit(tester);

    expect(find.text('Aus Datei: Tauchgang.fit'), findsOneWidget);
    // One diver per app since 2026-11-22 (ui-spec §2, T23.13).
    expect(find.textContaining('Importieren für'), findsNothing);
    expect(find.text('18,4 m · 47 min'), findsOneWidget);
    await tester.tap(find.text('1 Tauchgang importieren'));
    await tester.pumpAndSettle();

    expect(currentLocation(tester), LogbookScreen.path);
    expect(find.text('1 Tauchgang importiert'), findsOneWidget);
    final saved = await DriftDiveRepository(h.db).listForDiver(h.anna.id!);
    expect(saved.single.source, DiveSource.fit);
    expect(saved.single.sourceId, '777:14');
    expect(saved.single.diveComputerId, isNull);
  });

  testWidgets('T12.32 the same file again: „Bereits im Logbuch“', (
    tester,
  ) async {
    final h = await _open(tester);
    await seedDive(h.db, fitDive(14).toDive(diverId: h.anna.id!));

    await _pickFit(tester);

    expect(find.text('Bereits im Logbuch'), findsOneWidget);
    expect(find.text('Nichts ausgewählt'), findsOneWidget);
  });

  group('T12.33 file errors (§5.8)', () {
    const unreadable =
        'Diese Datei konnte nicht gelesen werden. Ist es eine FIT-Datei aus '
        'der Suunto- oder Garmin-App?';
    for (final (reason, text) in [
      (FileImportFailure.tooLarge, 'Die Datei ist zu groß (max. 10 MB).'),
      (FileImportFailure.notFit, unreadable),
      (FileImportFailure.corrupt, unreadable),
      (FileImportFailure.unreadable, unreadable),
      (
        FileImportFailure.noDive,
        'Die Datei enthält keinen Tauchgang (sondern z. B. Laufen oder '
            'Radfahren).',
      ),
      (
        FileImportFailure.timeout,
        'Das Lesen hat zu lange gedauert. Die Datei ist möglicherweise '
            'beschädigt.',
      ),
    ]) {
      testWidgets('${reason.name}: message, file name, nothing saved', (
        tester,
      ) async {
        final h = await _open(tester);
        h.source.result = FileFailed(reason);

        await _pickFit(tester);

        expect(find.text(text), findsOneWidget);
        expect(find.text('Aus Datei: Tauchgang.fit'), findsOneWidget);
        expect(
          await DriftDiveRepository(h.db).listForDiver(h.anna.id!),
          isEmpty,
        );
      });
    }

    testWidgets('too large already in the dialog: parser not called', (
      tester,
    ) async {
      final h = await _open(tester);
      h.picker.next = const PickFailed(
        'riesig.fit',
        FileImportFailure.tooLarge,
      );

      await _pickFit(tester);

      expect(find.text('Die Datei ist zu groß (max. 10 MB).'), findsOneWidget);
      expect(h.source.parsed, isEmpty);
    });
  });

  testWidgets('T12.34 shared from another app: opens the FIT preview '
      'directly, from any tab', (tester) async {
    final h = await _open(tester, location: LogbookScreen.path);

    h.shared.share(Picked(fitFile('Ocean 14.11.fit')));
    // From another tab the page change takes longer than _frames.
    await tester.pumpAndSettle();

    expect(currentLocation(tester), FitImportScreen.path);
    expect(find.text('Aus Datei: Ocean 14.11.fit'), findsOneWidget);
    expect(find.text('1 Tauchgang importieren'), findsOneWidget);
  });

  testWidgets('T12.14 FIT preview and error: tap targets and contrast', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final h = await _open(tester);

    await _pickFit(tester);
    expect(find.text('1 Tauchgang importieren'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    router(tester).go(ImportScreen.path);
    await _frames(tester);
    h.source.result = const FileFailed(FileImportFailure.noDive);
    await _pickFit(tester);
    expect(find.textContaining('keinen Tauchgang'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
