import 'package:flutter/material.dart';

extension MaterialColorExtension on Color {
  /// Converts the [Color] to a [MaterialColor] with optional shades.
  ///
  /// Returns a [MaterialColor] object with the specified or default shades.
  MaterialColor toMaterialColor({Map<int, Color>? shades}) {
    return MaterialColor(
      toARGB32(),
      shades ??
          {
            50: withValues(alpha: 0.1),
            100: withValues(alpha: 0.2),
            200: withValues(alpha: 0.3),
            300: withValues(alpha: 0.4),
            400: withValues(alpha: 0.5),
            500: this,
            600: withValues(alpha: 0.7),
            700: withValues(alpha: 0.8),
            800: withValues(alpha: 0.9),
            900: withValues(alpha: 1.0),
          },
    );
  }
}
