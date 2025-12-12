import 'package:dedecube_themify/src/data/configs/themify_config.dart';
import 'package:dedecube_themify/src/domain/typedefs/themify_typedef.dart';

/// A contract defining the required theme properties for an application.
abstract class ThemifyContract {
  /// Gets the current theming configuration.
  ///
  /// Returns a [ThemifyConfig] that contains settings such as the supported themes
  /// and the initial theme to be applied.
  ThemifyConfig get config;

  /// Sets a new theming configuration.
  ///
  /// Updating the configuration should trigger reloading and application of the
  /// corresponding theme.
  set config(ThemifyConfig config);

  /// The current theme being used by the application.
  ///
  /// Provides access to detailed theme properties including colors, typography,
  /// and other stylistic elements.
  Themable get currentTheme;

  /// A stream that broadcasts theme changes.
  ///
  /// Subscribers listening to this stream will be notified whenever the active theme
  /// is updated.
  Stream<Themable?> get themeStream;

  /// Updates the current theme if it is supported and refreshes the theme settings.
  ///
  /// This method performs the following actions:
  ///   1. Sets the [currentTheme] to the new theme provided.
  ///   2. Validates that the new theme is supported by the current configuration.
  ///   3. Saves the validated theme to persistent storage.
  ///   4. Notifies all subscribed listeners about the theme change.
  Future<void> setTheme(
    Themable theme,
  );
}
