import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/themes/components/main_elevated_button_theme.dart';
import 'package:cloudless/presentation/themes/components/main_text_button_theme.dart';
import 'package:cloudless/presentation/themes/components/main_text_theme.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/link_style.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class MainTheme implements Themable {
  @override
  ColorScheme get colorScheme {
    return const ColorScheme(
      brightness: Brightness.dark,
      // primaries
      primary: MainColors.accent,
      onPrimary: MainColors.white,
      primaryContainer: MainColors.accent,
      onPrimaryContainer: MainColors.white,
      // secondaries
      secondary: MainColors.dark,
      onSecondary: MainColors.white,
      secondaryContainer: MainColors.dark,
      onSecondaryContainer: MainColors.white,
      // tertiary
      tertiary: MainColors.accent,
      onTertiary: MainColors.white,
      tertiaryContainer: MainColors.accent,
      onTertiaryContainer: MainColors.white,
      // error
      error: MainColors.accent,
      onError: MainColors.white,
      errorContainer: MainColors.accent,
      onErrorContainer: MainColors.white,
      // surface
      surface: MainColors.dark,
      surfaceDim: Color(0xFF121212),
      onSurface: MainColors.white,
      onSurfaceVariant: Color(0xFFCCCCCC),
      // outline
      outline: Color(0xFF333333),
      outlineVariant: Color(0xFF444444),
      // shadows and scrims
      shadow: MainColors.dark,
      scrim: MainColors.dark,
      // containers
      surfaceContainerLowest: Color(0xFF0F0F0F),
      surfaceContainerLow: Color(0xFF1A1A1A),
      surfaceContainer: Color(0xFF222222),
      surfaceContainerHigh: Color(0xFF2A2A2A),
      surfaceContainerHighest: Color(0xFF333333),
      // banner variants
      tertiaryFixedDim: MainColors.dark,
      onTertiaryFixedVariant: MainColors.white,
    );
  }

  @override
  ThemeData get themeData {
    final theme = ThemeData(
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.tertiary,
        selectionColor: colorScheme.tertiary.withValues(alpha: 0.3),
        selectionHandleColor: colorScheme.tertiary,
      ),
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: MainTextTheme.theme(colorScheme),
      elevatedButtonTheme: MainElevatedButtonTheme.theme(colorScheme),
      textButtonTheme: MainTextButtonTheme.theme(colorScheme),
      extensions: const [
        CallToActionStyle(
          mode: CallToAction.filled,
          theme: CallToActionTheme.primary,
          horizontalMargin: 20,
          borderRadius: BorderRadius.all(Radius.circular(900)),
          height: 50,
          iconOnTheRight: false,
        ),
        LinkTextStyle(),
      ],
    );

    return theme.copyWith(
      listTileTheme: theme.listTileTheme.copyWith(
        titleTextStyle: theme.textTheme.titleMedium,
        iconColor: theme.colorScheme.onSurface,
      ),
      iconTheme: theme.iconTheme.copyWith(color: theme.colorScheme.onSurface),
    );
  }
}
