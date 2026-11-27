import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/theme.dart' show appFontFamily;
import '../../domain/share/share_card.dart';
import '../../l10n/app_localizations.dart';

/// Size of the shared image (ui-spec §5.16).
const shareImageWidth = 1080;
const shareImageHeight = 1920;

// Everything below is in pixels of the 1080 × 1920 image; the card's own
// measures are at 100 % size and are scaled with the layout.
const _sideMargin = shareImageWidth * 0.06;
const _topMargin = shareImageHeight * 0.04;
const _cardWidth = shareImageWidth * 0.88;
const _pad = 32.0;
const _titleTop = _pad;
const _subtitleTop = _titleTop + 60;
const _valueTop = _subtitleTop + 64;
const _labelTop = _valueTop + 64;
const _chartTop = _labelTop + 62;
const _chartHeight = 300.0;
const _brandTop = _chartTop + _chartHeight + 8;
const _cardHeight = _brandTop + 34 + 28;
const _radius = 28.0;

// Colours of the light style „Riff“ (ui-spec §1). The card is part of an
// image, so it stays light in the dark theme too.
const _primary = Color(0xFF0B7A80);
const _raised = Color(0xFFFFFFFF);
const _onSurface = Color(0xFF13303A);
const _muted = Color(0xFF55727A);
const _temperature = Color(0xFFA35C00);
const _outline = Color(0xFFD6E7E8);
const _white = Color(0xFFFFFFFF);

