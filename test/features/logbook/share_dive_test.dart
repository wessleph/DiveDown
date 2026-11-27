// T43.8-T43.11: the page „Tauchgang teilen“ (ui-spec §5.16).
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:divedown/app/providers.dart';
import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_app_settings.dart';
import 'package:divedown/data/platform/share_photo.dart';
import 'package:divedown/domain/share/share_card.dart';
import 'package:divedown/features/logbook/dive_detail_screen.dart';
import 'package:divedown/features/logbook/share_dive_screen.dart';
import 'package:divedown/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

final _card = find.byKey(const ValueKey('share-card'));
final _size = find.byKey(const ValueKey('share-size'));
final _opacity = find.byKey(const ValueKey('share-opacity'));

class _Fakes {
  SharePhotoResult? nextPhoto;
  int photoCalls = 0;
  final rendered = <({ShareCardLayout layout, ui.Image? photo})>[];
  final shared = <(String, Uint8List)>[];
  Object? shareError;
  final log = MemoryDiagnosticLog();

  List<Override> get overrides => [
    sharePhotoLoaderProvider.overrideWithValue(() async {
      photoCalls++;
      return nextPhoto;
    }),
    shareImageRendererProvider.overrideWithValue(({
      required ShareCardContent content,
      required ShareCardLayout layout,
      required AppLocalizations l10n,
      ui.Image? photo,
    }) async {
      rendered.add((layout: layout, photo: photo));
      return Uint8List.fromList([1, 2, 3]);
    }),
    shareFileProvider.overrideWithValue((name, bytes) async {
      if (shareError != null) throw shareError!;
      shared.add((name, bytes));
    }),
  ];
}

Future<(AppDatabase, String, _Fakes)> _openShare(
  WidgetTester tester, {
  bool viaDetail = false,
}) async {
  final db = newTestDatabase();
  addTearDown(db.close);
  final anna = await seedActiveDiver(db);
  final dive = await seedDive(
    db,
    exampleDive(anna.id!, siteName: 'Elphinstone'),
  );
  final fakes = _Fakes();
  await pumpTestApp(
    tester,
    db: db,
    size: const Size(400, 1000),
    diagnosticLog: fakes.log,
    overrides: fakes.overrides,
    location: viaDetail
        ? DiveDetailScreen.pathFor(dive.id!)
        : ShareDiveScreen.pathFor(dive.id!),
  );
  return (db, dive.id!, fakes);
}

String? _cardLabel(WidgetTester tester) => tester.getSemantics(_card).label;

