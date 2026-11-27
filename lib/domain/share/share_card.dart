// Sharing a dive as an image (ui-spec §5.16, security.md G7, T43). Pure
// Dart: what the card shows and where it sits. Drawing is in
// features/logbook/share_card_painter.dart.

import '../dive/dive.dart';

/// The three figures on the card, in this order.
enum ShareFigureKind { depth, duration, water }

class ShareFigure {
  const ShareFigure(this.kind, this.value);

  final ShareFigureKind kind;

  /// Formatted with unit, e.g. `18,4 m`.
  final String value;
}

/// A mark on an axis: [position] in metres (depth) or seconds (time).
class ShareTick {
  const ShareTick(this.position, this.label);

  final double position;
  final String label;
}

/// One point of the profile on the card.
class ShareProfilePoint {
  const ShareProfilePoint(this.timeS, this.depthM);

  final int timeS;
  final double depthM;
}

/// What the card shows. Only the fields of the positive list in
/// security.md G7; nothing else of the dive reaches the image.
class ShareCardContent {
  const ShareCardContent({
    required this.siteName,
    required this.number,
    required this.date,
    required this.figures,
    required this.profile,
    required this.estimatedProfile,
    required this.depthScaleM,
    required this.timeScaleS,
    required this.depthTicks,
    required this.timeTicks,
  });

  /// Null when the dive has no site; the card then says „Tauchgang #42“.
  final String? siteName;
  final int? number;

  /// `14.11.2026`
  final String date;
  final List<ShareFigure> figures;
  final List<ShareProfilePoint> profile;

  /// No samples: rectangle from depth and duration, drawn dashed.
  final bool estimatedProfile;

  /// Bottom of the depth axis, a multiple of the tick step.
  final double depthScaleM;

  /// End of the time axis: the dive's duration.
  final int timeScaleS;
  final List<ShareTick> depthTicks;
  final List<ShareTick> timeTicks;

  /// Every text the card can show from the dive (for the privacy test).
  Iterable<String> get texts => [
    ?siteName,
    if (number != null) '#$number',
    date,
    for (final f in figures) f.value,
    for (final t in depthTicks) t.label,
    for (final t in timeTicks) t.label,
  ];
}

/// The card for [dive] (T43.1, T43.2).
ShareCardContent shareCardContent(Dive dive) =>
    throw UnimplementedError('shareCardContent');

/// Quick positions of the card (ui-spec §5.16).
enum ShareCardAnchor { top, middle, bottom }

/// Size, opacity and position of the card on the image (T43.3).
///
/// The position is a fraction of the free space inside the image's margin:
/// [x] 0 = left, 1 = right, [y] 0 = top, 1 = bottom. Whatever the size,
/// the card thus stays inside the image.
class ShareCardLayout {
  const ShareCardLayout({
    this.scale = 1,
    this.opacity = 0.95,
    this.x = 0.5,
    this.y = 1,
  });

  /// 0,5–1,0 of the full card width (88 % of the image).
  final double scale;

  /// Opacity of the card's white background, 0–1.
  final double opacity;
  final double x;
  final double y;

  static const minScale = 0.5;
  static const maxScale = 1.0;

  /// Below 50 % the text, axes and curve turn white (ui-spec §5.16).
  bool get lightText => throw UnimplementedError('lightText');

  /// Values outside their range are brought back into it.
  ShareCardLayout copyWith({
    double? scale,
    double? opacity,
    double? x,
    double? y,
  }) => throw UnimplementedError('copyWith');

  /// „Oben“, „Mitte“, „Unten“: centred horizontally.
  ShareCardLayout anchoredAt(ShareCardAnchor anchor) =>
      throw UnimplementedError('anchoredAt');

  /// Kept in `app_meta` (`share_card`).
  String encode() => throw UnimplementedError('encode');

  /// The stored text; anything unreadable gives the default.
  static ShareCardLayout decode(String? text) =>
      throw UnimplementedError('decode');
}
