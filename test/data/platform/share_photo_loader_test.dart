// T43.6: the photo for a share image is read in memory and decoded scaled
// down (security.md G7).
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:divedown/data/platform/share_photo.dart';
import 'package:divedown/domain/import/file_import.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_file_import.dart';
import '../../support/png_chunks.dart';

void main() {
  testWidgets('T43.6 picker closed: null', (tester) async {
    final picker = FakeFilePicker()..next = null;
    SharePhotoResult? result = const SharePhotoFailed(
      SharePhotoFailure.unreadable,
    );
    await tester.runAsync(() async => result = await loadSharePhoto(picker));
    expect(result, isNull);
  });

  testWidgets('T43.6 over 50 MB: too large, nothing decoded', (tester) async {
    final picker = FakeFilePicker()
      ..next = const PickFailed('IMG_0001.HEIC', FileImportFailure.tooLarge);
    SharePhotoResult? result;
    await tester.runAsync(() async => result = await loadSharePhoto(picker));
    expect(result, isA<SharePhotoFailed>());
    expect((result! as SharePhotoFailed).reason, SharePhotoFailure.tooLarge);
  });

  testWidgets('T43.6 broken file: unreadable, no crash', (tester) async {
    final picker = FakeFilePicker()
      ..next = Picked(
        ImportFile('IMG_0002.JPG', Uint8List.fromList(List.filled(500, 7))),
      );
    SharePhotoResult? result;
    await tester.runAsync(() async => result = await loadSharePhoto(picker));
    expect(result, isA<SharePhotoFailed>());
    expect((result! as SharePhotoFailed).reason, SharePhotoFailure.unreadable);
  });

  testWidgets('T43.6 a large photo is decoded with the shorter side 1920', (
    tester,
  ) async {
    SharePhotoResult? result;
    await tester.runAsync(() async {
      final png = await solidPng(3000, 2400, const ui.Color(0xFF3D97A3));
      final picker = FakeFilePicker()..next = Picked(ImportFile('a.png', png));
      result = await loadSharePhoto(picker);
    });
    expect(result, isA<SharePhoto>());
    final image = (result! as SharePhoto).image;
    expect((image.width, image.height), (2400, 1920));
  });

  testWidgets('T43.6 a small photo keeps its size', (tester) async {
    SharePhotoResult? result;
    await tester.runAsync(() async {
      final png = await solidPng(400, 300, const ui.Color(0xFF3D97A3));
      result = await decodeSharePhoto(png);
    });
    final image = (result! as SharePhoto).image;
    expect((image.width, image.height), (400, 300));
  });
}
