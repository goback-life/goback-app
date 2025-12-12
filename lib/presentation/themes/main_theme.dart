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
      primary: MainColors.white,
      onPrimary: MainColors.white, // used by DefaultLoadingOverlay
      primaryContainer: MainColors.green500,
      onPrimaryContainer: MainColors.green500,
      // secondaries
      secondary: MainColors.black,
      onSecondary: MainColors.white,
      secondaryContainer: MainColors.white,
      onSecondaryContainer: MainColors.black,
      // tertiary
      tertiary: MainColors.blue500,
      onTertiary: MainColors.white,
      tertiaryContainer: MainColors.green500,
      onTertiaryContainer: MainColors.green500,
      // error
      error: MainColors.red500,
      onError: MainColors.white,
      errorContainer: MainColors.red500,
      onErrorContainer: MainColors.white,
      // surface
      surface: MainColors.white,
      surfaceDim: MainColors.grey400,
      onSurface: MainColors.black,
      onSurfaceVariant: MainColors.grey500,
      // outline
      outline: MainColors.grey200,
      outlineVariant: MainColors.grey400,
      // shadows and scrims
      shadow: MainColors.grey800,
      scrim: MainColors.grey900,
      // containers
      surfaceContainerLowest: MainColors.grey600,
      // avatar placeholder
      surfaceContainerLow: MainColors.grey700,
      // cards and tab bar
      surfaceContainer: MainColors.green400,
      // group chat background and chat action bar
      surfaceContainerHigh: MainColors.grey300,
      // videos background
      surfaceContainerHighest: MainColors.grey100,
      // free banner
      tertiaryFixedDim: MainColors.black100,
      onTertiaryFixedVariant: MainColors.white100,
      // unused
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
