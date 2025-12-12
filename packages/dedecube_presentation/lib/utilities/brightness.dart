import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// Extension methods and properties for the [Brightness] enum.
extension BrightnessExtension on Brightness {
  /// Returns an icon representing the brightness level.
  /// [MdiIcons.weatherSunny] for light and [MdiIcons.weatherNight] for dark.
  IconData get icon => switch (this) {
        Brightness.light => MdiIcons.weatherSunny,
        Brightness.dark => MdiIcons.weatherNight,
      };

  /// Whether the brightness is light.
  bool get isLight => this == Brightness.light;

  /// Whether the brightness is dark.
  bool get isDark => this == Brightness.dark;

  /// Returns the opposite brightness value.
  /// Light becomes dark, dark becomes light.
  Brightness get opposite => switch (this) {
        Brightness.light => Brightness.dark,
        Brightness.dark => Brightness.light,
      };

  /// Folds the brightness value into a result of type [T].
  ///
  /// [onDark] is called when brightness is dark.
  /// [onLight] is called when brightness is light.
  T fold<T>({
    required T Function() onDark,
    required T Function() onLight,
  }) =>
      switch (this) {
        Brightness.light => onLight(),
        Brightness.dark => onDark(),
      };

  /// Returns a color representing this brightness.
  /// White for light mode, black for dark mode.
  Color get color => switch (this) {
        Brightness.light => Colors.white,
        Brightness.dark => Colors.black,
      };

  /// Returns a contrasting color for this brightness.
  /// Black for light mode, white for dark mode.
  Color get contrast => switch (this) {
        Brightness.light => Colors.black,
        Brightness.dark => Colors.white,
      };
}
