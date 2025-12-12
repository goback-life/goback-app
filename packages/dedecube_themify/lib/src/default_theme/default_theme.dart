import 'package:dedecube_themify/src/domain/typedefs/themify_typedef.dart';
import 'package:flutter/material.dart';

class DefaultTheme extends Themable {
  @override
  ColorScheme get colorScheme {
    return ColorScheme.fromSeed(
      seedColor: Colors.greenAccent,
      brightness: Brightness.light,
    );
  }

  @override
  ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.light,
      primaryColorLight: Colors.lightGreen,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.green,
      ),
    );
  }
}
