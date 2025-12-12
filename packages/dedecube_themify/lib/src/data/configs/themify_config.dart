import 'package:dedecube_themify/src/default_theme/default_theme.dart';
import 'package:dedecube_themify/src/domain/contracts/themify_config_contract.dart';
import 'package:dedecube_themify/src/domain/typedefs/themify_typedef.dart';

class ThemifyConfig implements ThemifyConfigContract {
  ThemifyConfig({
    List<Themable>? supportedThemes,
    Themable? initialTheme,
  })  : supportedThemes = supportedThemes ?? [],
        initialTheme = initialTheme ?? _defaultThemeData;

  static final Themable _defaultThemeData = DefaultTheme();

  @override
  final List<Themable> supportedThemes;

  @override
  final Themable initialTheme;
}
