// T16.4: the database cannot be opened at start (ui-spec §4).
import 'package:divedown/app/startup_gate.dart';
import 'package:divedown/data/local/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('T16.4 error card with „Erneut versuchen“, retry opens', (
    tester,
  ) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await seedActiveDiver(db);
    var attempts = 0;
    Future<AppDatabase> open() async {
      attempts++;
      if (attempts == 1) throw const FileSystemExceptionLike();
      return db;
    }

    await tester.pumpWidget(AppStartupGate(openDatabase: open));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);

    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsNothing);
  });

  testWidgets('T16.4 the error card is German and not cut at 200 %', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      AppStartupGate(
        openDatabase: () async => throw const FileSystemExceptionLike(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('Das Logbuch konnte nicht geöffnet werden.'),
      findsOneWidget,
    );
  });
}

/// Stand-in for an I/O error such as a full disk.
class FileSystemExceptionLike implements Exception {
  const FileSystemExceptionLike();
}
