import 'package:cloudless/presentation/themes/components/main_text_theme.dart';
import 'package:flutter/material.dart';

class MainElevatedButtonTheme {
  static ElevatedButtonThemeData theme(ColorScheme? colorScheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme?.secondaryContainer,
        foregroundColor: colorScheme?.onSecondaryContainer,
        disabledBackgroundColor: colorScheme?.secondaryContainer.withValues(
          alpha: 0.2,
        ),
        disabledForegroundColor: colorScheme?.onSecondaryContainer,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12),
        textStyle: MainTextTheme.theme(colorScheme).headlineMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
