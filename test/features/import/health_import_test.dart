// T6.8-T6.10: importing from Apple Health (ui-spec §5.10, §5.9).
import 'package:clock/clock.dart';
import 'package:divedown/app/providers.dart';
import 'package:divedown/data/local/database.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/import/health_import.dart';
import 'package:divedown/domain/import/imported_dive.dart';
import 'package:divedown/features/import/import_screen.dart';
import 'package:divedown/features/logbook/dive_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/health_fixtures.dart';
import '../../support/test_app.dart';

final _now = DateTime.utc(2026, 11, 26, 10);

class _FakeHealth implements HealthDiveSource {
  HealthAvailability answer = HealthAvailability.available;
  List<ImportedDive> dives = const [];
  int skipped = 0;
  bool fail = false;
  Object? unexpected;
  int permissionRequests = 0;
  final asked = <({DateTime from, DateTime to})>[];

  @override
  Future<HealthAvailability> availability() async => answer;

  @override
  Future<void> requestPermission() async => permissionRequests++;

  @override
  Future<HealthFetchResult> fetch({
    required DateTime from,
    required DateTime to,
  }) async {
    asked.add((from: from, to: to));
    if (fail) throw const HealthReadFailure('query_failed');
    if (unexpected case final e?) throw e;
    return HealthFetchResult(dives, skippedWithoutDepth: skipped);
  }
}

