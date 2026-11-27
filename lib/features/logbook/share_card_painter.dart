import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/share/share_card.dart';
import '../../l10n/app_localizations.dart';

/// Size of the shared image (ui-spec §5.16).
const shareImageWidth = 1080;
const shareImageHeight = 1920;

/// Draws photo (or colour) and card. The same painter draws the preview on
/// the screen and the shared image, so both always look the same.
class ShareCardPainter extends CustomPainter {
  ShareCardPainter({
    required this.content,
    required this.layout,
    required this.l10n,
    this.photo,
  });

  final ShareCardContent content;
  final ShareCardLayout layout;
  final AppLocalizations l10n;
  final ui.Image? photo;

  /// Height of the card at [layout] as a fraction of the image height.
  static double cardHeightFraction(ShareCardLayout layout) =>
      throw UnimplementedError('cardHeightFraction');

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(ShareCardPainter old) => true;
}

/// The PNG of 1080 × 1920 px for the share dialog (T43.5).
Future<Uint8List> renderShareImage({
  required ShareCardContent content,
  required ShareCardLayout layout,
  required AppLocalizations l10n,
  ui.Image? photo,
}) => throw UnimplementedError('renderShareImage');
