// T40.5: conditions in the form draft (ui-spec §5.4).
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/dive/manual_dive_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime.utc(2026, 3, 1, 10);
  final dive = Dive(
    id: 'd1',
    diverId: 'anna',
    number: 3,
    source: DiveSource.manual,
    start: start,
    durationS: 2820,
    maxDepthM: 18,
    visibility: WaterVisibility.good,
    current: WaterCurrent.light,
    kinds: const {DiveKind.reef, DiveKind.night},
  );

  test('T40.5 fromDive shows the conditions, toDive keeps them', () {
    final draft = ManualDiveDraft.fromDive(dive);
    expect(draft.visibility, WaterVisibility.good);
    expect(draft.current, WaterCurrent.light);
    expect(draft.kinds, {DiveKind.reef, DiveKind.night});

    final saved = draft.toDive(diverId: 'anna', original: dive);
    expect(saved.visibility, WaterVisibility.good);
    expect(saved.current, WaterCurrent.light);
    expect(saved.kinds, {DiveKind.reef, DiveKind.night});
  });

  test('T40.5 a new draft with conditions sets them; none means empty', () {
    final draft = ManualDiveDraft(
      start: start,
      duration: '45',
      maxDepth: '12',
      visibility: WaterVisibility.poor,
      current: WaterCurrent.none,
      kinds: const {DiveKind.lake},
    );
    final saved = draft.toDive(diverId: 'anna');
    expect(saved.visibility, WaterVisibility.poor);
    expect(saved.current, WaterCurrent.none);
    expect(saved.kinds, {DiveKind.lake});

    final plain = ManualDiveDraft(
      start: start,
      duration: '45',
      maxDepth: '12',
    ).toDive(diverId: 'anna');
    expect(plain.visibility, isNull);
    expect(plain.current, isNull);
    expect(plain.kinds, isEmpty);
  });
}
