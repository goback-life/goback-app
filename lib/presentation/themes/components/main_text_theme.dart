import 'package:cloudless/presentation/themes/components/default_text_theme.dart';
import 'package:cloudless/presentation/themes/components/text_theme_extensions.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:flutter/material.dart';

class MainTextTheme {
  static TextTheme theme(ColorScheme? colorScheme) {
    return DefaultTextTheme.create()
        .broadCustomization(
          color: colorScheme?.onSurface,
          family: MainFontFamilies.geist,
          displayWeight: FontWeight.w600, // huge titles
          headlineWeight: FontWeight.w600, // headers
          titleWeight: FontWeight.w600, // sub-headers
          bodyWeight: FontWeight.w400, // the rest
          labelWeight: FontWeight.w500, // call to actions
        )
        .merge(
          const TextTheme(
            // big header title
            displayMedium: TextStyle(fontSize: 40, height: 47 / 40),
            // header titles
            headlineMedium: TextStyle(fontSize: 28, height: 33 / 28),
            // big header subtitle and dialog titles
            headlineSmall: TextStyle(fontSize: 24, height: 31 / 24),
            // onboarding slides
            titleLarge: TextStyle(fontSize: 20, height: 22 / 20),
            // header subtitles
            titleMedium: TextStyle(fontSize: 16, height: 16 / 16),
            // minimum size for onboarding slides
            titleSmall: TextStyle(fontSize: 18, height: 44 / 18),
            // text fields
            bodyLarge: TextStyle(fontSize: 16, height: 21 / 16),
            // bodies
            bodyMedium: TextStyle(fontSize: 14, height: 18 / 14),
            // call to actions
            labelMedium: TextStyle(fontSize: 12, height: 16 / 12),
          ),
        );
  }
}
