// T12.4-T12.11, T12.14 (import), T12.16-T12.24: BLE import screens
// (ui-spec §5.5-§5.7, §5.9). Fakes for plugin, permissions and display.
import 'package:divedown/app/providers.dart';
import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_dive_computer_repository.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/domain/dive/diver.dart';
import 'package:divedown/domain/import/bluetooth_access.dart';
import 'package:divedown/domain/import/dive_computer_registry.dart';
import 'package:divedown/domain/import/dive_computer_source.dart';
import 'package:divedown/features/import/dive_computer_screen.dart';
import 'package:divedown/features/import/import_screen.dart';
import 'package:divedown/features/logbook/logbook_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dive_computer.dart';
import '../../support/test_app.dart';

class _Harness {
  _Harness(this.db, this.anna);

  final AppDatabase db;
  final Diver anna;
  final source = FakeDiveComputerSource();
  final access = FakeBluetoothAccess();
  final awake = FakeScreenAwake();
}

Future<_Harness> _setUp(WidgetTester tester) async {
  final db = newTestDatabase();
  addTearDown(db.close);
  final h = _Harness(db, await seedActiveDiver(db));
  return h;
}

/// Opens the app on the import tab. Does not wait for animations to end:
/// the search and the transfer animate as long as they run.
Future<void> _pump(
  WidgetTester tester,
  _Harness h, {
  String location = DiveComputerScreen.path,
}) async {
  await pumpTestApp(
    tester,
    db: h.db,
    overrides: [
      diveComputerSourceProvider.overrideWithValue(h.source),
      bluetoothAccessProvider.overrideWithValue(h.access),
      screenAwakeProvider.overrideWithValue(h.awake),
    ],
  );
  router(tester).go(location);
  await _frames(tester);
}

Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).first);
  await _frames(tester);
}

/// Seeds the EON Core as known from an earlier download, serial S.
Future<KnownDiveComputer> _seedKnown(AppDatabase db) =>
    DriftDiveComputerRepository(db).create(
      KnownDiveComputer(
        id: '',
        vendor: 'Suunto',
        product: 'EON Core',
        model: 1,
        serial: 'S',
        address: eonCore.address,
      ),
    );

