import 'package:flutter/material.dart';

// Colour tokens and type rules from specs/tauchcomputer-import/ui-spec.md §1.

ThemeData buildLightTheme() => _buildTheme(
  brightness: Brightness.light,
  surface: const Color(0xFFF6F8FA),
  onSurface: const Color(0xFF0E1B26),
  primary: const Color(0xFF0B5C8A),
  error: const Color(0xFFB91C1C),
  dive: const DiveColors(
    surfaceRaised: Color(0xFFFFFFFF),
    onSurfaceMuted: Color(0xFF4A5C6B),
    depth: Color(0xFF1676B8),
    temperature: Color(0xFFC2410C),
    pressure: Color(0xFF047857),
    sac: Color(0xFF7C3AED),
    warning: Color(0xFFB45309),
  ),
);

ThemeData buildDarkTheme() => _buildTheme(
  brightness: Brightness.dark,
  surface: const Color(0xFF0B1620),
  onSurface: const Color(0xFFE6EEF4),
  primary: const Color(0xFF5CB8E8),
  error: const Color(0xFFF87171),
  dive: const DiveColors(
    surfaceRaised: Color(0xFF13212E),
    onSurfaceMuted: Color(0xFF9AB0C0),
    depth: Color(0xFF3FA3E0),
    temperature: Color(0xFFFB923C),
    pressure: Color(0xFF34D399),
    sac: Color(0xFFA78BFA),
    warning: Color(0xFFFBBF24),
  ),
);

ThemeData _buildTheme({
  required Brightness brightness,
  required Color surface,
  required Color onSurface,
  required Color primary,
  required Color error,
  required DiveColors dive,
}) {
  final scheme =
      ColorScheme.fromSeed(seedColor: primary, brightness: brightness).copyWith(
        primary: primary,
        error: error,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: dive.onSurfaceMuted,
        surfaceContainerLowest: dive.surfaceRaised,
        surfaceContainerLow: dive.surfaceRaised,
        surfaceContainer: dive.surfaceRaised,
      );
  final base = ThemeData(colorScheme: scheme, extensions: [dive]);
  return base.copyWith(
    scaffoldBackgroundColor: surface,
    textTheme: _withTabularFigures(base.textTheme),
    cardTheme: const CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );
}

TextTheme _withTabularFigures(TextTheme t) {
  TextStyle? tab(TextStyle? s) =>
      s?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  return t.copyWith(
    displayLarge: tab(t.displayLarge),
    displayMedium: tab(t.displayMedium),
    displaySmall: tab(t.displaySmall),
    headlineLarge: tab(t.headlineLarge),
    headlineMedium: tab(t.headlineMedium),
    headlineSmall: tab(t.headlineSmall),
    titleLarge: tab(t.titleLarge),
    titleMedium: tab(t.titleMedium),
    titleSmall: tab(t.titleSmall),
    bodyLarge: tab(t.bodyLarge),
    bodyMedium: tab(t.bodyMedium),
    bodySmall: tab(t.bodySmall),
    labelLarge: tab(t.labelLarge),
    labelMedium: tab(t.labelMedium),
    labelSmall: tab(t.labelSmall),
  );
}

/// Domain colours that have no slot in [ColorScheme].
class DiveColors extends ThemeExtension<DiveColors> {
  const DiveColors({
    required this.surfaceRaised,
    required this.onSurfaceMuted,
    required this.depth,
    required this.temperature,
    required this.pressure,
    required this.sac,
    required this.warning,
    this.surfaceTint = const Color(0xFFF6F8FA),
    this.outline = const Color(0xFF4A5C6B),
    this.accent = const Color(0xFF0B5C8A),
    this.ndl = const Color(0xFF1676B8),
  });

  final Color surfaceRaised;
  final Color onSurfaceMuted;
  final Color depth;
  final Color temperature;
  final Color pressure;
  final Color sac;
  final Color warning;

  /// Flat tint behind the detail header; only `onSurface` text on it.
  final Color surfaceTint;

  /// Card borders, dividers, chart grid.
  final Color outline;

  /// Coral accent: „Manuell eintragen“, air in the profile.
  final Color accent;

  /// NDL band in the profile.
  final Color ndl;

  @override
  DiveColors copyWith({
    Color? surfaceRaised,
    Color? onSurfaceMuted,
    Color? depth,
    Color? temperature,
    Color? pressure,
    Color? sac,
    Color? warning,
    Color? surfaceTint,
    Color? outline,
    Color? accent,
    Color? ndl,
  }) => DiveColors(
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
    depth: depth ?? this.depth,
    temperature: temperature ?? this.temperature,
    pressure: pressure ?? this.pressure,
    sac: sac ?? this.sac,
    warning: warning ?? this.warning,
    surfaceTint: surfaceTint ?? this.surfaceTint,
    outline: outline ?? this.outline,
    accent: accent ?? this.accent,
    ndl: ndl ?? this.ndl,
  );

  @override
  DiveColors lerp(DiveColors? other, double t) {
    if (other == null) return this;
    return DiveColors(
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      onSurfaceMuted: Color.lerp(onSurfaceMuted, other.onSurfaceMuted, t)!,
      depth: Color.lerp(depth, other.depth, t)!,
      temperature: Color.lerp(temperature, other.temperature, t)!,
      pressure: Color.lerp(pressure, other.pressure, t)!,
      sac: Color.lerp(sac, other.sac, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      ndl: Color.lerp(ndl, other.ndl, t)!,
    );
  }
}
