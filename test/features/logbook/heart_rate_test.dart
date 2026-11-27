// T6.11: heart rate from the Apple Watch in the profile (ui-spec §6).
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/features/logbook/dive_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/health_fixtures.dart';
import '../../support/test_app.dart';

final _values = find.byKey(const ValueKey('profile-values'));

Finder _chip(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(FilterChip));

Future<void> _open(WidgetTester tester, Dive Function(String) dive) async {
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
}

void main() {
  testWidgets('T6.11 Apple Watch dive: „Puls“ chip on, value in the panel', (
    tester,
  ) async {
    await _open(tester, (id) => elphinstoneImported().toDive(diverId: id));

    expect(_chip('Puls'), findsOneWidget);
    expect(tester.widget<FilterChip>(_chip('Puls')).selected, isTrue);
    // No pressure from the watch: no air chip.
    expect(_chip('Flaschendruck'), findsNothing);
    expect(_chip('Flaschendruck (geschätzt)'), findsNothing);
    // The panel starts at the deepest point, 5:00 with 95 /min.
    expect(
      find.descendant(of: _values, matching: find.text('Puls')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _values, matching: find.text('95 /min')),
      findsOneWidget,
    );

    await tester.tap(_chip('Puls'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(_chip('Puls')).selected, isFalse);
  });

  testWidgets('T6.11 dive without heart rate: no chip', (tester) async {
    await _open(tester, exampleDive);

    expect(_chip('Puls'), findsNothing);
    expect(
      find.descendant(of: _values, matching: find.text('Puls')),
      findsNothing,
    );
  });
}
