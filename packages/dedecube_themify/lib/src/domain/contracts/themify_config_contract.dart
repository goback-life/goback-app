import 'package:dedecube_themify/src/domain/typedefs/themify_typedef.dart';

/// A contract defining the required theme configuration for an application.
abstract class ThemifyConfigContract {
  /// A list of supported themes for the application.
  List<Themable> get supportedThemes;

  /// The initial theme to be used by the application.
  Themable get initialTheme;
}
