import 'package:flutter/material.dart';

// Colour tokens and type rules from specs/tauchcomputer-import/ui-spec.md §1.

ThemeData buildLightTheme() => _buildTheme(
  brightness: Brightness.light,
  surface: const Color(0xFFF2F8F8),
  onSurface: const Color(0xFF13303A),
  primary: const Color(0xFF0B7A80),
  onPrimary: const Color(0xFFFFFFFF),
  error: const Color(0xFFB42318),
  dive: const DiveColors(
    surfaceRaised: Color(0xFFFFFFFF),
    onSurfaceMuted: Color(0xFF55727A),
    depth: Color(0xFF0B7A80),
    temperature: Color(0xFFA35C00),
    pressure: Color(0xFFB9412A),
    sac: Color(0xFF6D4BC4),
    warning: Color(0xFF9A5B00),
    surfaceTint: Color(0xFFDDEFF0),
    outline: Color(0xFFD6E7E8),
    accent: Color(0xFFB9412A),
    ndl: Color(0xFF3B5BCC),
  ),
  onAccent: const Color(0xFFFFFFFF),
);

ThemeData buildDarkTheme() => _buildTheme(
  brightness: Brightness.dark,
  surface: const Color(0xFF0D1E22),
  onSurface: const Color(0xFFE3F1F2),
  primary: const Color(0xFF4CC9CE),
  onPrimary: const Color(0xFF0D1E22),
  error: const Color(0xFFFF8A80),
  dive: const DiveColors(
    surfaceRaised: Color(0xFF15292F),
    onSurfaceMuted: Color(0xFF9BB5BA),
    depth: Color(0xFF4CC9CE),
    temperature: Color(0xFFF2B14C),
    pressure: Color(0xFFFF8D6E),
    sac: Color(0xFFB49BFF),
    warning: Color(0xFFF5B83D),
    surfaceTint: Color(0xFF123139),
    outline: Color(0xFF21393F),
    accent: Color(0xFFFF8D6E),
    ndl: Color(0xFF8FA8FF),
  ),
  onAccent: const Color(0xFF0D1E22),
);

/// Bundled font (ui-spec §1, assets/fonts/, SIL OFL 1.1).
const appFontFamily = 'Manrope';

ThemeData _buildTheme({
  required Brightness brightness,
  required Color surface,
  required Color onSurface,
  required Color primary,
  required Color onPrimary,
  required Color error,
  required DiveColors dive,
  required Color onAccent,
}) {
  final scheme =
      ColorScheme.fromSeed(seedColor: primary, brightness: brightness).copyWith(
        primary: primary,
        onPrimary: onPrimary,
        error: error,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: dive.onSurfaceMuted,
        outline: dive.outline,
        outlineVariant: dive.outline,
        surfaceContainerLowest: dive.surfaceRaised,
        surfaceContainerLow: dive.surfaceRaised,
        surfaceContainer: dive.surfaceRaised,
        surfaceContainerHigh: dive.surfaceRaised,
        surfaceContainerHighest: dive.surfaceTint,
        tertiary: dive.accent,
        onTertiary: onAccent,
      );
  final base = ThemeData(
    colorScheme: scheme,
    fontFamily: appFontFamily,
    extensions: [dive],
  );
  return base.copyWith(
    scaffoldBackgroundColor: surface,
    textTheme: _withTabularFigures(base.textTheme),
    cardTheme: CardThemeData(
      elevation: 0,
      color: dive.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: dive.outline),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: dive.accent,
      foregroundColor: onAccent,
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: dive.outline),
      selectedColor: primary.withValues(alpha: 0.16),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dive.surfaceRaised,
      indicatorColor: primary.withValues(alpha: 0.16),
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
    required this.surfaceTint,
    required this.outline,
    required this.accent,
    required this.ndl,
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
