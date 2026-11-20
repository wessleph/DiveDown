import '../dive/dive.dart';

/// Turns SI values into display text (ui-spec §3). German decimal comma.
/// Only metric for now; imperial comes with the settings screen.
class UnitFormatter {
  const UnitFormatter.metric();

  /// `18,4 m`
  String depth(double metres) => throw UnimplementedError('T15.1: depth');

  /// `47 min`, rounded to whole minutes.
  String duration(int seconds) => throw UnimplementedError('T15.1: duration');

  /// `21 °C`
  String temperature(double celsius) =>
      throw UnimplementedError('T15.1: temperature');

  /// `200 bar`
  String pressure(double bar) => throw UnimplementedError('T15.1: pressure');

  /// `12 l`
  String volume(double litres) => throw UnimplementedError('T15.1: volume');

  /// `18,0 l/min`
  String sac(double litresPerMinute) => throw UnimplementedError('T15.1: sac');

  /// `Luft`, `EAN32`, `Tx 21/35`
  String gas(GasMix gas) => throw UnimplementedError('T15.1: gas');
}
