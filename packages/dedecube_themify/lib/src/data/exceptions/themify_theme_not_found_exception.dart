import 'package:dedecube_themify/src/domain/typedefs/themify_typedef.dart';

class ThemifyThemeNotFoundException implements Exception {
  ThemifyThemeNotFoundException(this.theme);
  final Themable theme;

  @override
  String toString() =>
      'ThemifyThemeNotFoundException: Unable to retrieve the theme $theme.';
}