void main() {
  testWidgets('T43.8 the detail opens „Tauchgang teilen“ without tab bar', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final (_, id, _) = await _openShare(tester, viaDetail: true);

    await tester.tap(find.byTooltip('Tauchgang teilen'));
    await tester.pumpAndSettle();

    expect(currentLocation(tester), ShareDiveScreen.pathFor(id));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Tauchgang teilen'), findsOneWidget);
    for (final label in [
      'Foto wählen',
      'Größe',
      'Deckkraft',
      'Oben',
      'Mitte',
      'Unten',
      'Teilen',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Foto entfernen'), findsNothing);
    expect(
      find.bySemanticsLabel('Vorschau: Tauchangaben auf farbiger Fläche'),
      findsOneWidget,
    );
    expect(_cardLabel(tester), 'Tauchangaben, Position unten, Größe 100 %');
    semantics.dispose();
  });

  testWidgets('T43.9 sliders and „Oben“ change the card, it is remembered', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final (db, id, _) = await _openShare(tester);

    // Both sliders all the way to the left.
    await tester.drag(_size, const Offset(-600, 0));
    await tester.drag(_opacity, const Offset(-600, 0));
    await tester.tap(find.text('Oben'));
    await tester.pumpAndSettle();

    expect(_cardLabel(tester), 'Tauchangaben, Position oben, Größe 50 %');
    final stored = (await DriftAppSettings(db).shareCardLayout())!;
    expect(stored.scale, closeTo(0.5, 1e-9));
    expect(stored.opacity, closeTo(0, 1e-9));
    expect(stored.y, closeTo(0, 1e-9));

    // Closed and opened again: the same card.
    router(tester).go(DiveDetailScreen.pathFor(id));
    await tester.pumpAndSettle();
    router(tester).go(ShareDiveScreen.pathFor(id));
    await tester.pumpAndSettle();
    expect(_cardLabel(tester), 'Tauchangaben, Position oben, Größe 50 %');
    expect(tester.widget<Slider>(_opacity).value, closeTo(0, 1e-9));
    semantics.dispose();
  });

  testWidgets('T43.9 dragging the card keeps it inside the image', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final (db, _, _) = await _openShare(tester);
    final preview = tester.getRect(find.byKey(const ValueKey('share-preview')));

    await tester.drag(_card, const Offset(0, -3000));
    await tester.pumpAndSettle();

    expect(_cardLabel(tester), 'Tauchangaben, Position oben, Größe 100 %');
    final card = tester.getRect(_card);
    expect(card.top, greaterThanOrEqualTo(preview.top));
    expect(card.bottom, lessThanOrEqualTo(preview.bottom));
    expect((await DriftAppSettings(db).shareCardLayout())!.y, 0);
    semantics.dispose();
  });

  testWidgets('T43.10 photo chosen, removed; broken; picker closed', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final (_, _, fakes) = await _openShare(tester);
    final image = (await tester.runAsync(
      () => createTestImage(width: 40, height: 30),
    ))!;

    // Closed without a photo: nothing changes.
    fakes.nextPhoto = null;
    await tester.tap(find.text('Foto wählen'));
    await tester.pumpAndSettle();
    expect(fakes.photoCalls, 1);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Foto entfernen'), findsNothing);

    // Broken file.
    fakes.nextPhoto = const SharePhotoFailed(SharePhotoFailure.unreadable);
    await tester.tap(find.text('Foto wählen'));
    await tester.pumpAndSettle();
    expect(find.text('Das Foto konnte nicht geöffnet werden.'), findsOneWidget);
    expect(find.text('Foto entfernen'), findsNothing);

    // A photo.
    fakes.nextPhoto = SharePhoto(image);
    await tester.tap(find.text('Foto wählen'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Vorschau: Tauchangaben auf Foto'),
      findsOneWidget,
    );
    expect(find.text('Foto entfernen'), findsOneWidget);

    await tester.tap(find.text('Foto entfernen'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Vorschau: Tauchangaben auf farbiger Fläche'),
      findsOneWidget,
    );
    expect(find.text('Foto entfernen'), findsNothing);
    semantics.dispose();
  });

  testWidgets('T43.11 „Teilen“ hands the PNG to the share dialog', (
    tester,
  ) async {
    final (_, _, fakes) = await _openShare(tester);
    final image = (await tester.runAsync(
      () => createTestImage(width: 40, height: 30),
    ))!;
    fakes.nextPhoto = SharePhoto(image);
    await tester.tap(find.text('Foto wählen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oben'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Teilen'));
    await tester.pumpAndSettle();

    expect(fakes.rendered, hasLength(1));
    expect(fakes.rendered.single.photo, same(image));
    expect(fakes.rendered.single.layout.y, 0);
    expect(fakes.shared, hasLength(1));
    expect(fakes.shared.single.$1, 'DiveDown-2026-11-14-42.png');
    expect(fakes.shared.single.$2, [1, 2, 3]);
    expect(fakes.log.stored, contains('INFO app share image created'));
    // Nothing about the dive or the photo in the log.
    expect(fakes.log.stored.join(), isNot(contains('Elphinstone')));
  });

  testWidgets('T43.11 sharing fails: message, the page stays', (tester) async {
    final (_, id, fakes) = await _openShare(tester);
    fakes.shareError = Exception('no activity');

    await tester.tap(find.text('Teilen'));
    await tester.pumpAndSettle();

    expect(
      find.text('Teilen hat nicht geklappt. Versuch es noch einmal.'),
      findsOneWidget,
    );
    expect(currentLocation(tester), ShareDiveScreen.pathFor(id));
  });
}
