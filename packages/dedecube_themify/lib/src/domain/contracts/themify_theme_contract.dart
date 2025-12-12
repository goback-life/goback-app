import 'package:flutter/material.dart';

/// A contract defining the required theme properties for an application.
abstract class ThemifyThemeContract {
  /// The color scheme for this theme.
  ///
  /// Returns a [ColorScheme] that defines the primary and secondary colors, as well as other
  /// color properties for the theme. If not overridden, this getter returns `null`.
  ColorScheme? get colorScheme {
    return null;
  }

  /// The overall theme data.
  ///
  /// Returns a [ThemeData] object representing the complete visual configuration of the application,
  /// including colors, typography, icon themes, etc. Implementations must override this getter to provide
  /// a proper theme.
  ThemeData get themeData;
}
