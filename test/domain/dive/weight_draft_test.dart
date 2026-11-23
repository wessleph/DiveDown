// T31.1: lead and equipment in the manual entry draft (ui-spec §5.4,
// ADR 0007).
import 'package:clock/clock.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/dive/manual_dive_draft.dart';
import 'package:flutter_test/flutter_test.dart';

final _start = DateTime.utc(2026, 11, 14, 10, 42);

ManualDiveDraft _draft({String weight = '', Set<String>? equipment}) =>
    ManualDiveDraft(
      start: _start,
      duration: '47',
      maxDepth: '18,4',
      weight: weight,
      equipmentIds: equipment,
    );

void main() {
  test('T31.1 lead: empty is fine, 0-40 kg with comma or point', () {
    withClock(Clock.fixed(DateTime.utc(2026, 11, 20)), () {
      for (final ok in ['', '0', '6', '6,5', '6.5', '40']) {
        expect(_draft(weight: ok).validate(), isEmpty, reason: ok);
      }
      expect(_draft(weight: '41').validate(), {
        ManualDiveField.weight: ManualDiveError.weightOutOfRange,
      });
      expect(_draft(weight: '-1').validate(), {
        ManualDiveField.weight: ManualDiveError.weightOutOfRange,
      });
      expect(_draft(weight: 'viel').validate(), {
        ManualDiveField.weight: ManualDiveError.notANumber,
      });
    });
  });

  test('T31.1 toDive: lead in kg, equipment as selected', () {
    final dive = _draft(
      weight: '6,5',
      equipment: {'suit', 'bcd'},
    ).toDive(diverId: 'anna');
    expect(dive.weightKg, 6.5);
    expect(dive.equipmentIds, unorderedEquals(['suit', 'bcd']));

    final none = _draft().toDive(diverId: 'anna');
    expect(none.weightKg, isNull);
    // Not loaded: the repository applies the standard set (ADR 0007).
    expect(none.equipmentIds, isNull);
  });

  test('T31.1 fromDive: lead without trailing zero, equipment kept', () {
    final dive = Dive(
      id: 'd1',
      diverId: 'anna',
      source: DiveSource.diveComputer,
      start: _start,
      durationS: 2820,
      maxDepthM: 18.4,
      weightKg: 6,
      equipmentIds: const ['suit'],
    );
    final draft = ManualDiveDraft.fromDive(dive);
    expect(draft.weight, '6');
    expect(draft.equipmentIds, {'suit'});
    expect(
      ManualDiveDraft.fromDive(dive.copyWith(weightKg: 6.5)).weight,
      '6,5',
    );

    // Unchanged form: lead and equipment stay as they were.
    final again = draft.toDive(diverId: 'anna', original: dive);
    expect(again.weightKg, 6);
    expect(again.equipmentIds, ['suit']);
  });
}
