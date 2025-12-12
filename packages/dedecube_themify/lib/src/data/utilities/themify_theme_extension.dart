import 'package:dedecube_themify/src/domain/typedefs/themify_typedef.dart';
import 'package:flutter/material.dart';

/// Extension on [Themable] that provides a configured [ThemeData] with an updated color scheme.
///
/// The [configuredThemeData] property creates a copy of the existing [ThemeData] and
/// applies the current theme's color scheme to it. This ensures that any custom colors
/// defined in the theme are integrated throughout the application UI.
///
/// For example, if the current theme defines a specific [ColorScheme], calling
/// [configuredThemeData] will return a [ThemeData] that includes those custom colors.
extension ThemifyThemeExtension on Themable {
  ThemeData get configuredThemeData {
    return themeData.copyWith(
      colorScheme: colorScheme,
    );
  }
}
