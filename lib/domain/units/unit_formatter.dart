import '../dive/dive.dart';

/// Turns SI values into display text (ui-spec §3). German decimal comma.
/// Only metric for now; imperial comes with the settings screen.
class UnitFormatter {
  const UnitFormatter.metric();

  /// `18,4 m`
  String depth(double metres) => '${_fixed(metres, 1)} m';

  /// `47 min`, rounded to whole minutes.
  String duration(int seconds) => '${(seconds / 60).round()} min';

  /// Time under water in the logbook header (ui-spec §5.2): „61 h“ from
  /// 10 h on, below that „7 h 40 min“ or „40 min“.
  String underwater(int seconds) => throw UnimplementedError('underwater');

  /// `21 °C`
  String temperature(double celsius) => '${celsius.round()} °C';

  /// `200 bar`
  String pressure(double bar) => '${bar.round()} bar';

  /// `12 l`
  String volume(double litres) => '${trimmed(litres, 1)} l';

  /// `18,0 l/min`
  String sac(double litresPerMinute) => '${_fixed(litresPerMinute, 1)} l/min';

  /// `Luft`, `EAN32`, `Tx 21/35`
  String gas(GasMix gas) {
    final o2 = (gas.o2 * 100).round();
    final he = (gas.he * 100).round();
    if (he > 0) return 'Tx $o2/$he';
    if (o2 == 21) return 'Luft';
    return 'EAN$o2';
  }

  /// Number without unit for form fields: up to [decimals] places, no
  /// trailing zeros, German comma (`18,4`, `12`).
  static String trimmed(double value, int decimals) {
    var s = value.toStringAsFixed(decimals);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return s.replaceAll('.', ',');
  }

  static String _fixed(double value, int decimals) =>
      value.toStringAsFixed(decimals).replaceAll('.', ',');
}
