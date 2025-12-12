import 'package:flutter/material.dart';

/// Extension on [TextTheme] that provides functionality to change font families
/// for different text styles in bulk.
extension TextThemeFamilyChanger on TextTheme {
  /// Creates a copy of this [TextTheme] with modified font families for different
  /// text categories.
  ///
  /// Parameters:
  /// - [display] - Font family for display styles (large, medium, small)
  /// - [headline] - Font family for headline styles (large, medium, small)
  /// - [title] - Font family for title styles (large, medium, small)
  /// - [body] - Font family for body styles (large, medium, small)
  /// - [label] - Font family for label styles (large, medium, small)
  ///
  /// Returns a new [TextTheme] with the specified font families applied to their
  /// respective text styles.
  TextTheme withFamilies({
    String? display,
    String? headline,
    String? title,
    String? body,
    String? label,
  }) =>
      copyWith(
        displayLarge: displayLarge!.copyWith(fontFamily: display),
        displayMedium: displayMedium!.copyWith(fontFamily: display),
        displaySmall: displaySmall!.copyWith(fontFamily: display),
        headlineLarge: headlineLarge!.copyWith(fontFamily: headline),
        headlineMedium: headlineMedium!.copyWith(fontFamily: headline),
        headlineSmall: headlineSmall!.copyWith(fontFamily: headline),
        titleLarge: titleLarge!.copyWith(fontFamily: title),
        titleMedium: titleMedium!.copyWith(fontFamily: title),
        titleSmall: titleSmall!.copyWith(fontFamily: title),
        bodyLarge: bodyLarge!.copyWith(fontFamily: body),
        bodyMedium: bodyMedium!.copyWith(fontFamily: body),
        bodySmall: bodySmall!.copyWith(fontFamily: body),
        labelLarge: labelLarge!.copyWith(fontFamily: label),
        labelMedium: labelMedium!.copyWith(fontFamily: label),
        labelSmall: labelSmall!.copyWith(fontFamily: label),
      );
}
