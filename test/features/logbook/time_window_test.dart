// T27.1: the visible time range of the full-screen profile (ui-spec §6).
import 'package:divedown/features/logbook/time_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('T27.1 TimeWindow', () {
    late TimeWindow full;
    setUp(() => full = TimeWindow.full(2800));

    test('starts with the whole dive', () {
      expect((full.startS, full.endS, full.isFull), (0.0, 2800.0, true));
      expect(full.timeAt(0.25), 700);
    });

    test('zoom keeps the moment under the fingers in place', () {
      final mid = full.zoom(2, 0.5);
      expect((mid.startS, mid.endS), (700.0, 2100.0));
      expect(mid.isFull, isFalse);

      final left = full.zoom(4, 0);
      expect((left.startS, left.endS), (0.0, 700.0));

      final again = mid.zoom(2, 0.25);
      expect(again.timeAt(0.25), mid.timeAt(0.25));
      expect(again.lengthS, 700);
    });

    test('never narrower than 2 min, never wider than the dive', () {
      expect(full.zoom(1000, 0.5).lengthS, TimeWindow.minLengthS);
      final out = full.zoom(2, 0.5).zoom(0.1, 0.5);
      expect((out.startS, out.endS, out.isFull), (0.0, 2800.0, true));
    });

    test('zooming near the end stays inside the dive', () {
      final w = full.zoom(2, 0.5).pan(1).zoom(0.8, 1);
      expect(w.endS, 2800);
      expect(w.startS, greaterThanOrEqualTo(0));
    });

    test('pan moves by a part of the visible length and stops at the '
        'edges', () {
      final mid = full.zoom(2, 0.5);
      final later = mid.pan(0.25);
      expect((later.startS, later.endS), (1050.0, 2450.0));
      expect(mid.pan(5).endS, 2800);
      expect(mid.pan(-5).startS, 0);
      expect(mid.pan(-5).lengthS, 1400);
      expect(full.pan(0.5).startS, 0, reason: 'nothing to move');
    });
  });
}
