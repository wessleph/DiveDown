// T24.1-T24.4: the app icon in the Riff colours (ui-spec §1).
// T29.1-T29.4: since 2026-11-23 the motif is the mask with the clownfish
// reflected in the lens; the coral bubble of T24 is gone (T29 replaces it).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

const _surface = 0xF2F8F8;
const _primary = '#0B7A80';
const _navy = '#13303A';
const _orange = '#F26B1D';
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

    test('the foreground is a vector in primary', () {
      final fg = File('$res/drawable/ic_launcher_foreground.xml')
          .readAsStringSync()
          .toUpperCase();
      expect(fg, contains('<VECTOR'));
      expect(fg, contains(_primary));
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

  group('T29 mask with the clownfish', () {
    const res = 'android/app/src/main/res';
    const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

    test('T29.1 the SVG masters show the mask and the fish, no curve', () {
      for (final name in [
        'divedown_icon',
        'divedown_icon_small',
        'divedown_icon_android_foreground',
      ]) {
        final svg = File('assets/icon/$name.svg').readAsStringSync();
        expect(svg.toUpperCase(), contains(_navy), reason: '$name frame');
        expect(svg.toUpperCase(), contains(_orange), reason: '$name fish');
        expect(svg, isNot(contains('M170 330')), reason: '$name old curve');
      }
    });

    test('T29.2 Android vector layers: mask, lens and fish; monochrome '
        'silhouette with the lens cut out', () {
      final fg = File('$res/drawable/ic_launcher_foreground.xml')
          .readAsStringSync();
      for (final c in [_navy, _primary, _orange, '#FFFFFF']) {
        expect(fg.toUpperCase(), contains(c));
      }
      expect(fg, isNot(contains('M170,330')));
      final mono = File('$res/drawable/ic_launcher_monochrome.xml')
          .readAsStringSync();
      expect(mono, contains('android:fillType="evenOdd"'));
      expect(mono, isNot(contains('M170,330')));
    });

    test('T29.3 iOS 1024: frame navy, lens petrol, fish orange with a '
        'white stripe, strap petrol', () {
      final img = _decode(File('$ios/Icon-App-1024x1024@1x.png'));
      _near(img, 243, 576, 0x13303A, 'frame');
      _near(img, 704, 576, 0x0B7A80, 'lens');
      _near(img, 538, 531, 0xF26B1D, 'fish');
      _near(img, 496, 531, 0xFFFFFF, 'stripe');
      _near(img, 128, 550, 0x0B7A80, 'strap');
    });

    test('T29.4 small sizes still show the fish and the frame', () {
      final launcher = _decode(File('$res/mipmap-xxxhdpi/ic_launcher.png'));
      _near(launcher, 101, 100, 0xF26B1D, 'xxxhdpi fish');
      _near(launcher, 46, 108, 0x13303A, 'xxxhdpi frame');
      final small = _decode(File('$ios/Icon-App-29x29@2x.png'));
      _near(small, 30, 30, 0xF26B1D, '58 px fish');
    });
  });
}

/// Decoded 8-bit RGB(A) PNG: size and one RGB int per pixel.
({int size, List<int> rgb}) _decode(File file) {
  final b = file.readAsBytesSync();
  final data = ByteData.sublistView(b);
  final width = data.getUint32(16);
  final height = data.getUint32(20);
  final bpp = switch (b[25]) {
    2 => 3,
    6 => 4,
    _ => throw StateError('${file.path}: colour type ${b[25]}'),
  };
  final idat = BytesBuilder();
  var pos = 8;
  while (pos < b.length) {
    final len = data.getUint32(pos);
    final type = ascii.decode(b.sublist(pos + 4, pos + 8));
    if (type == 'IDAT') idat.add(b.sublist(pos + 8, pos + 8 + len));
    pos += 12 + len;
  }
  final raw = ZLibCodec().decode(idat.toBytes());
  final stride = width * bpp;
  var prev = Uint8List(stride);
  final rgb = <int>[];
  for (var y = 0; y < height; y++) {
    final filter = raw[y * (stride + 1)];
    final line = Uint8List.fromList(
      raw.sublist(y * (stride + 1) + 1, (y + 1) * (stride + 1)),
    );
    for (var i = 0; i < stride; i++) {
      final a = i >= bpp ? line[i - bpp] : 0;
      final up = prev[i];
      final c = i >= bpp ? prev[i - bpp] : 0;
      final add = switch (filter) {
        0 => 0,
        1 => a,
        2 => up,
        3 => (a + up) >> 1,
        4 => _paeth(a, up, c),
        _ => throw StateError('filter $filter'),
      };
      line[i] = (line[i] + add) & 0xFF;
    }
    for (var x = 0; x < width; x++) {
      final o = x * bpp;
      rgb.add((line[o] << 16) | (line[o + 1] << 8) | line[o + 2]);
    }
    prev = line;
  }
  expect(width, height, reason: file.path);
  return (size: width, rgb: rgb);
}

int _paeth(int a, int b, int c) {
  final p = a + b - c;
  final pa = (p - a).abs(), pb = (p - b).abs(), pc = (p - c).abs();
  if (pa <= pb && pa <= pc) return a;
  return pb <= pc ? b : c;
}

/// The pixel at ([x], [y]) is within 24 per channel of [want].
void _near(
  ({int size, List<int> rgb}) img,
  int x,
  int y,
  int want,
  String what,
) {
  final got = img.rgb[y * img.size + x];
  for (final shift in [16, 8, 0]) {
    final d = ((got >> shift) & 0xFF) - ((want >> shift) & 0xFF);
    expect(
      d.abs(),
      lessThanOrEqualTo(24),
      reason:
          '$what at ($x, $y): got #${got.toRadixString(16).padLeft(6, '0')}',
    );
  }
}
