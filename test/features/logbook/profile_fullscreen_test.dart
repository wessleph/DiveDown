// T27.2-T27.5: the profile in full screen with zoom (ui-spec §6, §8).
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/features/logbook/dive_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

final _plot = find.byKey(const ValueKey('profile-plot'));
final _values = find.byKey(const ValueKey('profile-values'));
final _range = find.byKey(const ValueKey('profile-range'));
final _fullscreen = find.byKey(const ValueKey('profile-fullscreen'));

/// The example dive with a sample every minute, 0 … 47 min.
Dive _withSamples(String id) => exampleDive(
  id,
  samples: [
    for (var t = 0; t <= 2820; t += 60)
      DiveSample(
        timeS: t,
        depthM: t < 1410 ? t / 1410 * 18.4 : 10,
        temperatureC: 21,
      ),
  ],
);

/// Calls to SystemChrome (orientation, system bars).
final _system = <MethodCall>[];

Future<void> _open(
  WidgetTester tester,
  Dive Function(String diverId) dive,
) async {
  _system.clear();
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      _system.add(call);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  final db = newTestDatabase();
  addTearDown(db.close);
  final anna = await seedActiveDiver(db);
  final saved = await seedDive(db, dive(anna.id!));
  await pumpTestApp(
    tester,
    db: db,
    size: const Size(400, 2000),
    location: DiveDetailScreen.pathFor(saved.id!),
  );
}

Future<void> _openFullscreen(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Vollbild'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Vollbild'));
  await tester.pumpAndSettle();
}

List<Object?> _calls(String method) => [
  for (final c in _system)
    if (c.method == method) c.arguments,
];

/// Spreads two fingers horizontally around the middle of the plot.
Future<void> _pinchOut(WidgetTester tester) async {
  final c = tester.getCenter(_plot);
  final a = await tester.startGesture(c - const Offset(20, 0), pointer: 1);
  final b = await tester.startGesture(c + const Offset(20, 0), pointer: 2);
  await tester.pump();
  for (var i = 0; i < 6; i++) {
    await a.moveBy(const Offset(-10, 0));
    await b.moveBy(const Offset(10, 0));
    await tester.pump();
  }
  await a.up();
  await b.up();
  await tester.pumpAndSettle();
}

/// Seconds of „m:ss“ texts in [text], in order.
List<int> _clock(String text) => [
  for (final m in RegExp(r'(\d+):(\d\d)').allMatches(text))
    int.parse(m[1]!) * 60 + int.parse(m[2]!),
];

String _textOf(WidgetTester tester, Finder f) => [
  for (final t in tester.widgetList<Text>(
    // matchRoot: the range is a Text itself.
    find.descendant(of: f, matching: find.byType(Text), matchRoot: true),
  ))
    t.data ?? t.textSpan?.toPlainText() ?? '',
].join(' ');

void main() {
  testWidgets('T27.2 „Vollbild“ opens the profile alone, in landscape '
      'without system bars; „Schließen“ restores both', (tester) async {
    await _open(tester, _withSamples);
    await _openFullscreen(tester);

    expect(_fullscreen, findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(_plot, findsOneWidget);
    expect(_values, findsOneWidget);
    expect(find.textContaining('#42'), findsOneWidget);
    expect(_calls('SystemChrome.setPreferredOrientations').last, [
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);
    expect(
      _calls('SystemChrome.setEnabledSystemUIMode').last,
      'SystemUiMode.immersiveSticky',
    );

    await tester.tap(find.byTooltip('Schließen'));
    await tester.pumpAndSettle();

    expect(_fullscreen, findsNothing);
    expect(find.text('Vollbild'), findsOneWidget);
    expect(_calls('SystemChrome.setPreferredOrientations').last, isEmpty);
    expect(
      _calls('SystemChrome.setEnabledSystemUIMode').last,
      'SystemUiMode.edgeToEdge',
    );
  });

  testWidgets('T27.3 pinch zooms the time axis and shows the range, a '
      'double tap shows the whole dive again', (tester) async {
    await _open(tester, _withSamples);
    await _openFullscreen(tester);
    expect(_range, findsNothing, reason: 'whole dive, nothing to say');

    await _pinchOut(tester);

    expect(_range, findsOneWidget);
    final range = _clock(_textOf(tester, _range));
    expect(range, hasLength(2));
    expect(range[0], greaterThan(0));
    expect(range[1], lessThan(2820));

    await tester.tap(_plot);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(_plot);
    await tester.pumpAndSettle();

    expect(_range, findsNothing);
  });

  testWidgets('T27.4 a tap in the zoomed plot picks a moment inside the '
      'range', (tester) async {
    await _open(tester, _withSamples);
    await _openFullscreen(tester);
    await _pinchOut(tester);
    final range = _clock(_textOf(tester, _range));

    final rect = tester.getRect(_plot);
    await tester.tapAt(Offset(rect.left + 2, rect.center.dy));
    await tester.pumpAndSettle();

    final picked = _clock(_textOf(tester, _values)).first;
    expect(picked, greaterThanOrEqualTo(range[0] - 60));
    expect(picked, lessThanOrEqualTo(range[0] + 60));
  });

  testWidgets('T27.5 without samples there is no „Vollbild“', (tester) async {
    await _open(tester, (id) => exampleDive(id, samples: const []));

    expect(find.text('Vollbild'), findsNothing);
  });
}
