import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../domain/import/file_import.dart';

/// Largest photo read for a share image (security.md G7).
const maxSharePhotoBytes = 50 * 1024 * 1024;

/// The shorter side of a photo is decoded to at most this many pixels: the
/// image is 1080 × 1920, more is memory without use (security.md G7).
const maxSharePhotoShortSide = 1920;

/// The longer side at most this, so a panorama stays small too (review N1).
const maxSharePhotoLongSide = 4096;

/// Why a photo could not be used (ui-spec §5.16).
enum SharePhotoFailure { tooLarge, unreadable }

sealed class SharePhotoResult {
  const SharePhotoResult();
}

class SharePhoto extends SharePhotoResult {
  const SharePhoto(this.image);

  final ui.Image image;
}

class SharePhotoFailed extends SharePhotoResult {
  const SharePhotoFailed(this.reason);

  final SharePhotoFailure reason;
}

/// Lets the diver pick a photo with [picker] and decodes it, scaled down
/// (T43.6). Null when the picker was closed without a photo.
Future<SharePhotoResult?> loadSharePhoto(ImportFilePicker picker) async {
  final picked = await picker.pick();
  return switch (picked) {
    null => null,
    PickFailed(reason: FileImportFailure.tooLarge) => const SharePhotoFailed(
      SharePhotoFailure.tooLarge,
    ),
    PickFailed() => const SharePhotoFailed(SharePhotoFailure.unreadable),
    Picked(:final file) => decodeSharePhoto(file.bytes),
  };
}

/// Decodes [bytes], the shorter side at most [maxSharePhotoShortSide].
Future<SharePhotoResult> decodeSharePhoto(Uint8List bytes) async {
  if (bytes.length > maxSharePhotoBytes) {
    return const SharePhotoFailed(SharePhotoFailure.tooLarge);
  }
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final short = math.min(descriptor.width, descriptor.height);
    final long = math.max(descriptor.width, descriptor.height);
    // One factor for both sides keeps the shape, whichever way the codec
    // turns the photo by its EXIF orientation.
    final factor = math.min(
      1.0,
      math.min(maxSharePhotoShortSide / short, maxSharePhotoLongSide / long),
    );
    codec = await descriptor.instantiateCodec(
      targetWidth: (descriptor.width * factor).round(),
      targetHeight: (descriptor.height * factor).round(),
    );
    final frame = await codec.getNextFrame();
    return SharePhoto(frame.image);
  } catch (_) {
    // Any failure of a foreign file is „unreadable“, never a crash (N2).
    return const SharePhotoFailed(SharePhotoFailure.unreadable);
  } finally {
    codec?.dispose();
    descriptor?.dispose();
    buffer?.dispose();
  }
}
