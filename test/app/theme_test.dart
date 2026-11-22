import 'dart:io';

import 'package:divedown/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('T21.1 light theme Riff (ui-spec §1)', () {
    final theme = buildLightTheme();
    final scheme = theme.colorScheme;
    final dive = theme.extension<DiveColors>();

    test('uses Material 3 and the light brightness', () {
      expect(theme.useMaterial3, isTrue);
      expect(scheme.brightness, Brightness.light);
    });

    test('maps the colour tokens onto the ColorScheme', () {
      expect(scheme.surface, const Color(0xFFF2F8F8));
      expect(scheme.onSurface, const Color(0xFF13303A));
      expect(scheme.primary, const Color(0xFF0B7A80));
      expect(scheme.error, const Color(0xFFB42318));
    });

    test('exposes the domain tokens as DiveColors', () {
      expect(dive, isNotNull);
      expect(dive!.surfaceRaised, const Color(0xFFFFFFFF));
      expect(dive.surfaceTint, const Color(0xFFDDEFF0));
      expect(dive.outline, const Color(0xFFD6E7E8));
      expect(dive.onSurfaceMuted, const Color(0xFF55727A));
      expect(dive.accent, const Color(0xFFB9412A));
      expect(dive.depth, const Color(0xFF0B7A80));
      expect(dive.temperature, const Color(0xFFA35C00));
      expect(dive.pressure, const Color(0xFFB9412A));
      expect(dive.sac, const Color(0xFF6D4BC4));
      expect(dive.ndl, const Color(0xFF3B5BCC));
      expect(dive.warning, const Color(0xFF9A5B00));
    });
  });

  group('T21.2 dark theme Riff (ui-spec §1)', () {
    final theme = buildDarkTheme();
    final scheme = theme.colorScheme;
    final dive = theme.extension<DiveColors>();

    test('maps the colour tokens onto the ColorScheme', () {
      expect(scheme.brightness, Brightness.dark);
      expect(scheme.surface, const Color(0xFF0D1E22));
      expect(scheme.onSurface, const Color(0xFFE3F1F2));
      expect(scheme.primary, const Color(0xFF4CC9CE));
      expect(scheme.error, const Color(0xFFFF8A80));
    });

    test('exposes the domain tokens as DiveColors', () {
      expect(dive, isNotNull);
      expect(dive!.surfaceRaised, const Color(0xFF15292F));
      expect(dive.surfaceTint, const Color(0xFF123139));
      expect(dive.outline, const Color(0xFF21393F));
      expect(dive.onSurfaceMuted, const Color(0xFF9BB5BA));
      expect(dive.accent, const Color(0xFFFF8D6E));
      expect(dive.depth, const Color(0xFF4CC9CE));
      expect(dive.temperature, const Color(0xFFF2B14C));
      expect(dive.pressure, const Color(0xFFFF8D6E));
      expect(dive.sac, const Color(0xFFB49BFF));
      expect(dive.ndl, const Color(0xFF8FA8FF));
      expect(dive.warning, const Color(0xFFF5B83D));
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

  group('T21.3 Manrope, bundled (ui-spec §1)', () {
    test('every text style uses Manrope', () {
      final styles = buildLightTheme().textTheme;
      for (final style in [
        styles.displayLarge,
        styles.headlineMedium,
        styles.titleMedium,
        styles.bodyMedium,
        styles.labelSmall,
      ]) {
        expect(style?.fontFamily, 'Manrope');
      }
    });

    test('font files and their OFL licence ship with the app', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('family: Manrope'));
      final fonts = Directory('assets/fonts');
      expect(fonts.existsSync(), isTrue, reason: 'assets/fonts missing');
      final files = fonts.listSync().map((f) => f.uri.pathSegments.last);
      expect(
        files.where((f) => f.contains('Manrope') && f.endsWith('.ttf')),
        isNotEmpty,
      );
      expect(File('assets/fonts/OFL.txt').existsSync(), isTrue);
      expect(File('THIRD_PARTY.md').readAsStringSync(), contains('Manrope'));
    });
  });

  test('T21.4 cards: 20 dp corners and an outline instead of a shadow', () {
    final theme = buildLightTheme();
    final shape = theme.cardTheme.shape as RoundedRectangleBorder?;
    expect(shape?.borderRadius, BorderRadius.circular(20));
    expect(shape?.side.color, const Color(0xFFD6E7E8));
    expect(theme.cardTheme.elevation, 0);
  });
}
