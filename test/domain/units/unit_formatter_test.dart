// T15.1: display units, metric, German number format (ui-spec §3).
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/units/unit_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const f = UnitFormatter.metric();

  test('T15.1: depth with one decimal and a comma', () {
    expect(f.depth(18.4), '18,4 m');
    expect(f.depth(30), '30,0 m');
    expect(f.depth(29.87), '29,9 m');
  });

  test('T15.1: duration in whole minutes', () {
    expect(f.duration(2820), '47 min');
    expect(f.duration(4200), '70 min');
    expect(f.duration(2850), '48 min');
  });

  test('T15.1: temperature, pressure, volume, SAC', () {
    expect(f.temperature(21), '21 °C');
    expect(f.temperature(-1.6), '-2 °C');
    expect(f.pressure(200), '200 bar');
    expect(f.volume(12), '12 l');
    expect(f.volume(11.1), '11,1 l');
    expect(f.sac(18), '18,0 l/min');
    expect(f.sac(14.24), '14,2 l/min');
  });

  test('T15.1: gas names', () {
    expect(f.gas(const GasMix(o2: 0.21)), 'Luft');
    expect(f.gas(const GasMix(o2: 0.32)), 'EAN32');
    expect(f.gas(const GasMix(o2: 0.21, he: 0.35)), 'Tx 21/35');
  });
}
