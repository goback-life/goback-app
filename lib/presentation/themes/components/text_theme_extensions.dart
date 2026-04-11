import 'package:flutter/material.dart';

extension TextThemeExtensions on TextTheme {
  TextTheme broadCustomization({
    Color? color,
    String? family,
    String? displayFamily,
    String? headlineFamily,
    String? titleFamily,
    String? bodyFamily,
    String? labelFamily,
    FontWeight? displayWeight,
    FontWeight? headlineWeight,
    FontWeight? titleWeight,
    FontWeight? bodyWeight,
    FontWeight? labelWeight,
  }) => applyColor(color)
      .applyFamilies(
        displayFamily: displayFamily ?? family,
        headlineFamily: headlineFamily ?? family,
        titleFamily: titleFamily ?? family,
        bodyFamily: bodyFamily ?? family,
        labelFamily: labelFamily ?? family,
      )
      .applyWeights(
        displayWeight: displayWeight,
        headlineWeight: headlineWeight,
        titleWeight: titleWeight,
        bodyWeight: bodyWeight,
        labelWeight: labelWeight,
      );
  TextTheme applyWeights({
    FontWeight? displayWeight,
    FontWeight? headlineWeight,
    FontWeight? titleWeight,
    FontWeight? bodyWeight,
    FontWeight? labelWeight,
  }) => merge(
    TextTheme(
      displayLarge: TextStyle(fontWeight: displayWeight),
      displayMedium: TextStyle(fontWeight: displayWeight),
      displaySmall: TextStyle(fontWeight: displayWeight),
      headlineLarge: TextStyle(fontWeight: headlineWeight),
      headlineMedium: TextStyle(fontWeight: headlineWeight),
      headlineSmall: TextStyle(fontWeight: headlineWeight),
      titleLarge: TextStyle(fontWeight: titleWeight),
      titleMedium: TextStyle(fontWeight: titleWeight),
      titleSmall: TextStyle(fontWeight: titleWeight),
      bodyLarge: TextStyle(fontWeight: bodyWeight),
      bodyMedium: TextStyle(fontWeight: bodyWeight),
      bodySmall: TextStyle(fontWeight: bodyWeight),
      labelLarge: TextStyle(fontWeight: labelWeight),
      labelMedium: TextStyle(fontWeight: labelWeight),
      labelSmall: TextStyle(fontWeight: labelWeight),
    ),
  );
  TextTheme applyFamilies({
    String? displayFamily,
    String? headlineFamily,
    String? titleFamily,
    String? bodyFamily,
    String? labelFamily,
  }) => merge(
    TextTheme(
      displayLarge: TextStyle(fontFamily: displayFamily),
      displayMedium: TextStyle(fontFamily: displayFamily),
      displaySmall: TextStyle(fontFamily: displayFamily),
      headlineLarge: TextStyle(fontFamily: headlineFamily),
      headlineMedium: TextStyle(fontFamily: headlineFamily),
      headlineSmall: TextStyle(fontFamily: headlineFamily),
      titleLarge: TextStyle(fontFamily: titleFamily),
      titleMedium: TextStyle(fontFamily: titleFamily),
      titleSmall: TextStyle(fontFamily: titleFamily),
      bodyLarge: TextStyle(fontFamily: bodyFamily),
      bodyMedium: TextStyle(fontFamily: bodyFamily),
      bodySmall: TextStyle(fontFamily: bodyFamily),
      labelLarge: TextStyle(fontFamily: labelFamily),
      labelMedium: TextStyle(fontFamily: labelFamily),
      labelSmall: TextStyle(fontFamily: labelFamily),
    ),
  );

  TextTheme applyColor(Color? color) => merge(
    TextTheme(
      displayLarge: TextStyle(color: color),
      displayMedium: TextStyle(color: color),
      displaySmall: TextStyle(color: color),
      headlineLarge: TextStyle(color: color),
      headlineMedium: TextStyle(color: color),
      headlineSmall: TextStyle(color: color),
      titleLarge: TextStyle(color: color),
      titleMedium: TextStyle(color: color),
      titleSmall: TextStyle(color: color),
      bodyLarge: TextStyle(color: color),
      bodyMedium: TextStyle(color: color),
      bodySmall: TextStyle(color: color),
      labelLarge: TextStyle(color: color),
      labelMedium: TextStyle(color: color),
      labelSmall: TextStyle(color: color),
    ),
  );
}
