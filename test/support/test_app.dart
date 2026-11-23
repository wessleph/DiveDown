// Shared setup for widget tests: in-memory database, seeded diver, app.
import 'package:divedown/app/app.dart';
import 'package:divedown/app/providers.dart';
import 'package:divedown/app/router.dart';
import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_app_settings.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/diagnostics/diagnostic_log.dart';
import 'package:divedown/domain/dive/diver.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

AppDatabase newTestDatabase() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

/// Creates a diver and makes it the active one, as after §5.1. Writes the
/// setting directly so this helper does not depend on [DriftAppSettings].
Future<Diver> seedActiveDiver(
  AppDatabase db, {
  String name = 'Anna',
  int firstDiveNumber = 1,
}) async {
  final diver = await DriftDiverRepository(db)
      .create(Diver(name: name, firstDiveNumber: firstDiveNumber));
  await db
      .into(db.appMeta)
      .insertOnConflictUpdate(
        AppMetaCompanion.insert(key: activeDiverKey, value: diver.id!),
      );
  return diver;
}

Future<Dive> seedDive(AppDatabase db, Dive dive) async =>
    (await DriftDiveRepository(db).save(dive)).dive;

/// The dive from the spec examples: #42 at the Thistlegorm, 18,4 m, 47 min.
Dive exampleDive(
  String diverId, {
  int? number = 42,
  String? siteName = 'SS Thistlegorm',
  DateTime? start,
  DiveSource source = DiveSource.diveComputer,
  List<DiveTank>? tanks,
  List<DiveSample>? samples,
}) {
  return Dive(
    diverId: diverId,
    number: number,
    siteName: siteName,
    source: source,
    sourceId: source == DiveSource.manual ? null : 'eon-3F7A-$number',
    start: start ?? DateTime.utc(2026, 11, 14, 10, 42),
    durationS: 2820,
    maxDepthM: 18.4,
    avgDepthM: 10,
    minTemperatureC: 21,
    waterType: WaterType.salt,
    tanks:
        tanks ??
        const [
          DiveTank(
            index: 0,
            volumeL: 12,
            startPressureBar: 200,
            endPressureBar: 50,
            gas: GasMix(o2: 0.32),
          ),
        ],
    samples:
        samples ??
        [
          for (var t = 0; t <= 2820; t += 60)
            DiveSample(timeS: t, depthM: t < 1410 ? t / 1410 * 18.4 : 10),
        ],
  );
}

/// Pumps the whole app on [db], optionally at [location].
Future<void> pumpTestApp(
  WidgetTester tester, {
  required AppDatabase db,
  Size size = const Size(400, 800),
  double textScale = 1,
  String? location,
  List<Override> overrides = const [],
  DiagnosticLog? diagnosticLog,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        diagnosticLogProvider.overrideWithValue(
          diagnosticLog ?? MemoryDiagnosticLog(),
        ),
        diagnosticHeaderProvider.overrideWith((ref) async => testHeader),
        ...overrides,
      ],
      child: const DiveDownApp(),
    ),
  );
  await tester.pumpAndSettle();
  if (location != null) {
    router(tester).go(location);
    await tester.pumpAndSettle();
  }
}

GoRouter router(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
        .read(routerProvider);

String currentLocation(WidgetTester tester) =>
    router(tester).routerDelegate.currentConfiguration.uri.toString();

/// Header used by widget tests (T10.10).
const testHeader = DiagnosticHeader(
  appVersion: '1.0.0',
  build: '1',
  os: 'Android 17 (SDK 37)',
  model: 'samsung SM-S938B',
  libdivecomputer: '0.10.0',
);

/// Diagnostic log in memory for widget tests: stores lines as given.
class MemoryDiagnosticLog implements DiagnosticLog {
  MemoryDiagnosticLog([List<String>? lines]) : stored = lines ?? [];

  final List<String> stored;

  @override
  Future<void> log(String category, LogLevel level, String message) async =>
      stored.add('${level.name.toUpperCase()} $category $message');

  @override
  Future<List<String>> lines() async => List.of(stored);

  @override
  Future<String> export(DiagnosticHeader header) async => [
    'DiveDown ${header.appVersion} (Build ${header.build})',
    ...stored,
  ].join(String.fromCharCode(10));
}