Future<(AppDatabase, String, _FakeHealth)> _open(
  WidgetTester tester, {
  HealthAvailability answer = HealthAvailability.available,
  bool earlierImport = false,
}) async {
  final db = newTestDatabase();
  addTearDown(db.close);
  final anna = await seedActiveDiver(db);
  // Before the app starts, so the logbook already holds it.
  if (earlierImport) {
    await seedDive(db, elphinstoneImported().toDive(diverId: anna.id!));
  }
  final health = _FakeHealth()..answer = answer;
  await pumpTestApp(
    tester,
    db: db,
    size: const Size(400, 1400),
    location: ImportScreen.path,
    overrides: [healthDiveSourceProvider.overrideWithValue(health)],
  );
  return (db, anna.id!, health);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

final _iOS = TargetPlatformVariant.only(TargetPlatform.iOS);

void main() {
  testWidgets('T6.8 tile opens §5.10, search shows the preview, save', (
    tester,
  ) async {
    await withClock(Clock.fixed(_now), () async {
      final (_, _, health) = await _open(tester);
      health
        ..dives = [elphinstoneImported()]
        ..skipped = 1;

      await _tap(tester, find.text('Apple Health'));
      expect(find.text('Kommt mit einem der nächsten Updates.'), findsNothing);
      expect(
        find.text(
          'DiveDown liest Tauchgänge deiner Apple Watch aus Apple Health: '
          'Tiefe, Wassertemperatur und Puls. DiveDown schreibt nichts in '
          'Apple Health.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Apple Health erfasst Tiefen nur bis ca. 40 m.'),
        findsOneWidget,
      );
      // No earlier import: only twelve months.
      expect(find.text('Letzte 12 Monate'), findsOneWidget);
      expect(find.textContaining('Seit letztem Import'), findsNothing);

      await _tap(tester, find.text('Tauchgänge suchen'));
      expect(health.permissionRequests, 1);
      expect(health.asked.single.from, DateTime.utc(2025, 11, 26, 10));
      expect(health.asked.single.to, _now);

      expect(find.text('Aus Apple Health'), findsOneWidget);
      expect(find.text('1 Training ohne Tiefe übersprungen.'), findsOneWidget);
      await _tap(tester, find.text('1 Tauchgang importieren'));

      expect(find.text('1 Tauchgang importiert'), findsOneWidget);
    });
  }, variant: _iOS);

  testWidgets('T6.8 the same workout again is already in the logbook', (
    tester,
  ) async {
    await withClock(Clock.fixed(_now), () async {
      final (_, _, health) = await _open(tester, earlierImport: true);
      health.dives = [elphinstoneImported()];

      await _tap(tester, find.text('Apple Health'));
      // Earlier import: „Seit letztem Import“ is offered and chosen.
      expect(find.text('Seit letztem Import (ab 13.11.2026)'), findsOneWidget);
      await _tap(tester, find.text('Tauchgänge suchen'));

      expect(health.asked.single.from, DateTime.utc(2026, 11, 13, 12, 42));
      expect(find.text('Bereits im Logbuch'), findsOneWidget);
    });
  }, variant: _iOS);

  testWidgets('T6.8 „Letzte 12 Monate“ can be chosen instead', (tester) async {
    await withClock(Clock.fixed(_now), () async {
      final (_, _, health) = await _open(tester, earlierImport: true);

      await _tap(tester, find.text('Apple Health'));
      expect(find.textContaining('Seit letztem Import'), findsOneWidget);
      await _tap(tester, find.text('Letzte 12 Monate'));
      await _tap(tester, find.text('Tauchgänge suchen'));

      expect(health.asked.single.from, DateTime.utc(2025, 11, 26, 10));
    });
  }, variant: _iOS);

  testWidgets('T6.9 nothing found: hints, including the access', (
    tester,
  ) async {
    await withClock(Clock.fixed(_now), () async {
      await _open(tester);
      await _tap(tester, find.text('Apple Health'));
      await _tap(tester, find.text('Tauchgänge suchen'));

      expect(
        find.text('Keine Tauchgänge im gewählten Zeitraum gefunden.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Tauchgänge werden von der Apple Watch Ultra mit der App „Tiefe“ '
          'oder einer Tauch-App aufgezeichnet.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Fehlt der Zugriff? Erlaube ihn in der Health-App → Profil → Apps '
          '→ DiveDown.',
        ),
        findsOneWidget,
      );
    });
  }, variant: _iOS);

  testWidgets('T6.9 read failure: message and „Erneut versuchen“', (
    tester,
  ) async {
    await withClock(Clock.fixed(_now), () async {
      final (_, _, health) = await _open(tester);
      health.fail = true;
      await _tap(tester, find.text('Apple Health'));
      await _tap(tester, find.text('Tauchgänge suchen'));

      expect(
        find.text('Apple Health konnte nicht gelesen werden.'),
        findsOneWidget,
      );
      health
        ..fail = false
        ..dives = [elphinstoneImported()];
      await _tap(tester, find.text('Erneut versuchen'));

      expect(find.text('Aus Apple Health'), findsOneWidget);
      expect(health.asked, hasLength(2));
    });
  }, variant: _iOS);

  testWidgets('T6.9 any other error also ends the search (review W1)', (
    tester,
  ) async {
    await withClock(Clock.fixed(_now), () async {
      final (_, _, health) = await _open(tester);
      health.unexpected = StateError('database closed');
      await _tap(tester, find.text('Apple Health'));
      await _tap(tester, find.text('Tauchgänge suchen'));

      expect(
        find.text('Apple Health konnte nicht gelesen werden.'),
        findsOneWidget,
      );
      final retry = tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text('Erneut versuchen'),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
      expect(retry.onPressed, isNotNull);
    });
  }, variant: _iOS);

  testWidgets('T6.10 iOS 15: tile disabled with a hint', (tester) async {
    await _open(tester, answer: HealthAvailability.needsNewerIos);

    expect(find.text('Apple Health'), findsOneWidget);
    expect(find.text('Benötigt iOS 16 oder neuer.'), findsOneWidget);
    // Screen readers say it is off (review N4).
    expect(
      tester.getSemantics(find.text('Apple Health')),
      isSemantics(isEnabled: false, hasEnabledState: true),
    );
    await _tap(tester, find.text('Apple Health'));
    expect(currentLocation(tester), ImportScreen.path);
    expect(find.text('Tauchgänge suchen'), findsNothing);
  }, variant: _iOS);

  testWidgets('T6.10 no Health on the device: no tile', (tester) async {
    await _open(tester, answer: HealthAvailability.unavailable);

    expect(find.text('Apple Health'), findsNothing);
  }, variant: _iOS);

  testWidgets('T6.10 Android: no tile', (tester) async {
    await _open(tester);

    expect(find.text('Apple Health'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
    'T6.11 imported dive shows „Apple Watch“ as source in the detail',
    (tester) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final anna = await seedActiveDiver(db);
      final saved = await seedDive(
        db,
        elphinstoneImported().toDive(diverId: anna.id!),
      );
      expect(saved.source, DiveSource.appleHealth);
      await pumpTestApp(
        tester,
        db: db,
        size: const Size(400, 1400),
        location: DiveDetailScreen.pathFor(saved.id!),
      );

      expect(find.textContaining('Apple Watch'), findsWidgets);
    },
    variant: _iOS,
  );
}
