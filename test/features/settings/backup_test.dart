// T11.11-T11.15: Logbuch sichern / wiederherstellen and the reminder
// (ui-spec §5.2, §5.12, one diver per app).
import 'dart:typed_data';

import 'package:divedown/app/providers.dart';
import 'package:divedown/data/backup/logbook_backup.dart';
import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_app_settings.dart';
import 'package:divedown/domain/import/file_import.dart';
import 'package:divedown/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_file_import.dart';
import '../../support/test_app.dart';

class _FakeBackup implements BackupActions {
  BackupCheck check = BackupReadable(
    BackupManifest(
      format: 1,
      appVersion: '1.0.0',
      schemaVersion: 1,
      createdAt: DateTime.utc(2026, 12, 20, 18),
      sha256: 'x',
      diveCount: 128,
    ),
  );
  RestoreResult? result;
  int created = 0;
  int restored = 0;

  @override
  Future<BackupFile> create() async {
    created++;
    return BackupFile(
      'DiveDown-Sicherung-2026-11-22.divedown',
      Uint8List.fromList([1, 2, 3]),
    );
  }

  @override
  BackupCheck inspect(Uint8List bytes) => check;

  @override
  Future<RestoreResult> restore(Uint8List bytes) async {
    restored++;
    return result ?? Restored((check as BackupReadable).manifest);
  }
}

class _Shared {
  final files = <String>[];
}

Future<(_FakeBackup, _Shared, FakeFilePicker)> _open(
  WidgetTester tester,
  AppDatabase db, {
  String? location = SettingsScreen.path,
}) async {
  final backup = _FakeBackup();
  final shared = _Shared();
  final picker = FakeFilePicker()
    ..next = Picked(ImportFile('Sicherung.divedown', Uint8List(10)));
  await pumpTestApp(
    tester,
    db: db,
    size: const Size(400, 1800),
    location: location,
    overrides: [
      appInfoProvider.overrideWith(
        (ref) async => const AppInfo(
          version: '1.0.0',
          build: '1',
          libdivecomputer: '0.10.0',
        ),
      ),
      backupActionsProvider.overrideWithValue(backup),
      shareFileProvider.overrideWithValue(
        (name, bytes) async => shared.files.add(name),
      ),
      backupFilePickerProvider.overrideWithValue(picker),
    ],
  );
  return (backup, shared, picker);
}

const _invalid = 'Diese Datei ist keine gültige DiveDown-Sicherung.';

