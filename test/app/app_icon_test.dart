// T24.1-T24.4: the app icon in the Riff colours (ui-spec §1: motif
// „Tiefenkurve“ stays, curve primary, bubble accent, background surface).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

const _surface = 0xF2F8F8;
const _primary = '#0B7A80';
const _accent = '#B9412A';
const _old = ['#0B1620', '#3FA3E0', '#5CB8E8', '#2A3B4A'];

/// Width, height, PNG colour type and the top-left pixel (RGB) of [file].
({int width, int height, int colorType, int topLeft}) _png(File file) {
  final b = file.readAsBytesSync();
  final data = ByteData.sublistView(b);
  expect(b.sublist(1, 4), ascii.encode('PNG'), reason: file.path);
  final width = data.getUint32(16);
  final height = data.getUint32(20);
  final colorType = b[25];
  // Concatenate IDAT chunks and inflate; for the first pixel of the first
  // row every PNG filter predicts 0, so its bytes are the colour.
  final idat = BytesBuilder();
  var pos = 8;
  while (pos < b.length) {
    final len = data.getUint32(pos);
    final type = ascii.decode(b.sublist(pos + 4, pos + 8));
    if (type == 'IDAT') idat.add(b.sublist(pos + 8, pos + 8 + len));
    pos += 12 + len;
  }
  final raw = ZLibCodec().decode(idat.toBytes());
  final topLeft = (raw[1] << 16) | (raw[2] << 8) | raw[3];
  return (width: width, height: height, colorType: colorType, topLeft: topLeft);
}

void main() {
  test('T24.1 the SVG masters use the Riff colours', () {
    for (final name in [
      'divedown_icon',
      'divedown_icon_small',
      'divedown_icon_android_foreground',
    ]) {
      final svg = File('assets/icon/$name.svg')
          .readAsStringSync()
          .toUpperCase();
      expect(svg, contains(_primary), reason: name);
      for (final c in _old) {
        expect(svg, isNot(contains(c)), reason: '$name still has $c');
      }
    }
    final master = File('assets/icon/divedown_icon.svg').readAsStringSync();
    expect(master.toUpperCase(), contains('#F2F8F8'));
    expect(master.toUpperCase(), contains(_accent));
  });

  group('T24.2 Android adaptive icon', () {
    const res = 'android/app/src/main/res';

    test('background, foreground and monochrome layers', () {
      final xml = File('$res/mipmap-anydpi-v26/ic_launcher.xml')
          .readAsStringSync();
      expect(xml, contains('<adaptive-icon'));
      expect(xml, contains('@color/ic_launcher_background'));
      expect(xml, contains('@drawable/ic_launcher_foreground'));
      expect(xml, contains('@drawable/ic_launcher_monochrome'));
      final colors = File('$res/values/ic_launcher_background.xml')
          .readAsStringSync()
          .toUpperCase();
      expect(colors, contains('#F2F8F8'));
    });

    test('the foreground is the curve in primary with the coral bubble', () {
      final fg = File('$res/drawable/ic_launcher_foreground.xml')
          .readAsStringSync()
          .toUpperCase();
      expect(fg, contains('<VECTOR'));
      expect(fg, contains(_primary));
      expect(fg, contains(_accent));
      final mono = File('$res/drawable/ic_launcher_monochrome.xml')
          .readAsStringSync();
      expect(mono, contains('<vector'));
    });

    test('T24.3 legacy launcher PNGs in every density', () {
      const sizes = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      };
      for (final e in sizes.entries) {
        final png = _png(File('$res/mipmap-${e.key}/ic_launcher.png'));
        expect(png.width, e.value, reason: e.key);
        expect(png.height, e.value, reason: e.key);
        expect(png.topLeft, _surface, reason: '${e.key} background');
      }
    });
  });

  test('T24.4 iOS: every size, no alpha channel, Riff background', () {
    const dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    final contents = jsonDecode(
      File('$dir/Contents.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final images = (contents['images']! as List).cast<Map<String, Object?>>();
    expect(images, isNotEmpty);
    for (final image in images) {
      final name = image['filename']! as String;
      final points = double.parse((image['size']! as String).split('x').first);
      final scale = int.parse((image['scale']! as String).replaceAll('x', ''));
      final png = _png(File('$dir/$name'));
      expect(png.width, (points * scale).round(), reason: name);
      expect(png.height, png.width, reason: name);
      expect(png.colorType, 2, reason: '$name must be RGB without alpha');
      expect(png.topLeft, _surface, reason: '$name background');
    }
  });
}
