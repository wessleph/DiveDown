// Sharing a dive as an image (ui-spec §5.16, security.md G7, T43). Pure
// Dart: what the card shows and where it sits. Drawing is in
// features/logbook/share_card_painter.dart.

import 'dart:math' as math;

import '../dive/dive.dart';
import '../units/unit_formatter.dart';

const _units = UnitFormatter.metric();

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
ShareCardContent shareCardContent(Dive dive) {
  final site = dive.siteName?.trim();
  final start = dive.start;
  String two(int v) => v.toString().padLeft(2, '0');
  final water = dive.minTemperatureC;

  final samples = dive.samples;
  final estimated = samples.length < 2;
  final profile = estimated
      ? [
          const ShareProfilePoint(0, 0),
          ShareProfilePoint(math.min(60, dive.durationS ~/ 4), dive.maxDepthM),
          ShareProfilePoint(
            math.max(dive.durationS - 180, dive.durationS * 3 ~/ 4),
            dive.maxDepthM,
          ),
          ShareProfilePoint(dive.durationS, 0),
        ]
      : [for (final s in samples) ShareProfilePoint(s.timeS, s.depthM)];
  final deepest = profile.fold<double>(0, (m, p) => math.max(m, p.depthM));

  // Depth axis as in the profile chart (ui-spec §6).
  final maxDepth = math.max(5.0, math.max(dive.maxDepthM, deepest));
  final depthStep = maxDepth <= 15 ? 5.0 : 10.0;
  final depthScale = (maxDepth / depthStep).ceil() * depthStep;
  final depthTicks = [
    for (var d = 0.0; d <= depthScale + 0.01; d += depthStep)
      ShareTick(d, d == 0 ? '0 m' : '${d.round()}'),
  ];

  // Time axis: the smallest round step that gives at most five marks. At
  // least two minutes long, so a very short dive still gets three marks
  // and nothing is divided by zero (review N4).
  final end = math.max(
    120,
    estimated ? dive.durationS : math.max(dive.durationS, samples.last.timeS),
  );
  final minutes = end / 60;
  const steps = [1, 2, 5, 10, 15, 20, 30, 60, 120];
  final step = steps.firstWhere(
    (m) => (minutes / m).floor() + 1 <= 5,
    orElse: () => steps.last,
  );
  final marks = [for (var m = 0; m * 60 <= end; m += step) m];
  final timeTicks = [
    for (final (i, m) in marks.indexed)
      ShareTick(m * 60.0, i == marks.length - 1 && i > 0 ? '$m min' : '$m'),
  ];

  return ShareCardContent(
    siteName: site == null || site.isEmpty ? null : site,
    number: dive.number,
    date: '${two(start.day)}.${two(start.month)}.${start.year}',
    figures: [
      ShareFigure(ShareFigureKind.depth, _units.depth(dive.maxDepthM)),
      ShareFigure(ShareFigureKind.duration, _units.duration(dive.durationS)),
      if (water != null)
        ShareFigure(ShareFigureKind.water, _units.temperature(water)),
    ],
    profile: profile,
    estimatedProfile: estimated,
    depthScaleM: depthScale,
    timeScaleS: end,
    depthTicks: depthTicks,
    timeTicks: timeTicks,
  );
}

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

  ShareCardLayout._clamped({
    required double scale,
    required double opacity,
    required double x,
    required double y,
  }) : scale = scale.clamp(minScale, maxScale),
       opacity = opacity.clamp(0.0, 1.0),
       x = x.clamp(0.0, 1.0),
       y = y.clamp(0.0, 1.0);

  /// 0,5–1,0 of the full card width (88 % of the image).
  final double scale;

  /// Opacity of the card's white background, 0–1.
  final double opacity;
  final double x;
  final double y;

  static const minScale = 0.5;
  static const maxScale = 1.0;

  /// Below 50 % the text, axes and curve turn white (ui-spec §5.16).
  bool get lightText => opacity < 0.5;

  /// Values outside their range are brought back into it.
  ShareCardLayout copyWith({
    double? scale,
    double? opacity,
    double? x,
    double? y,
  }) => ShareCardLayout._clamped(
    scale: scale ?? this.scale,
    opacity: opacity ?? this.opacity,
    x: x ?? this.x,
    y: y ?? this.y,
  );

  /// „Oben“, „Mitte“, „Unten“: centred horizontally.
  ShareCardLayout anchoredAt(ShareCardAnchor anchor) => copyWith(
    x: 0.5,
    y: switch (anchor) {
      ShareCardAnchor.top => 0,
      ShareCardAnchor.middle => 0.5,
      ShareCardAnchor.bottom => 1,
    },
  );

  /// Kept in `app_meta` (`share_card`).
  String encode() => [scale, opacity, x, y].join(',');

  /// The stored text; anything unreadable gives the default.
  static ShareCardLayout decode(String? text) {
    final parts = (text ?? '').split(',').map(double.tryParse).toList();
    if (parts.length != 4 || parts.contains(null)) {
      return const ShareCardLayout();
    }
    return ShareCardLayout._clamped(
      scale: parts[0]!,
      opacity: parts[1]!,
      x: parts[2]!,
      y: parts[3]!,
    );
  }
}