void main() {
  testWidgets('T11.11 section DATEN with both entries', (tester) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await seedActiveDiver(db);
    await _open(tester, db);

    expect(find.text('DATEN'), findsOneWidget);
    expect(find.text('Logbuch sichern'), findsOneWidget);
    expect(find.text('Logbuch wiederherstellen'), findsOneWidget);
  });

  testWidgets('T11.12 sichern: hint, warning, share, done', (tester) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await seedActiveDiver(db);
    final (backup, shared, _) = await _open(tester, db);

    await tester.tap(find.text('Logbuch sichern'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Erstellt eine Datei mit allen Tauchgängen. Speichere sie z. B. in '
        '„Dateien“ oder schicke sie dir per Mail.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Die Datei ist nicht verschlüsselt und enthält Gesundheitsdaten (Puls).',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Sicherung erstellen'));
    await tester.pumpAndSettle();

    expect(backup.created, 1);
    expect(shared.files, ['DiveDown-Sicherung-2026-11-22.divedown']);
    expect(find.text('Sicherung erstellt'), findsOneWidget);
    expect(await DriftAppSettings(db).lastBackupAt(), isNotNull);
  });

  testWidgets('T11.13 wiederherstellen: summary, confirm, done', (
    tester,
  ) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await seedActiveDiver(db);
    final (backup, _, picker) = await _open(tester, db);

    await tester.tap(find.text('Logbuch wiederherstellen'));
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(
      find.text('Sicherung vom 20.12.2026 · 128 Tauchgänge'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Dein aktuelles Logbuch wird ersetzt. '
        'Vorher wird automatisch eine Kopie angelegt.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Wiederherstellen'));
    await tester.pumpAndSettle();

    expect(backup.restored, 1);
    expect(find.text('Wiederhergestellt'), findsOneWidget);
  });

  testWidgets('T11.13 cancel restores nothing; no file chosen: nothing', (
    tester,
  ) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await seedActiveDiver(db);
    final (backup, _, picker) = await _open(tester, db);

    await tester.tap(find.text('Logbuch wiederherstellen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(backup.restored, 0);

    picker.next = null;
    await tester.tap(find.text('Logbuch wiederherstellen'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sicherung vom'), findsNothing);
    expect(backup.restored, 0);
  });

  group('T11.14 problems are explained, nothing is replaced', () {
    Future<void> expectText(
      WidgetTester tester, {
      BackupCheck? check,
      PickResult? pick,
      RestoreResult? result,
      required String text,
    }) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      await seedActiveDiver(db);
      final (backup, _, picker) = await _open(tester, db);
      if (check != null) backup.check = check;
      if (pick != null) picker.next = pick;
      backup.result = result;

      await tester.tap(find.text('Logbuch wiederherstellen'));
      await tester.pumpAndSettle();
      if (result != null) {
        await tester.tap(find.widgetWithText(FilledButton, 'Wiederherstellen'));
        await tester.pumpAndSettle();
      } else {
        expect(backup.restored, 0);
      }
      expect(find.text(text), findsOneWidget);
    }

    testWidgets('invalid', (tester) async {
      await expectText(
        tester,
        check: const BackupRejected(BackupProblem.invalid),
        text: _invalid,
      );
    });

    testWidgets('corrupt', (tester) async {
      await expectText(
        tester,
        check: const BackupRejected(BackupProblem.corrupt),
        text: 'Die Sicherung ist beschädigt und kann nicht verwendet werden.',
      );
    });

    testWidgets('newer version', (tester) async {
      await expectText(
        tester,
        check: const BackupRejected(BackupProblem.newerVersion),
        text:
            'Diese Sicherung stammt aus einer neueren DiveDown-Version. '
            'Bitte aktualisiere die App zuerst.',
      );
    });

    testWidgets('too large (file dialog)', (tester) async {
      await expectText(
        tester,
        pick: const PickFailed('riesig.divedown', FileImportFailure.tooLarge),
        text: 'Die Datei ist zu groß für eine DiveDown-Sicherung.',
      );
    });

    testWidgets('replacing failed', (tester) async {
      await expectText(
        tester,
        result: const RestoreFailed('disk full'),
        text:
            'Wiederherstellen fehlgeschlagen. '
            'Dein bisheriges Logbuch ist unverändert.',
      );
    });

    testWidgets('T10.14 replacing failed offers „Logs an Entwickler senden“', (
      tester,
    ) async {
      await expectText(
        tester,
        result: const RestoreFailed('disk full'),
        text:
            'Wiederherstellen fehlgeschlagen. '
            'Dein bisheriges Logbuch ist unverändert.',
      );
      await tester.tap(find.text('Logs an Entwickler senden'));
      await tester.pumpAndSettle();
      expect(find.text('Am besten per Mail.'), findsOneWidget);
    });
  });

  group('T11.15 reminder in the logbook', () {
    testWidgets('never backed up, app older than 30 days: card, ✕ hides it', (
      tester,
    ) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final anna = await seedActiveDiver(db);
      await seedDive(db, exampleDive(anna.id!));
      await db
          .into(db.appMeta)
          .insertOnConflictUpdate(
            AppMetaCompanion.insert(
              key: 'backup_baseline',
              value: DateTime.now()
                  .toUtc()
                  .subtract(const Duration(days: 40))
                  .toIso8601String(),
            ),
          );
      await _open(tester, db, location: null);

      expect(find.text('Noch keine Sicherung.'), findsOneWidget);
      expect(find.text('Jetzt sichern'), findsOneWidget);
      await tester.tap(find.byTooltip('Erinnerung ausblenden'));
      await tester.pumpAndSettle();

      expect(find.text('Noch keine Sicherung.'), findsNothing);
      final until = await DriftAppSettings(db).backupReminderSnoozedUntil();
      expect(
        until!.difference(DateTime.now().toUtc()).inDays,
        inInclusiveRange(6, 7),
      );
    });

    testWidgets('last backup 34 days ago; „Jetzt sichern“ opens sichern', (
      tester,
    ) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final anna = await seedActiveDiver(db);
      await seedDive(db, exampleDive(anna.id!));
      await DriftAppSettings(db).setLastBackupAt(
        DateTime.now().toUtc().subtract(const Duration(days: 34, hours: 1)),
      );
      await _open(tester, db, location: null);

      expect(find.text('Letzte Sicherung vor 34 Tagen.'), findsOneWidget);
      await tester.tap(find.text('Jetzt sichern'));
      await tester.pumpAndSettle();
      expect(find.text('Sicherung erstellen'), findsOneWidget);
    });

    testWidgets('recent backup: no card', (tester) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final anna = await seedActiveDiver(db);
      await seedDive(db, exampleDive(anna.id!));
      await DriftAppSettings(db).setLastBackupAt(DateTime.now().toUtc());
      await _open(tester, db, location: null);

      expect(find.text('Jetzt sichern'), findsNothing);
    });
  });
}
