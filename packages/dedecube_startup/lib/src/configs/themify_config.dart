import 'package:dedecube_environment/dedecube_environment.dart';
import 'package:dedecube_startup/src/utilities/iterable_extensions.dart';
import 'package:dedecube_themify/dedecube_themify.dart';

/// Configuration for the themify service.
///
/// This function provides a [ThemifyConfig] instance with settings loaded from environment variables:
/// * supportedThemes: List of themes supported by the application
/// * initialTheme: The initial theme when the app starts ('THEMIFY_INITIAL_THEME')
ThemifyConfig themifyConfig(List<Themable>? themes, Themable? initialTheme) {
  final themifyConfig = ThemifyConfig(
    supportedThemes: themes,
    initialTheme: initialTheme ??
        _resolveInitialTheme(
          environment.tryGetString('THEMIFY_INITIAL_THEME'),
          themes,
        ),
  );

  return themifyConfig;
}

/// Resolves the initial theme based on the provided theme name and list of themes.
///
/// This function attempts to find a theme in the list of themes that matches the provided theme name.
/// If no matching theme is found, it returns null.
Themable? _resolveInitialTheme(String? themeName, List<Themable>? themes) {
  if (themeName == null) {
    return null;
  }
  return themes?.firstWhereOrNull(
    (theme) =>
        theme.runtimeType.toString().toLowerCase() ==
        '${themeName.toLowerCase()}theme',
  );
}
