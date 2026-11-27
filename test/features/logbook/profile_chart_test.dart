// T22.7-T22.13: the tappable profile and the value panel (ui-spec §6).
//
// Contract for the widgets: the drawing area that maps 0 … duration onto
// its full width has the key `profile-plot`; the value panel under it has
// the key `profile-values`.
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/features/logbook/dive_detail_screen.dart';
import 'package:divedown/features/logbook/manual_dive_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

final _plot = find.byKey(const ValueKey('profile-plot'));
final _values = find.byKey(const ValueKey('profile-values'));

Finder _inValues(Finder f) => find.descendant(of: _values, matching: f);

Future<Dive> _open(
  WidgetTester tester,
  Dive Function(String diverId) dive,
) async {
  final db = newTestDatabase();
  addTearDown(db.close);
  final anna = await seedActiveDiver(db);
  final saved = await seedDive(db, dive(anna.id!));
  await pumpTestApp(
    tester,
    db: db,
    size: const Size(400, 2000),
    location: DiveDetailScreen.pathFor(saved.id!),
  );
  return saved;
}

/// Taps the plot at [fraction] of its width (0 = start, 1 = end).
Future<void> _tapAt(WidgetTester tester, double fraction) async {
  final rect = tester.getRect(_plot);
  await tester.tapAt(Offset(rect.left + rect.width * fraction, rect.center.dy));
  await tester.pumpAndSettle();
}

/// The example dive with pressure samples (measured).
Dive _measured(String id) => exampleDive(
  id,
  samples: [
    for (var t = 0; t <= 2820; t += 60)
      DiveSample(
        timeS: t,
        depthM: t < 1410 ? t / 1410 * 18.4 : 10,
        temperatureC: 21,
        pressures: [
          TankPressure(tankIndex: 0, pressureBar: 200 - t / 2820 * 150),
        ],
      ),
  ],
);

