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
      brightness: Brightness.light,
      // primaries
      primary: MainColors.accent,
      onPrimary: MainColors.white,
      primaryContainer: MainColors.accent,
      onPrimaryContainer: MainColors.white,
      // secondaries
      secondary: MainColors.dark,
      onSecondary: MainColors.white,
      secondaryContainer: MainColors.surface,
      onSecondaryContainer: MainColors.dark,
      // tertiary
      tertiary: MainColors.accent,
      onTertiary: MainColors.white,
      tertiaryContainer: MainColors.accent,
      onTertiaryContainer: MainColors.white,
      // error
      error: MainColors.red500,
      onError: MainColors.white,
      errorContainer: MainColors.red100,
      onErrorContainer: MainColors.red500,
      // surface
      surface: MainColors.surface,
      surfaceDim: Color(0xFFE0DFDD),
      onSurface: MainColors.dark,
      onSurfaceVariant: Color(0xFF5A5A58),
      // outline
      outline: Color(0xFFC8C7C5),
      outlineVariant: Color(0xFFB0AFAD),
      // shadows and scrims
      shadow: MainColors.dark,
      scrim: MainColors.dark,
      // containers
      surfaceContainerLowest: MainColors.white,
      surfaceContainerLow: Color(0xFFF5F4F2),
      surfaceContainer: Color(0xFFEFEEEC),
      surfaceContainerHigh: Color(0xFFE8E7E5),
      surfaceContainerHighest: Color(0xFFE0DFDD),
      // banner variants
      tertiaryFixedDim: MainColors.surface,
      onTertiaryFixedVariant: MainColors.dark,
      // inverse
      inverseSurface: MainColors.dark,
      onInverseSurface: MainColors.white,
      inversePrimary: MainColors.accent,
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
          borderRadius: const BorderRadius.all(Radius.circular(10)),
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
