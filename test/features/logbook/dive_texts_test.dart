// T21.9, T21.10: German event texts and grouping (ui-spec §5.3).
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/features/logbook/dive_texts.dart';
import 'package:divedown/l10n/app_localizations_de.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsDe();

  test('T21.9 every libdivecomputer event type has a German text', () {
    const expected = {
      'deepstop': 'Tiefenstopp',
      'safetystop': 'Sicherheitsstopp',
      'safetystop_voluntary': 'Sicherheitsstopp',
      'safetystop_mandatory': 'Sicherheitsstopp',
      'ceiling_safetystop': 'Sicherheitsstopp',
      'ascent': 'Aufstieg zu schnell',
      'decostop': 'Dekostopp',
      'ceiling': 'Deko-Grenze verletzt',
      'gaschange': 'Gaswechsel',
      'gaschange2': 'Gaswechsel',
      'violation': 'Grenzwert überschritten',
      'bookmark': 'Markierung',
      'surface': 'Aufgetaucht',
      'rbt': 'Restgrundzeit',
      'airtime': 'Luftzeit',
      'maxdepth': 'Maximaltiefe',
      'divetime': 'Tauchzeit',
      'workload': 'Hohe Atemarbeit',
      'transmitter': 'Sender-Warnung',
      'tissuelevel': 'Gewebesättigung',
      'heading': 'Kompass-Richtung',
      'floor': 'Tiefengrenze',
      'olf': 'Sauerstoffbelastung',
      'po2': 'Sauerstoff-Partialdruck',
      'rgbm': 'RGBM-Warnung',
    };
    for (final e in expected.entries) {
      expect(eventLabel(l10n, e.key), e.value, reason: e.key);
    }
    // Unknown types are never shown raw and alone.
    expect(eventLabel(l10n, 'xyz'), 'Ereignis (xyz)');
  });

  test('T21.9 warnings are marked, information is not', () {
    const warnings = [
      'ascent', 'ceiling', 'violation', 'decostop', 'transmitter', //
      'workload', 'rbt', 'maxdepth', 'divetime', 'airtime', 'po2', 'olf',
      'floor', 'rgbm',
    ];
    const information = [
      'deepstop', 'safetystop', 'gaschange', 'bookmark', 'surface', //
      'heading', 'tissuelevel', 'xyz',
    ];
    for (final t in warnings) {
      expect(isWarningEvent(t), isTrue, reason: t);
    }
    for (final t in information) {
      expect(isWarningEvent(t), isFalse, reason: t);
    }
  });

  test('T21.10 same events within 60 s become one row with a count', () {
    const events = [
      DiveEvent(timeS: 599, type: 'ascent'),
      DiveEvent(timeS: 599, type: 'safetystop'),
      DiveEvent(timeS: 600, type: 'ascent'),
      DiveEvent(timeS: 1339, type: 'deepstop'),
      DiveEvent(timeS: 1363, type: 'deepstop'),
      DiveEvent(timeS: 1712, type: 'deepstop'), // > 60 s after 1339
      DiveEvent(timeS: 3270, type: 'safetystop'),
      DiveEvent(timeS: 3293, type: 'safetystop'),
      DiveEvent(timeS: 3296, type: 'safetystop'),
    ];
    final groups = groupEvents(events);
    expect(
      [for (final g in groups) '${g.timeS} ${g.type} ${g.count}'],
      [
        '599 ascent 2',
        '599 safetystop 1',
        '1339 deepstop 2',
        '1712 deepstop 1',
        '3270 safetystop 3',
      ],
    );
    expect(groupEvents(const []), isEmpty);
  });
}
