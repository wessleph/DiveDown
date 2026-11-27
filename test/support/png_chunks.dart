// Reads the chunk list of a PNG (T43.5, security.md G7) and builds test
// images with the engine.
import 'dart:typed_data';
import 'dart:ui' as ui;

class PngChunk {
  const PngChunk(this.type, this.data);

  final String type;
  final Uint8List data;
}

const _signature = [137, 80, 78, 71, 13, 10, 26, 10];

List<PngChunk> pngChunks(Uint8List png) {
  for (var i = 0; i < _signature.length; i++) {
    if (png[i] != _signature[i]) throw const FormatException('not a PNG');
  }
  final view = ByteData.sublistView(png);
  final chunks = <PngChunk>[];
  var at = 8;
  while (at + 8 <= png.length) {
    final length = view.getUint32(at);
    final type = String.fromCharCodes(png.sublist(at + 4, at + 8));
    chunks.add(PngChunk(type, png.sublist(at + 8, at + 8 + length)));
    at += 12 + length;
  }
  return chunks;
}

/// Width and height from the IHDR chunk.
(int, int) pngSize(Uint8List png) {
  final ihdr = pngChunks(png).firstWhere((c) => c.type == 'IHDR');
  final v = ByteData.sublistView(ihdr.data);
  return (v.getUint32(0), v.getUint32(4));
}

/// A PNG of one [color], made by the engine; call inside `runAsync`.
Future<Uint8List> solidPng(int width, int height, ui.Color color) async {
  final image = await solidImage(width, height, color);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<ui.Image> solidImage(int width, int height, ui.Color color) {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = color,
  );
  return recorder.endRecording().toImage(width, height);
}

/// [png] with an `eXIf` chunk (GPS-like bytes) right after IHDR, as cameras
/// write it.
Uint8List withExifChunk(Uint8List png) {
  final chunks = pngChunks(png);
  final out = BytesBuilder()..add(_signature);
  void write(String type, List<int> data) {
    final header = ByteData(8)..setUint32(0, data.length);
    final typeBytes = type.codeUnits;
    for (var i = 0; i < 4; i++) {
      header.setUint8(4 + i, typeBytes[i]);
    }
    out
      ..add(header.buffer.asUint8List())
      ..add(data);
    final crc = ByteData(4)..setUint32(0, _crc32([...typeBytes, ...data]));
    out.add(crc.buffer.asUint8List());
  }

  for (final c in chunks) {
    write(c.type, c.data);
    if (c.type == 'IHDR') {
      write('eXIf', 'MM\x00\x2a GPS 25.31417 34.86139'.codeUnits);
    }
  }
  return out.toBytes();
}

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc ^= b;
    for (var k = 0; k < 8; k++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}

/// The colour of one pixel of [png]; call inside `runAsync`.
Future<ui.Color> pixelAt(Uint8List png, int x, int y) async {
  final codec = await ui.instantiateImageCodec(png);
  final image = (await codec.getNextFrame()).image;
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final i = (y * image.width + x) * 4;
  final color = ui.Color.fromARGB(
    data.getUint8(i + 3),
    data.getUint8(i),
    data.getUint8(i + 1),
    data.getUint8(i + 2),
  );
  image.dispose();
  return color;
}
