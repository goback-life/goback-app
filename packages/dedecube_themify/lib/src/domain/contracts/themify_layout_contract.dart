import 'package:dedecube_themify/src/domain/typedefs/themify_typedef.dart';

/// A contract defining the required layout properties for an application.
abstract class ThemifyLayoutContract {
  const ThemifyLayoutContract();

  /// Returns the layout configuration for this instance.
  ///
  /// The returned [LayoutConfig] contains properties that control the structural
  /// aspects of the user interface, including padding, margins, spacing, and dimensions.
  LayoutConfig get config;
}
