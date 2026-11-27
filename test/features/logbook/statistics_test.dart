// T39.4-T39.7: the statistics page (ui-spec §5.15).
import 'package:divedown/app/providers.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/features/logbook/dive_detail_screen.dart';
import 'package:divedown/features/logbook/logbook_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

const _statsPath = '/logbook/statistics';

/// #1 2025 Walensee 8 m, #2-#4 2026 at Elphinstone, #4 the deepest (31 m)
/// and coldest (19 °C), #3 the longest (62 min).
Future<String> _open(
  WidgetTester tester, {
  bool dives = true,
  List<DiveTank>? tanks,
  String location = LogbookScreen.path,
}) async {
  final db = newTestDatabase();
  addTearDown(db.close);
  final anna = (await seedActiveDiver(db)).id!;
  String? deepestId;
  if (dives) {
    Dive d(
      int n,
      DateTime start,
      String site,
      double depth,
      int min,
      double t,
    ) => exampleDive(
      anna,
      number: n,
      siteName: site,
      start: start,
      source: DiveSource.manual,
      tanks: tanks,
    ).copyWith(maxDepthM: depth, durationS: min * 60, minTemperatureC: t);
    await seedDive(
      db,
      d(1, DateTime.utc(2025, 7, 1, 10), 'Walensee', 8, 40, 21),
    );
    await seedDive(
      db,
      d(2, DateTime.utc(2026, 3, 1, 10), 'Elphinstone', 24, 50, 24),
    );
    await seedDive(
      db,
      d(3, DateTime.utc(2026, 3, 2, 10), 'Elphinstone', 20, 62, 23),
    );
    deepestId = (await seedDive(
      db,
      d(4, DateTime.utc(2026, 3, 3, 10), 'Elphinstone', 31, 45, 19),
    )).id;
  }
  await pumpTestApp(
    tester,
    db: db,
    size: const Size(400, 2000),
    location: location,
    overrides: [
      visitedCountriesProvider.overrideWith((ref) async => {'EG', 'CH'}),
    ],
  );
  return deepestId ?? '';
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('T39.5 a tile opens the page; overview; record opens the dive', (
    tester,
  ) async {
    final deepest = await _open(tester);

    await _tap(tester, find.text('Tauchgänge').first);
    expect(currentLocation(tester), _statsPath);
    expect(find.text('Statistik'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);

    expect(find.text('ÜBERBLICK'), findsOneWidget);
    expect(find.text('Tiefster Tauchgang'), findsOneWidget);
    expect(find.text('31,0 m'), findsOneWidget);
    expect(find.text('#4 · Elphinstone'), findsNWidgets(2)); // deepest, coldest
    expect(find.text('Längster Tauchgang'), findsOneWidget);
    expect(find.text('62 min'), findsOneWidget);
    expect(find.text('#3 · Elphinstone'), findsOneWidget);
    expect(find.text('Kältestes Wasser'), findsOneWidget);
    expect(find.text('19 °C'), findsOneWidget);
    expect(find.text('Länder'), findsOneWidget);
    expect(find.text('2'), findsWidgets);

    await _tap(tester, find.text('Tiefster Tauchgang'));
    expect(currentLocation(tester), DiveDetailScreen.pathFor(deepest));
  });

  testWidgets('T39.5 the tiles say what they open', (tester) async {
    await _open(tester);
    expect(find.bySemanticsLabel(RegExp('Statistik öffnen')), findsOneWidget);
  });

  testWidgets('T39.6 per year, spoken with the number', (tester) async {
    await _open(tester, location: _statsPath);

    expect(find.text('PRO JAHR'), findsOneWidget);
    expect(find.bySemanticsLabel('2025: 1 Tauchgang'), findsOneWidget);
    expect(find.bySemanticsLabel('2026: 3 Tauchgänge'), findsOneWidget);
  });

  testWidgets('T39.7 sites and air: without pressure the hint', (tester) async {
    await _open(
      tester,
      location: _statsPath,
      tanks: const [DiveTank(index: 0, volumeL: 12)],
    );

    expect(find.text('TAUCHPLÄTZE'), findsOneWidget);
    expect(find.text('Elphinstone'), findsOneWidget);
    expect(find.text('3×'), findsOneWidget);
    expect(find.text('Walensee'), findsOneWidget);
    expect(find.text('LUFTVERBRAUCH'), findsOneWidget);
    expect(
      find.text(
        'Für den Verlauf braucht es mindestens zwei Tauchgänge mit '
        'Flaschendruck und Flaschengröße.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('T39.7 air trend: average and latest', (tester) async {
    await _open(tester, location: _statsPath);

    // exampleDive: 12 l, 200 → 50 bar; the times and depths differ.
    expect(
      find.textContaining(RegExp(r'^Ø \d+,\d l/min · zuletzt \d+,\d l/min$')),
      findsOneWidget,
    );
  });

  testWidgets('T39.4 no dives: the empty text', (tester) async {
    await _open(tester, dives: false, location: _statsPath);

    expect(
      find.text('Noch keine Statistik. Sie entsteht mit deinen Tauchgängen.'),
      findsOneWidget,
    );
  });
}
