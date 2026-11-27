// T43.5: the shared image, 1080 × 1920 PNG without metadata (ui-spec
// §5.16, security.md G7).
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:divedown/domain/share/share_card.dart';
import 'package:divedown/features/logbook/share_card_painter.dart';
import 'package:divedown/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/png_chunks.dart';

/// Built by hand, so this test does not depend on shareCardContent.
const _content = ShareCardContent(
  siteName: 'Elphinstone',
  number: 42,
  date: '14.11.2026',
  figures: [
    ShareFigure(ShareFigureKind.depth, '18,4 m'),
    ShareFigure(ShareFigureKind.duration, '47 min'),
    ShareFigure(ShareFigureKind.water, '23 °C'),
  ],
  profile: [
    ShareProfilePoint(0, 0),
    ShareProfilePoint(600, 18.4),
    ShareProfilePoint(2400, 10),
    ShareProfilePoint(2820, 0),
  ],
  estimatedProfile: false,
  depthScaleM: 20,
  timeScaleS: 2820,
  depthTicks: [ShareTick(0, '0 m'), ShareTick(10, '10'), ShareTick(20, '20')],
  timeTicks: [
    ShareTick(0, '0'),
    ShareTick(600, '10'),
    ShareTick(1200, '20'),
    ShareTick(1800, '30'),
    ShareTick(2400, '40 min'),
  ],
);

const _primary = ui.Color(0xFF0B7A80);
const _photoColor = ui.Color(0xFFE53935);

void _expectColor(ui.Color actual, ui.Color expected) {
  expect((actual.r - expected.r).abs(), lessThan(0.02), reason: 'red');
  expect((actual.g - expected.g).abs(), lessThan(0.02), reason: 'green');
  expect((actual.b - expected.b).abs(), lessThan(0.02), reason: 'blue');
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('de'));

  testWidgets('T43.5 without photo: 1080 × 1920, primary, no metadata', (
    tester,
  ) async {
    late Uint8List png;
    late ui.Color corner;
    await tester.runAsync(() async {
      png = await renderShareImage(
        content: _content,
        layout: const ShareCardLayout(),
        l10n: l10n,
      );
      corner = await pixelAt(png, 20, 20);
    });

    expect(pngSize(png), (1080, 1920));
    final types = pngChunks(png).map((c) => c.type).toSet();
    expect(types.intersection({'eXIf', 'tEXt', 'iTXt', 'zTXt'}), isEmpty);
    _expectColor(corner, _primary);
  });

  testWidgets('T43.5 with photo: pixels from the photo, its metadata gone', (
    tester,
  ) async {
    late Uint8List png;
    late ui.Color corner;
    await tester.runAsync(() async {
      // A camera photo with location: decoded, then drawn.
      final source = withExifChunk(await solidPng(400, 300, _photoColor));
      expect(pngChunks(source).any((c) => c.type == 'eXIf'), isTrue);
      final codec = await ui.instantiateImageCodec(source);
      final photo = (await codec.getNextFrame()).image;
      png = await renderShareImage(
        content: _content,
        layout: const ShareCardLayout(),
        l10n: l10n,
        photo: photo,
      );
      corner = await pixelAt(png, 20, 20);
    });

    expect(pngSize(png), (1080, 1920));
    final types = pngChunks(png).map((c) => c.type).toSet();
    expect(types.intersection({'eXIf', 'tEXt', 'iTXt', 'zTXt'}), isEmpty);
    expect(String.fromCharCodes(png), isNot(contains('GPS')));
    _expectColor(corner, _photoColor);
  });

  testWidgets('T43.5 the card sits where the layout says', (tester) async {
    late ui.Color top;
    late ui.Color bottom;
    await tester.runAsync(() async {
      final png = await renderShareImage(
        content: _content,
        layout: const ShareCardLayout().anchoredAt(ShareCardAnchor.top),
        l10n: l10n,
      );
      // Near the top edge, inside the white card; near the bottom: colour.
      top = await pixelAt(png, 540, 100);
      bottom = await pixelAt(png, 540, 1850);
    });

    expect(top.r, greaterThan(0.9));
    _expectColor(bottom, _primary);
  });

  testWidgets('review W3: the photo fills the image, cut in the middle', (
    tester,
  ) async {
    late ui.Color left;
    late ui.Color right;
    await tester.runAsync(() async {
      // 400 × 300: green | red | blue. Cut to 9:16 in the middle only the
      // red stripe remains; stretching or a left cut would show green.
      final source = await stripedPng(300, [
        (100, const ui.Color(0xFF2E7D32)),
        (200, _photoColor),
        (100, const ui.Color(0xFF1E50DC)),
      ]);
      final codec = await ui.instantiateImageCodec(source);
      final photo = (await codec.getNextFrame()).image;
      final png = await renderShareImage(
        content: _content,
        layout: const ShareCardLayout(),
        l10n: l10n,
        photo: photo,
      );
      left = await pixelAt(png, 10, 300);
      right = await pixelAt(png, 1069, 300);
    });

    _expectColor(left, _photoColor);
    _expectColor(right, _photoColor);
  });

  test('review N7: title from site, else number, else „Tauchgang“', () {
    ShareCardContent withTitle(String? site, int? number) => ShareCardContent(
      siteName: site,
      number: number,
      date: _content.date,
      figures: _content.figures,
      profile: _content.profile,
      estimatedProfile: false,
      depthScaleM: _content.depthScaleM,
      timeScaleS: _content.timeScaleS,
      depthTicks: _content.depthTicks,
      timeTicks: _content.timeTicks,
    );
    expect(shareCardTitle(withTitle('Elphinstone', 42), l10n), 'Elphinstone');
    expect(shareCardTitle(withTitle(null, 42), l10n), 'Tauchgang #42');
    expect(shareCardTitle(withTitle(null, null), l10n), 'Tauchgang');
  });
}
