import 'package:dedecube_themify/src/data/configs/themify_config.dart';
import 'package:dedecube_themify/src/data/exceptions/themify_theme_not_found_exception.dart';
import 'package:dedecube_themify/src/data/utilities/themify_theme_name_extension.dart';
import 'package:dedecube_themify/src/default_theme/default_theme.dart';
import 'package:dedecube_themify/src/domain/typedefs/themify_typedef.dart';

class ThemeUtilities {
  /// Checks the validity of the [currentTheme].
  ///
  /// This method performs the following actions:
  ///   1. Verifies if the [currentTheme] is the default theme.
  ///   2. If not, it checks whether the [currentTheme] exists in the list of supported themes
  ///      defined in the [config].
  ///   3. If the theme is not found in the supported list, it throws a [ThemifyThemeNotFoundException].
  static Future<Themable> validateTheme(
    Themable currentTheme,
    ThemifyConfig config,
  ) async {
    if (currentTheme.name == DefaultTheme().name) {
      return currentTheme;
    }

    final exists =
        config.supportedThemes.any((theme) => theme.name == currentTheme.name);

    if (!exists) {
      throw ThemifyThemeNotFoundException(currentTheme);
    }

    return currentTheme;
  }

  /// Retrieves the currentTheme from persistent storage.
  ///
  /// This method retrieves the theme data that was previously persisted in storage.
  /// The implementation should include:
  ///   - Reading the persisted theme information from storage (e.g., file, database, or shared preferences).
  ///   - Returning the retrieved theme or null if no theme is stored.
  static void loadFromStorage() async {
    // TODO: get from storage
    return null;
  }

  /// Saves the currentTheme to persistent storage.
  ///
  /// This method is responsible for persisting the current theme data
  /// The implementation should include:
  ///   - Serializing the current theme data.
  ///   - Saving it to a persistent storage medium (e.g., file, database, or shared preferences).
  static void saveToStorage() {
    // TODO: set in storage
  }
}
