import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

extension ColorExtension on Color {
  /// Gets the tone value of the color in HCT color space.
  /// Returns a value between 0 (black) and 100 (white).
  double get tone {
    return Hct.fromInt(toARGB32()).tone;
  }

  /// Gets the chroma (colorfulness) of the color in HCT color space.
  /// Returns a value between 0 (grayscale) and ??? (most colorful).
  /// (Chroma has a different maximum for any given hue and tone)
  double get chroma {
    return Hct.fromInt(toARGB32()).chroma;
  }

  /// Gets the hue angle of the color in HCT color space.
  /// Returns a value between 0 and 360 degrees.
  double get hue {
    return Hct.fromInt(toARGB32()).hue;
  }

  /// Creates a new color with the specified tone while preserving hue and chroma.
  /// [tone] should be between 0 (black) and 100 (white).
  Color withTone(double tone) {
    final old = Hct.fromInt(toARGB32());
    return Color(Hct.from(old.hue, old.chroma, tone).toInt());
  }

  /// Creates a new color with the specified chroma while preserving hue and tone.
  /// [chroma] should be between 0 (grayscale) and ??? (most colorful).
  /// (Chroma has a different maximum for any given hue and tone)
  Color withChroma(double chroma) {
    final old = Hct.fromInt(toARGB32());
    return Color(Hct.from(old.hue, chroma, old.tone).toInt());
  }

  /// Creates a new color with the specified hue while preserving chroma and tone.
  /// [hue] should be between 0 and 360 degrees.
  Color withHue(double hue) {
    final old = Hct.fromInt(toARGB32());
    return Color(Hct.from(hue, old.chroma, old.tone).toInt());
  }

  /// Creates a key color mapping for the given brightness.
  /// Returns a [KeyColorMapping] containing tonal variations of the color.
  KeyColorMapping keyColorMapping(Brightness brightness) {
    return KeyColorMapping(this, brightness);
  }

  /// Creates a neutral color mapping for the given brightness.
  /// Returns a [NeutralColorMapping] containing neutral tonal variations.
  NeutralColorMapping neutralColorMapping(Brightness brightness) {
    return NeutralColorMapping(this, brightness);
  }

  /// Estimates the brightness of the color.
  /// Returns either [Brightness.light] or [Brightness.dark].
  Brightness get brightness => ThemeData.estimateBrightnessForColor(this);

  /// Returns true if the color is considered dark.
  bool get isDark => brightness == Brightness.dark;

  /// Returns true if the color is considered light.
  bool get isLight => brightness == Brightness.light;

  /// Returns white for dark colors and black for light colors.
  Color get contrast => isDark ? Colors.white : Colors.black;

  /// Checks if the color would be legible when placed on another color.
  bool legibleOn(Color other) => brightness != other.brightness;
}

extension ColorFilterExtension on Color {
  /// Returns a ColorFilter with the [BlendMode.srcIn] blend mode.
  ColorFilter get asSrcIn => ColorFilter.mode(this, BlendMode.srcIn);
}

class NeutralColorMapping {
  NeutralColorMapping(Color key, Brightness brightness) {
    final s = _buildDynamicScheme(brightness: brightness, seedColor: key);

    surfaceDim = key.withTone(MaterialDynamicColors.surfaceDim.tone(s));
    surface = key.withTone(MaterialDynamicColors.surface.tone(s));
    surfaceBright = key.withTone(MaterialDynamicColors.surfaceBright.tone(s));
    surfaceContainerLowest =
        key.withTone(MaterialDynamicColors.surfaceDim.tone(s));
    surfaceContainerLow =
        key.withTone(MaterialDynamicColors.surfaceContainerLow.tone(s));
    surfaceContainer =
        key.withTone(MaterialDynamicColors.surfaceContainer.tone(s));
    surfaceContainerHigh =
        key.withTone(MaterialDynamicColors.surfaceDim.tone(s));
    surfaceContainerHighest =
        key.withTone(MaterialDynamicColors.surfaceDim.tone(s));
    onSurface = key.withTone(MaterialDynamicColors.onSurface.tone(s));
    onSurfaceVariant =
        key.withTone(MaterialDynamicColors.onSurfaceVariant.tone(s));
    outline = key.withTone(MaterialDynamicColors.outline.tone(s));
    outlineVariant = key.withTone(MaterialDynamicColors.outlineVariant.tone(s));
  }

  late final Color surfaceDim;
  late final Color surface;
  late final Color surfaceBright;
  late final Color surfaceContainerLowest;
  late final Color surfaceContainerLow;
  late final Color surfaceContainer;
  late final Color surfaceContainerHigh;
  late final Color surfaceContainerHighest;
  late final Color onSurface;
  late final Color onSurfaceVariant;
  late final Color outline;
  late final Color outlineVariant;
}

class KeyColorMapping {
  KeyColorMapping(Color key, Brightness brightness) {
    final s = _buildDynamicScheme(brightness: brightness, seedColor: key);
    accent = key.withTone(MaterialDynamicColors.primary.tone(s));
    onAccent = key.withTone(MaterialDynamicColors.onPrimary.tone(s));
    container = key.withTone(MaterialDynamicColors.primaryContainer.tone(s));
    onContainer =
        key.withTone(MaterialDynamicColors.onPrimaryContainer.tone(s));
  }

  late final Color accent;
  late final Color onAccent;
  late final Color container;
  late final Color onContainer;
}

DynamicScheme _buildDynamicScheme({
  required Brightness brightness,
  required Color seedColor,
  DynamicSchemeVariant schemeVariant = DynamicSchemeVariant.tonalSpot,
  double contrastLevel = 0.0,
}) {
  assert(
    contrastLevel >= -1.0 && contrastLevel <= 1.0,
    'contrastLevel must be between -1.0 and 1.0 inclusive.',
  );
  final bool isDark = brightness == Brightness.dark;
  final Hct sourceColor = Hct.fromInt(seedColor.toARGB32());
  return switch (schemeVariant) {
    DynamicSchemeVariant.tonalSpot => SchemeTonalSpot(
        sourceColorHct: sourceColor,
        isDark: isDark,
        contrastLevel: contrastLevel,
      ),
    DynamicSchemeVariant.fidelity => SchemeFidelity(
        sourceColorHct: sourceColor,
        isDark: isDark,
        contrastLevel: contrastLevel,
      ),
    DynamicSchemeVariant.content => SchemeContent(
        sourceColorHct: sourceColor,
        isDark: isDark,
        contrastLevel: contrastLevel,
      ),
    DynamicSchemeVariant.monochrome => SchemeMonochrome(
        sourceColorHct: sourceColor,
        isDark: isDark,
        contrastLevel: contrastLevel,
      ),
    DynamicSchemeVariant.neutral => SchemeNeutral(
        sourceColorHct: sourceColor,
        isDark: isDark,
        contrastLevel: contrastLevel,
      ),
    DynamicSchemeVariant.vibrant => SchemeVibrant(
        sourceColorHct: sourceColor,
        isDark: isDark,
        contrastLevel: contrastLevel,
      ),
    DynamicSchemeVariant.expressive => SchemeExpressive(
        sourceColorHct: sourceColor,
        isDark: isDark,
        contrastLevel: contrastLevel,
      ),
    DynamicSchemeVariant.rainbow => SchemeRainbow(
        sourceColorHct: sourceColor,
        isDark: isDark,
        contrastLevel: contrastLevel,
      ),
    DynamicSchemeVariant.fruitSalad => SchemeFruitSalad(
        sourceColorHct: sourceColor,
        isDark: isDark,
        contrastLevel: contrastLevel,
      ),
  };
}