void main() {
  testWidgets('T22.7 panel starts at the deepest point', (tester) async {
    await _open(tester, exampleDive);

    expect(_values, findsOneWidget);
    expect(_inValues(find.text('Zeit')), findsOneWidget);
    // Minute samples: the deepest one is 23:00 with 1380 / 1410 × 18,4 m.
    expect(_inValues(find.text('23:00')), findsOneWidget);
    expect(_inValues(find.text('18,0 m')), findsOneWidget);
  });

  testWidgets('T22.8 tapping shows the values of that moment', (tester) async {
    await _open(tester, exampleDive);

    await _tapAt(tester, 0.25); // 705 s → nearest sample 12:00
    expect(_inValues(find.text('12:00')), findsOneWidget);
    expect(_inValues(find.text('9,4 m')), findsOneWidget);
    expect(_inValues(find.text('Umgebung')), findsOneWidget);
    expect(_inValues(find.text('1,9 bar')), findsOneWidget); // 1 + 9,4 × 0,1005

    await _tapAt(tester, 1.0);
    expect(_inValues(find.text('47:00')), findsOneWidget);
  });

  testWidgets('T22.8 dragging moves the moment along', (tester) async {
    await _open(tester, exampleDive);
    final rect = tester.getRect(_plot);
    final gesture = await tester.startGesture(
      Offset(rect.left + rect.width * 0.25, rect.center.dy),
    );
    await gesture.moveTo(Offset(rect.left + rect.width * 0.75, rect.center.dy));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_inValues(find.text('35:00')), findsOneWidget); // 2115 s → 35:00
    expect(_inValues(find.text('10,0 m')), findsOneWidget);
  });

  testWidgets('T22.9 estimated air: left in the tank and used so far', (
    tester,
  ) async {
    await _open(tester, exampleDive);
    await _tapAt(tester, 1.0);

    expect(_inValues(find.text('Noch in der Flasche')), findsOneWidget);
    expect(_inValues(find.text('ca. 50 bar')), findsOneWidget);
    expect(_inValues(find.text('Bisher verbraucht')), findsOneWidget);
    expect(_inValues(find.text('ca. 1.800 l')), findsOneWidget);
    expect(
      _inValues(
        find.text(
          'Luftwerte geschätzt aus Start- und Enddruck (200 → 50 bar, 12 l)',
        ),
      ),
      findsOneWidget,
    );
    expect(_inValues(find.text('Luft jetzt')), findsOneWidget);
    expect(
      find.text(
        'Werte vom Tauchcomputer, nur zur Anzeige. '
        'Luft ist geschätzt, weil kein Flaschendruck aufgezeichnet wurde.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'T22.10 measured air has no estimate note, offers Luftverbrauch',
    (tester) async {
      await _open(tester, _measured);
      await _tapAt(tester, 1.0);

      expect(_inValues(find.text('ca. 50 bar')), findsNothing);
      expect(_inValues(find.text('50 bar')), findsOneWidget);
      expect(_inValues(find.textContaining('geschätzt')), findsNothing);
      // Renamed in T37: „Luft“ → „Flaschendruck“, „SAC“ → „Luftverbrauch“.
      expect(find.widgetWithText(FilterChip, 'Flaschendruck'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Luftverbrauch'), findsOneWidget);
      expect(
        find.text('Werte vom Tauchcomputer, nur zur Anzeige.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('T22.11 layer chips; no Luftverbrauch for an estimate', (
    tester,
  ) async {
    await _open(tester, exampleDive);

    expect(find.widgetWithText(FilterChip, 'Temperatur'), findsOneWidget);
    expect(
      find.widgetWithText(FilterChip, 'Flaschendruck (geschätzt)'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilterChip, 'Luftverbrauch'), findsNothing);

    final temp = find.widgetWithText(FilterChip, 'Temperatur');
    final before = tester.widget<FilterChip>(temp).selected;
    await tester.tap(temp);
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(temp).selected, !before);
  });

  group('T22.12 without air data the panel says what is missing', () {
    testWidgets('no pressure: link to enter start and end pressure', (
      tester,
    ) async {
      final dive = await _open(
        tester,
        (id) => exampleDive(id, tanks: const [DiveTank(index: 0, volumeL: 12)]),
      );

      await tester.tap(_inValues(find.text('Start- und Enddruck eintragen')));
      await tester.pumpAndSettle();
      expect(currentLocation(tester), ManualDiveScreen.editPathFor(dive.id!));
    });

    testWidgets('no tank size: link to enter it', (tester) async {
      await _open(
        tester,
        (id) => exampleDive(
          id,
          tanks: const [
            DiveTank(index: 0, startPressureBar: 200, endPressureBar: 50),
          ],
        ),
      );

      expect(_inValues(find.text('Flaschengröße eintragen')), findsOneWidget);
    });
  });

  testWidgets('T22.13 summary for screen readers and a minute table', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _open(tester, exampleDive);

    expect(
      find.bySemanticsLabel(
        'Tiefenprofil: max. 18,4 m nach 23 min, Dauer 47 min',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Als Tabelle anzeigen'));
    await tester.pumpAndSettle();
    expect(find.text('0:00'), findsWidgets);
    expect(find.text('47:00'), findsWidgets);
    handle.dispose();
  });

  group('T37 chips: Temperatur, Flaschendruck, Luftverbrauch, Puls', () {
    List<String> chips(WidgetTester tester) => [
      for (final c in tester.widgetList<FilterChip>(find.byType(FilterChip)))
        (c.label as Text).data!,
    ];

    testWidgets('measured: no NDL, in this order', (tester) async {
      await _open(
        tester,
        (id) => exampleDive(
          id,
          samples: [
            for (var t = 0; t <= 2820; t += 60)
              DiveSample(
                timeS: t,
                depthM: t < 1410 ? t / 1410 * 18.4 : 10,
                temperatureC: 21,
                ndlS: 1200,
                pressures: [
                  TankPressure(tankIndex: 0, pressureBar: 200 - t / 20),
                ],
              ),
          ],
        ),
      );

      expect(chips(tester), ['Temperatur', 'Flaschendruck', 'Luftverbrauch']);
      // The NDL stays in the value panel when the computer sends it.
      expect(_inValues(find.text('NDL')), findsOneWidget);
    });

    testWidgets('a third axis turns the oldest off, with the new names', (
      tester,
    ) async {
      await _open(tester, _measured);

      await tester.tap(find.widgetWithText(FilterChip, 'Luftverbrauch'));
      await tester.pump();

      expect(
        find.text(
          'Höchstens zwei Werte mit eigener Achse. „Temperatur“ ist jetzt aus.',
        ),
        findsOneWidget,
      );
      final selected = [
        for (final c in tester.widgetList<FilterChip>(find.byType(FilterChip)))
          if (c.selected) (c.label as Text).data!,
      ];
      expect(selected, ['Flaschendruck', 'Luftverbrauch']);
    });
  });
}
