import 'package:divedown/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('light theme (ui-spec §1)', () {
    final theme = buildLightTheme();
    final scheme = theme.colorScheme;
    final dive = theme.extension<DiveColors>();

    test('uses Material 3 and the light brightness', () {
      expect(theme.useMaterial3, isTrue);
      expect(scheme.brightness, Brightness.light);
    });

    test('maps the colour tokens onto the ColorScheme', () {
      expect(scheme.surface, const Color(0xFFF6F8FA));
      expect(scheme.onSurface, const Color(0xFF0E1B26));
      expect(scheme.primary, const Color(0xFF0B5C8A));
      expect(scheme.error, const Color(0xFFB91C1C));
    });

    test('exposes the domain tokens as DiveColors', () {
      expect(dive, isNotNull);
      expect(dive!.surfaceRaised, const Color(0xFFFFFFFF));
      expect(dive.onSurfaceMuted, const Color(0xFF4A5C6B));
      expect(dive.depth, const Color(0xFF1676B8));
      expect(dive.temperature, const Color(0xFFC2410C));
      expect(dive.pressure, const Color(0xFF047857));
      expect(dive.sac, const Color(0xFF7C3AED));
      expect(dive.warning, const Color(0xFFB45309));
    });
  });

  group('dark theme (ui-spec §1)', () {
    final theme = buildDarkTheme();
    final scheme = theme.colorScheme;
    final dive = theme.extension<DiveColors>();

    test('maps the colour tokens onto the ColorScheme', () {
      expect(scheme.brightness, Brightness.dark);
      expect(scheme.surface, const Color(0xFF0B1620));
      expect(scheme.onSurface, const Color(0xFFE6EEF4));
      expect(scheme.primary, const Color(0xFF5CB8E8));
      expect(scheme.error, const Color(0xFFF87171));
    });

    test('exposes the domain tokens as DiveColors', () {
      expect(dive, isNotNull);
      expect(dive!.surfaceRaised, const Color(0xFF13212E));
      expect(dive.onSurfaceMuted, const Color(0xFF9AB0C0));
      expect(dive.depth, const Color(0xFF3FA3E0));
      expect(dive.temperature, const Color(0xFFFB923C));
      expect(dive.pressure, const Color(0xFF34D399));
      expect(dive.sac, const Color(0xFFA78BFA));
      expect(dive.warning, const Color(0xFFFBBF24));
    });
  });

  test('all text styles use tabular figures (ui-spec §1)', () {
    final styles = buildLightTheme().textTheme;
    for (final style in [
      styles.displayLarge,
      styles.headlineMedium,
      styles.titleMedium,
      styles.bodyMedium,
      styles.labelSmall,
    ]) {
      expect(style?.fontFeatures, contains(const FontFeature.tabularFigures()));
    }
  });

  test('DiveColors interpolates between light and dark', () {
    final light = buildLightTheme().extension<DiveColors>()!;
    final dark = buildDarkTheme().extension<DiveColors>()!;
    expect(light.lerp(dark, 0).depth, light.depth);
    expect(light.lerp(dark, 1).depth, dark.depth);
  });
}
