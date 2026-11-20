// T9.20: ODbL notice of the site catalogue (ADR 0006, ui-spec §5.11).
import 'package:divedown/app/licenses.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

void main() {
  test('T9.20 the catalogue notice is on the licence page', () async {
    registerCatalogueLicence();

    final entries = await LicenseRegistry.licenses
        .where((e) => e.packages.contains(catalogueLicenceName))
        .toList();
    expect(entries, hasLength(1));
    final text = entries.single.paragraphs.map((p) => p.text).join('\n');
    expect(text, contains('OpenStreetMap'));
    expect(text, contains('Open Database License'));
    expect(text, contains('Wikidata'));
  });

  testWidgets('T9.20 settings open the open source licences', (tester) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await seedActiveDiver(db);
    await pumpTestApp(tester, db: db, location: '/settings');

    await tester.tap(find.text('Open-Source-Lizenzen'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });
}
