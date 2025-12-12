import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_themify/src/domain/typedefs/themify_typedef.dart';

/// Extension on [Themable] that automatically derives a theme name from its runtime type.
///
/// The [name] property converts the runtime type (classified in CamelCase) into a snake_case
/// string. For example, if an instance's runtime type is `DefaultTheme`, [name] will return
/// `default_theme`.
extension ThemifyThemeNameExtension on Themable {
  String get name => runtimeType.toString().snakeCase();
}
