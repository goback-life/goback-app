import 'package:flutter/material.dart';

class MainTextButtonTheme {
  static TextButtonThemeData theme(ColorScheme? colorScheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(overlayColor: Colors.transparent),
    );
  }
}