/// The card's first line: the site, else „Tauchgang #42“, else
/// „Tauchgang“ (review N7).
String shareCardTitle(ShareCardContent content, AppLocalizations l10n) =>
    content.siteName ??
    (content.number == null
        ? l10n.shareCardFallbackTitleNoNumber
        : l10n.shareCardFallbackTitle(content.number!));

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
      _cardHeight * layout.scale / shareImageHeight;

  /// Where the card sits on an image or preview of [size].
  static Rect cardRect(Size size, ShareCardLayout layout) {
    final k = size.width / shareImageWidth;
    final w = _cardWidth * layout.scale;
    final h = _cardHeight * layout.scale;
    final left =
        _sideMargin + layout.x * (shareImageWidth - 2 * _sideMargin - w);
    final top = _topMargin + layout.y * (shareImageHeight - 2 * _topMargin - h);
    return Rect.fromLTWH(left * k, top * k, w * k, h * k);
  }

  /// The layout after dragging the card by [delta] on a preview of [size].
  static ShareCardLayout dragged(
    ShareCardLayout layout,
    Size size,
    Offset delta,
  ) {
    final k = size.width / shareImageWidth;
    final freeX = shareImageWidth - 2 * _sideMargin - _cardWidth * layout.scale;
    final freeY =
        shareImageHeight - 2 * _topMargin - _cardHeight * layout.scale;
    return layout.copyWith(
      x: freeX <= 0 ? layout.x : layout.x + delta.dx / k / freeX,
      y: freeY <= 0 ? layout.y : layout.y + delta.dy / k / freeY,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / shareImageWidth);
    const full = Rect.fromLTWH(
      0,
      0,
      shareImageWidth + 0.0,
      shareImageHeight + 0.0,
    );
    canvas.clipRect(full);
    _background(canvas, full);

    final rect = cardRect(
      const Size(shareImageWidth + 0.0, shareImageHeight + 0.0),
      layout,
    );
    canvas
      ..save()
      ..translate(rect.left, rect.top)
      ..scale(layout.scale);
    _card(canvas);
    canvas
      ..restore()
      ..restore();
  }

  void _background(Canvas canvas, Rect full) {
    final image = photo;
    if (image == null) {
      canvas.drawRect(full, Paint()..color = _primary);
      return;
    }
    // Fill the image, cut the middle (cover).
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    final target = full.width / full.height;
    final src = iw / ih > target
        ? Rect.fromCenter(
            center: Offset(iw / 2, ih / 2),
            width: ih * target,
            height: ih,
          )
        : Rect.fromCenter(
            center: Offset(iw / 2, ih / 2),
            width: iw,
            height: iw / target,
          );
    canvas.drawImageRect(
      image,
      src,
      full,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  void _card(Canvas canvas) {
    final light = layout.lightText;
    const card = Rect.fromLTWH(0, 0, _cardWidth, _cardHeight);
    canvas.drawRRect(
      RRect.fromRectAndRadius(card, const Radius.circular(_radius)),
      Paint()..color = _raised.withValues(alpha: layout.opacity),
    );

    final text = light ? _white : _onSurface;
    final muted = light ? _white : _muted;
    const inner = _cardWidth - 2 * _pad;

    _text(
      canvas,
      shareCardTitle(content, l10n),
      _style(46, FontWeight.w800, text, light),
      const Offset(_pad, _titleTop),
      maxWidth: inner,
    );
    _text(
      canvas,
      content.number == null
          ? content.date
          : '${content.date} · #${content.number}',
      _style(30, FontWeight.w500, muted, light),
      const Offset(_pad, _subtitleTop),
      maxWidth: inner,
    );

    final column = inner / math.max(1, content.figures.length);
    for (final (i, f) in content.figures.indexed) {
      final x = _pad + i * column;
      final color = light
          ? _white
          : switch (f.kind) {
              ShareFigureKind.depth => _primary,
              ShareFigureKind.water => _temperature,
              ShareFigureKind.duration => _onSurface,
            };
      _text(
        canvas,
        f.value,
        _style(50, FontWeight.w800, color, light),
        Offset(x, _valueTop),
        maxWidth: column - 8,
      );
      _text(
        canvas,
        switch (f.kind) {
          ShareFigureKind.depth => l10n.shareCardMax,
          ShareFigureKind.duration => l10n.shareCardDuration,
          ShareFigureKind.water => l10n.shareCardWater,
        },
        _style(28, FontWeight.w500, muted, light),
        Offset(x, _labelTop),
        maxWidth: column - 8,
      );
    }

    _chart(canvas, light);

    final brand = _layoutText(
      l10n.shareCardBrand,
      _style(26, FontWeight.w700, muted, light),
    );
    brand
      ..paint(canvas, Offset(_cardWidth - _pad - brand.width, _brandTop))
      ..dispose();
  }

  void _chart(Canvas canvas, bool light) {
    const plot = Rect.fromLTRB(
      _pad + 78,
      _chartTop + 16,
      _cardWidth - _pad - 12,
      _chartTop + _chartHeight - 48,
    );
    final axisColor = light ? _white : _muted;
    final grid = Paint()
      ..color = light ? _white.withValues(alpha: 0.45) : _outline
      ..strokeWidth = 2;
    final label = _style(30, FontWeight.w500, axisColor, light);
    double x(num t) => plot.left + t / content.timeScaleS * plot.width;
    double y(num d) => plot.top + d / content.depthScaleM * plot.height;

    for (final t in content.depthTicks) {
      canvas.drawLine(
        Offset(plot.left, y(t.position)),
        Offset(plot.right, y(t.position)),
        grid,
      );
      final p = _layoutText(t.label, label);
      p
        ..paint(
          canvas,
          Offset(plot.left - 14 - p.width, y(t.position) - p.height / 2),
        )
        ..dispose();
    }
    for (final (i, t) in content.timeTicks.indexed) {
      final p = _layoutText(t.label, label);
      final cx = x(t.position);
      final left = i == 0
          ? cx
          : math.min(cx - p.width / 2, plot.right - p.width);
      p
        ..paint(canvas, Offset(left, plot.bottom + 10))
        ..dispose();
    }

    if (content.profile.length < 2) return;
    final line = Path();
    for (final (i, p) in content.profile.indexed) {
      final o = Offset(x(p.timeS), y(p.depthM));
      i == 0 ? line.moveTo(o.dx, o.dy) : line.lineTo(o.dx, o.dy);
    }
    final curve = light ? _white : _primary;
    if (!content.estimatedProfile) {
      final area = Path.from(line)
        ..lineTo(x(content.profile.last.timeS), plot.top)
        ..lineTo(x(content.profile.first.timeS), plot.top)
        ..close();
      canvas.drawPath(
        area,
        Paint()..color = curve.withValues(alpha: light ? 0.2 : 0.18),
      );
    }
    final stroke = Paint()
      ..color = curve
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final drawn = content.estimatedProfile ? _dashed(line) : line;
    if (light) {
      canvas.drawPath(
        drawn,
        Paint()
          ..color = const Color(0x80000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    canvas.drawPath(drawn, stroke);
  }

  static Path _dashed(Path source) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 28) {
        out.addPath(metric.extractPath(d, d + 16), Offset.zero);
      }
    }
    return out;
  }

  static TextStyle _style(
    double size,
    FontWeight weight,
    Color color,
    bool light,
  ) => TextStyle(
    fontFamily: appFontFamily,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.2,
    fontFeatures: const [FontFeature.tabularFigures()],
    shadows: light
        ? const [Shadow(color: Color(0x99000000), blurRadius: 6)]
        : null,
  );

  static TextPainter _layoutText(
    String text,
    TextStyle style, {
    double maxWidth = double.infinity,
  }) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);

  static void _text(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset at, {
    required double maxWidth,
  }) => _layoutText(text, style, maxWidth: maxWidth)
    ..paint(canvas, at)
    ..dispose();

  @override
  bool shouldRepaint(ShareCardPainter old) =>
      old.content != content ||
      old.photo != photo ||
      old.layout.scale != layout.scale ||
      old.layout.opacity != layout.opacity ||
      old.layout.x != layout.x ||
      old.layout.y != layout.y;
}

/// The PNG of 1080 × 1920 px for the share dialog (T43.5). Drawn anew, so
/// none of the photo's metadata (place, time, camera) goes along.
Future<Uint8List> renderShareImage({
  required ShareCardContent content,
  required ShareCardLayout layout,
  required AppLocalizations l10n,
  ui.Image? photo,
}) async {
  final recorder = ui.PictureRecorder();
  ShareCardPainter(
    content: content,
    layout: layout,
    l10n: l10n,
    photo: photo,
  ).paint(
    Canvas(recorder),
    Size(shareImageWidth.toDouble(), shareImageHeight.toDouble()),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(shareImageWidth, shareImageHeight);
  picture.dispose();
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