void main() {
  group('T12.16 choose the source (§5.5)', () {
    testWidgets('cards, diver, no Apple Health on Android', (tester) async {
      final h = await _setUp(tester);
      await _pump(tester, h, location: ImportScreen.path);

      expect(find.text('Importieren für: Anna'), findsOneWidget);
      expect(find.text('Tauchcomputer'), findsOneWidget);
      expect(find.text('Per Bluetooth übertragen'), findsOneWidget);
      expect(find.text('FIT-Datei'), findsOneWidget);
      expect(find.text('Apple Health'), findsNothing);
    });

    testWidgets('„Tauchcomputer“ opens the search', (tester) async {
      final h = await _setUp(tester);
      await _pump(tester, h, location: ImportScreen.path);

      await _tapText(tester, 'Tauchcomputer');

      expect(currentLocation(tester), DiveComputerScreen.path);
    });
  });

  group('permissions and radio (§5.6)', () {
    testWidgets('T12.4 Bluetooth off: text and „Bluetooth einschalten“', (
      tester,
    ) async {
      final h = await _setUp(tester);
      h.access.state = BluetoothReadiness.off;
      await _pump(tester, h);

      expect(find.text('Bluetooth ist ausgeschaltet.'), findsOneWidget);
      expect(h.source.discoverCalls, 0);
      await _tapText(tester, 'Bluetooth einschalten');
      expect(h.access.enableRequests, 1);
    });

    testWidgets('T12.5 permanently denied: „Einstellungen öffnen“', (
      tester,
    ) async {
      final h = await _setUp(tester);
      h.access.state = BluetoothReadiness.permanentlyDenied;
      await _pump(tester, h);

      expect(
        find.text(
          'Ohne Bluetooth-Berechtigung kann DiveDown keine Tauchcomputer finden.',
        ),
        findsOneWidget,
      );
      await _tapText(tester, 'Einstellungen öffnen');
      expect(h.access.settingsOpened, 1);
      expect(h.source.discoverCalls, 0);
    });

    testWidgets('T12.22 not asked yet: explanation first, then the dialog, '
        'then the search', (tester) async {
      final h = await _setUp(tester);
      h.access.state = BluetoothReadiness.needsPermission;
      await _pump(tester, h);

      expect(
        find.text(
          'DiveDown braucht Bluetooth, um Tauchgänge von deinem '
          'Tauchcomputer zu laden. Es werden keine anderen Geräte gespeichert.',
        ),
        findsOneWidget,
      );
      expect(h.access.permissionRequests, 0);

      await _tapText(tester, 'Weiter');

      expect(h.access.permissionRequests, 1);
      expect(h.source.discoverCalls, 1);
    });
  });

  group('search (§5.6)', () {
    testWidgets('T12.17 search starts by itself, with hint and „Stopp“', (
      tester,
    ) async {
      final h = await _setUp(tester);
      h.source.devices = [];
      await _pump(tester, h);

      expect(h.source.discoverCalls, 1);
      expect(find.text('Suche nach Tauchcomputern …'), findsOneWidget);
      expect(
        find.text(
          'Aktiviere Bluetooth am Tauchcomputer: EON Core → Einstellungen → '
          'Verbindungen → Koppeln.',
        ),
        findsOneWidget,
      );
      await _tapText(tester, 'Stopp');
      expect(h.source.stopDiscoveryCalls, 1);
    });

    testWidgets('T12.6 nothing found in 30 s: checklist with the Suunto app, '
        '„Erneut suchen“', (tester) async {
      final h = await _setUp(tester);
      h.source.devices = [];
      await _pump(tester, h);

      await tester.pump(const Duration(seconds: 30));
      await _frames(tester);

      expect(h.source.stopDiscoveryCalls, 1);
      expect(find.text('Kein Tauchcomputer gefunden.'), findsOneWidget);
      expect(
        find.text('Ist Bluetooth am Tauchcomputer aktiv?'),
        findsOneWidget,
      );
      expect(
        find.text('Liegt der Tauchcomputer nah am Handy?'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Schließe die Suunto-App ganz. Sie hält sonst die Verbindung '
          'zum EON Core, auch im Hintergrund.',
        ),
        findsOneWidget,
      );

      await _tapText(tester, 'Erneut suchen');
      expect(h.source.discoverCalls, 2);
    });

    testWidgets('T12.23 known device is marked „Bekannt“', (tester) async {
      final h = await _setUp(tester);
      await _seedKnown(h.db);
      await _pump(tester, h);

      expect(find.text('EON Core'), findsWidgets);
      expect(find.text('Bekannt'), findsOneWidget);
    });

    testWidgets('T12.7 Suunto Ocean: greyed out, points to the FIT guide', (
      tester,
    ) async {
      final h = await _setUp(tester);
      h.source.devices = [suuntoOcean];
      await _pump(tester, h);

      expect(find.text('Suunto Ocean'), findsOneWidget);
      expect(
        find.text('Dieses Modell wird nicht direkt unterstützt.'),
        findsOneWidget,
      );
      expect(find.text('Nutze den Import per FIT-Datei.'), findsOneWidget);
      expect(find.text('Zur FIT-Anleitung'), findsOneWidget);

      await _tapText(tester, 'Suunto Ocean');
      expect(h.source.downloads, isEmpty);
    });
  });

  group('transfer (§5.7)', () {
    testWidgets('T12.18 running: count, hint, display on; '
        '„Abbrechen“ keeps the dives', (tester) async {
      final h = await _setUp(tester);
      await _pump(tester, h);
      await _tapText(tester, 'EON Core');

      expect(h.source.stopDiscoveryCalls, 1);
      expect(h.source.downloads.single.computer.address, eonCore.address);
      expect(
        find.text(
          'Halte den Tauchcomputer in der Nähe. Das kann einige Minuten dauern.',
        ),
        findsOneWidget,
      );
      expect(h.awake.on, isTrue);

      h.source.emit(const TransferProgress(100, 400));
      h.source.emit(DiveReceived(computerDive(12)));
      h.source.emit(DiveReceived(computerDive(13)));
      await _frames(tester);
      expect(find.text('2 neue Tauchgänge gefunden …'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(0.25, 0.01));

      await _tapText(tester, 'Abbrechen');

      expect(h.source.cancelCalls, 1);
      expect(h.awake.on, isFalse);
      expect(find.text('Übertragung abgebrochen.'), findsOneWidget);
      expect(find.text('2 Tauchgänge importieren'), findsOneWidget);
    });

    testWidgets('T12.19 no new dives: „Fertig“ goes back', (tester) async {
      final h = await _setUp(tester);
      await _pump(tester, h);
      await _tapText(tester, 'EON Core');

      h.source.emit(const TransferCompleted(serial: 'S'));
      await _frames(tester);

      expect(
        find.text(
          'Alles auf dem neuesten Stand. Keine neuen Tauchgänge auf dem '
          'Tauchcomputer.',
        ),
        findsOneWidget,
      );
      expect(h.awake.on, isFalse);
      await _tapText(tester, 'Fertig');
      expect(currentLocation(tester), ImportScreen.path);
    });

    testWidgets('T12.20 connection lost after 2 dives: check them or '
        'reconnect', (tester) async {
      final h = await _setUp(tester);
      await _pump(tester, h);
      await _tapText(tester, 'EON Core');

      h.source.emit(DiveReceived(computerDive(12)));
      h.source.emit(DiveReceived(computerDive(13)));
      h.source.emit(
        const TransferFailed('download_error', 'x', connectionLost: true),
      );
      await _frames(tester);

      expect(find.text('Die Verbindung wurde unterbrochen.'), findsOneWidget);
      expect(find.text('2 Tauchgänge wurden übertragen.'), findsOneWidget);
      expect(find.text('Erneut verbinden'), findsOneWidget);

      await _tapText(tester, 'Übertragene prüfen');
      expect(find.text('2 Tauchgänge importieren'), findsOneWidget);
    });

    testWidgets('T12.24 unexpected error: card with the code', (tester) async {
      final h = await _setUp(tester);
      await _pump(tester, h);
      await _tapText(tester, 'EON Core');

      h.source.emit(
        const TransferFailed('download_crashed', 'x', connectionLost: false),
      );
      await _frames(tester);

      expect(find.text('Erneut versuchen'), findsOneWidget);
      expect(find.textContaining('download_crashed'), findsOneWidget);
    });

    group('T12.9 PIN dialog', () {
      testWidgets('names the device, sends the code', (tester) async {
        final h = await _setUp(tester);
        await _pump(tester, h);
        await _tapText(tester, 'EON Core');

        h.source.emit(const PinRequested());
        await _frames(tester);

        expect(
          find.text(
            'EON Core (••3F7A) fragt nach einem Code. Gib den Code ein, '
            'der auf dem Tauchcomputer angezeigt wird.',
          ),
          findsOneWidget,
        );
        await tester.enterText(find.byType(TextField), '123456');
        await _tapText(tester, 'Bestätigen');

        expect(h.source.pins, ['123456']);
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('after 60 s: „Zeit abgelaufen“, download cancelled', (
        tester,
      ) async {
        final h = await _setUp(tester);
        await _pump(tester, h);
        await _tapText(tester, 'EON Core');

        h.source.emit(const PinRequested());
        await _frames(tester);
        await tester.pump(const Duration(seconds: 60));
        await _frames(tester);

        expect(
          find.text('Zeit abgelaufen. Bitte erneut verbinden.'),
          findsOneWidget,
        );
        expect(h.source.cancelCalls, 1);
        expect(h.source.pins, isEmpty);
      });
    });

    group('T12.8 serial mismatch (security A1)', () {
      Future<_Harness> mismatch(WidgetTester tester) async {
        final h = await _setUp(tester);
        await _seedKnown(h.db);
        await _pump(tester, h);
        await _tapText(tester, 'EON Core');
        h.source.emit(DiveReceived(computerDive(12)));
        h.source.emit(const TransferCompleted(serial: 'OTHER'));
        await _frames(tester);
        return h;
      }

      testWidgets('warning with „Abbrechen“ as the primary button', (
        tester,
      ) async {
        await mismatch(tester);

        expect(
          find.text(
            'Dieses Gerät meldet eine andere Seriennummer als dein '
            'gespeicherter ‚EON Core‘. Wenn du das Gerät nicht kennst, '
            'brich ab.',
          ),
          findsOneWidget,
        );
        expect(find.widgetWithText(FilledButton, 'Abbrechen'), findsOneWidget);
        expect(
          find.widgetWithText(TextButton, 'Als neues Gerät verwenden'),
          findsOneWidget,
        );
      });

      testWidgets('„Abbrechen“ saves nothing', (tester) async {
        final h = await mismatch(tester);

        await tester.tap(find.widgetWithText(FilledButton, 'Abbrechen'));
        await _frames(tester);

        expect(find.text('1 Tauchgang importieren'), findsNothing);
        final anna = h.anna.id!;
        expect(await DriftDiveRepository(h.db).listForDiver(anna), isEmpty);
      });

      testWidgets('„Als neues Gerät verwenden“ goes on to the preview', (
        tester,
      ) async {
        await mismatch(tester);

        await _tapText(tester, 'Als neues Gerät verwenden');

        expect(find.text('1 Tauchgang importieren'), findsOneWidget);
      });
    });
  });

  group('preview (§5.9)', () {
    /// Downloads dives of Nov 12, 13, 14 at 09:00.
    Future<_Harness> preview(
      WidgetTester tester, {
      Future<void> Function(_Harness h)? seed,
    }) async {
      final h = await _setUp(tester);
      await seed?.call(h);
      await _pump(tester, h);
      await _tapText(tester, 'EON Core');
      for (final day in [12, 13, 14]) {
        h.source.emit(DiveReceived(computerDive(day)));
      }
      h.source.emit(const TransferCompleted(serial: 'S'));
      await _frames(tester);
      return h;
    }

    testWidgets('T12.10 similar dive: marked, not selected, count follows', (
      tester,
    ) async {
      await preview(
        tester,
        seed: (h) => seedDive(
          h.db,
          computerDive(13, fingerprint: 99).toDive(diverId: h.anna.id!),
        ),
      );

      expect(find.text('Importieren für: Anna'), findsOneWidget);
      expect(
        find.text('Ähnlicher Tauchgang vorhanden (13.11., 18,4 m, 47 min)'),
        findsOneWidget,
      );
      expect(find.text('2 Tauchgänge importieren'), findsOneWidget);
      final boxes = tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .map((c) => c.value)
          .toList();
      expect(boxes, [true, false, true]);
    });

    testWidgets('T12.25 exact duplicate: „Bereits im Logbuch“, '
        'cannot be selected', (tester) async {
      await preview(
        tester,
        seed: (h) =>
            seedDive(h.db, computerDive(12).toDive(diverId: h.anna.id!)),
      );

      expect(find.text('Bereits im Logbuch'), findsOneWidget);
      final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(boxes.first.onChanged, isNull);
      expect(find.text('2 Tauchgänge importieren'), findsOneWidget);
    });

    testWidgets('T12.11 nothing selected: button off, „Nichts ausgewählt“', (
      tester,
    ) async {
      await preview(tester);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(Checkbox).at(i));
        await _frames(tester);
      }

      final button = find.widgetWithText(FilledButton, 'Nichts ausgewählt');
      expect(button, findsOneWidget);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
    });

    testWidgets('T12.21 import: saved, back in the logbook with snackbar', (
      tester,
    ) async {
      final h = await preview(tester);

      await _tapText(tester, '3 Tauchgänge importieren');
      await tester.pumpAndSettle();

      expect(currentLocation(tester), LogbookScreen.path);
      expect(find.text('3 Tauchgänge importiert'), findsOneWidget);
      final saved = await DriftDiveRepository(h.db).listForDiver(h.anna.id!);
      expect(saved, hasLength(3));
      final device = await DriftDiveComputerRepository(h.db)
          .findByAddress(eonCore.address);
      expect(device!.serial, 'S');
      expect(device.lastFingerprint, [14]);
    });

    testWidgets('T12.26 after the import, the tab starts at the source '
        'choice again', (tester) async {
      await preview(tester);
      await _tapText(tester, '3 Tauchgänge importieren');
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Importieren'),
        ),
      );
      await _frames(tester);

      expect(currentLocation(tester), ImportScreen.path);
      expect(find.text('Per Bluetooth übertragen'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('T12.27 no tab bar while the dive computer flow runs', (
      tester,
    ) async {
      final h = await _setUp(tester);
      await _pump(tester, h);

      expect(find.byType(NavigationBar), findsNothing);
    });
  });

  group('T12.14 import screens: tap targets and contrast', () {
    Future<void> check(WidgetTester tester) async {
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    }

    testWidgets('source, device list, preview', (tester) async {
      final handle = tester.ensureSemantics();
      final h = await _setUp(tester);
      h.source.devices = [eonCore, suuntoOcean];
      await _pump(tester, h, location: ImportScreen.path);
      expect(find.text('Tauchcomputer'), findsOneWidget);
      await check(tester);

      await _tapText(tester, 'Tauchcomputer');
      expect(find.text('Suunto Ocean'), findsOneWidget);
      await check(tester);

      await _tapText(tester, 'EON Core');
      h.source.emit(DiveReceived(computerDive(12)));
      h.source.emit(const TransferCompleted(serial: 'S'));
      await _frames(tester);
      expect(find.text('1 Tauchgang importieren'), findsOneWidget);
      await check(tester);
      handle.dispose();
    });
  });
}
