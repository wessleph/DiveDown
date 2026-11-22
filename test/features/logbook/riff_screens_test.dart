// T21.6-T21.8, T21.11-T21.13: logbook header and cards, detail header,
// key figures and events in the Riff style (ui-spec §5.2, §5.3).
import 'package:divedown/app/theme.dart';
import 'package:divedown/data/local/drift_dive_computer_repository.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/import/dive_computer_registry.dart';
import 'package:divedown/features/logbook/dive_detail_screen.dart';
import 'package:divedown/features/logbook/logbook_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

Finder _inLogbook(Finder f) =>
    find.descendant(of: find.byType(LogbookScreen), matching: f);

void main() {
  group('logbook (ui-spec §5.2)', () {
    testWidgets('T21.6 header: two tiles, no deepest dive, no avatar', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final db = newTestDatabase();
      addTearDown(db.close);
      final anna = await seedActiveDiver(db);
      for (var i = 0; i < 3; i++) {
        await seedDive(
          db,
          exampleDive(
            anna.id!,
            number: 40 + i,
            start: DateTime.utc(2026, 11, 12 + i, 10),
          ),
        );
      }
      await pumpTestApp(tester, db: db);

      // One diver per app since 2026-11-22: no avatar (ui-spec §2, T23.13).
      expect(_inLogbook(find.text('A')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Taucher Anna')), findsNothing);
      expect(_inLogbook(find.text('Tauchgänge')), findsOneWidget);
      expect(_inLogbook(find.text('3')), findsOneWidget);
      expect(_inLogbook(find.text('unter Wasser')), findsOneWidget);
      expect(_inLogbook(find.text('2 h 21 min')), findsOneWidget); // 3 × 47
      expect(_inLogbook(find.textContaining('tiefst')), findsNothing);
      handle.dispose();
    });

    testWidgets('T21.7 each dive is a card with a sparkline', (tester) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final anna = await seedActiveDiver(db);
      await seedDive(db, exampleDive(anna.id!, number: 41));
      await seedDive(
        db,
        exampleDive(anna.id!, number: 42, start: DateTime.utc(2026, 11, 15)),
      );
      await pumpTestApp(tester, db: db);

      expect(
        _inLogbook(find.byKey(const ValueKey('sparkline'))),
        findsNWidgets(2),
      );
      final cards = _inLogbook(find.byType(Card));
      expect(cards, findsAtLeastNWidgets(2));
      expect(
        _inLogbook(find.text('14.11.2026 · 10:42 · 47 min')),
        findsOneWidget,
      );
    });

    testWidgets('T21.8 „Manuell eintragen“ uses the coral accent', (
      tester,
    ) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final anna = await seedActiveDiver(db);
      await seedDive(db, exampleDive(anna.id!));
      await pumpTestApp(tester, db: db);

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      final accent = buildLightTheme().extension<DiveColors>()!.accent;
      final themed = Theme.of(tester.element(find.byType(FloatingActionButton)))
          .floatingActionButtonTheme
          .backgroundColor;
      expect(fab.backgroundColor ?? themed, accent);
    });
  });

  group('detail (ui-spec §5.3)', () {
    testWidgets('T21.11 source shows the model and the short id', (
      tester,
    ) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final anna = await seedActiveDiver(db);
      final computer = await DriftDiveComputerRepository(db).create(
        const KnownDiveComputer(
          id: '',
          vendor: 'Suunto',
          product: 'EON Core',
          serial: '2219801234',
          address: 'D4:22:CD:00:3F:7A',
        ),
      );
      final dive = await seedDive(
        db,
        exampleDive(anna.id!).copyWith(diveComputerId: computer.id),
      );
      await pumpTestApp(
        tester,
        db: db,
        location: DiveDetailScreen.pathFor(dive.id!),
      );

      expect(find.textContaining('Suunto EON Core ••3F7A'), findsOneWidget);
    });

    testWidgets('T21.12 key figures: tank tile and SAC with its origin', (
      tester,
    ) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final anna = await seedActiveDiver(db);
      final dive = await seedDive(db, exampleDive(anna.id!));
      await pumpTestApp(
        tester,
        db: db,
        location: DiveDetailScreen.pathFor(dive.id!),
      );

      expect(find.text('Flasche'), findsWidgets);
      expect(find.text('12 l'), findsWidgets);
      expect(find.text('200 → 50 bar'), findsOneWidget);
      expect(find.text('19,1 l/min'), findsOneWidget);
      // No pressure samples in the example dive: estimated.
      expect(find.text('geschätzt aus 200 → 50 bar'), findsOneWidget);
    });

    testWidgets('T21.12 SAC from pressure samples is marked „gemessen“', (
      tester,
    ) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final anna = await seedActiveDiver(db);
      final dive = await seedDive(
        db,
        exampleDive(
          anna.id!,
          samples: [
            for (var t = 0; t <= 2820; t += 60)
              DiveSample(
                timeS: t,
                depthM: 10,
                pressures: [
                  TankPressure(tankIndex: 0, pressureBar: 200 - t / 2820 * 150),
                ],
              ),
          ],
        ),
      );
      await pumpTestApp(
        tester,
        db: db,
        location: DiveDetailScreen.pathFor(dive.id!),
      );

      expect(find.text('gemessen'), findsOneWidget);
    });

    testWidgets('T21.13 events in German, grouped with a count', (
      tester,
    ) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final anna = await seedActiveDiver(db);
      final dive = await seedDive(
        db,
        exampleDive(anna.id!).copyWith(
          events: const [
            DiveEvent(timeS: 1339, type: 'deepstop'),
            DiveEvent(timeS: 1363, type: 'deepstop'),
            DiveEvent(timeS: 2700, type: 'safetystop'),
            DiveEvent(timeS: 2723, type: 'safetystop'),
            DiveEvent(timeS: 2726, type: 'safetystop'),
          ],
        ),
      );
      await pumpTestApp(
        tester,
        db: db,
        size: const Size(400, 2400),
        location: DiveDetailScreen.pathFor(dive.id!),
      );

      expect(find.textContaining('deepstop'), findsNothing);
      expect(find.text('Tiefenstopp'), findsOneWidget);
      expect(find.text('2×'), findsOneWidget);
      expect(find.text('Sicherheitsstopp'), findsOneWidget);
      expect(find.text('3×'), findsOneWidget);
      expect(find.text('22:19'), findsOneWidget);
    });
  });
}
