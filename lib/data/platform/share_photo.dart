import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../domain/import/file_import.dart';

/// Largest photo read for a share image (security.md G7).
const maxSharePhotoBytes = 50 * 1024 * 1024;

/// The shorter side of a photo is decoded to at most this many pixels: the
/// image is 1080 × 1920, more is memory without use (security.md G7).
const maxSharePhotoShortSide = 1920;

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
Future<SharePhotoResult?> loadSharePhoto(ImportFilePicker picker) =>
    throw UnimplementedError('loadSharePhoto');

/// Decodes [bytes], the shorter side at most [maxSharePhotoShortSide].
Future<SharePhotoResult> decodeSharePhoto(Uint8List bytes) =>
    throw UnimplementedError('decodeSharePhoto');
