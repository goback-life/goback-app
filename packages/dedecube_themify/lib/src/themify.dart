import 'dart:async';

import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_themify/src/data/configs/themify_config.dart';
import 'package:dedecube_themify/src/data/providers/themify_config_provider.dart';
import 'package:dedecube_themify/src/data/utilities/theme_utilities.dart';
import 'package:dedecube_themify/src/domain/contracts/themify_contract.dart';
import 'package:dedecube_themify/src/domain/typedefs/themify_typedef.dart';

/// A [Themify] class that handles theme operations.
///
/// This class is responsible for managing the theme configuration and allows
/// dynamic updates to the application's theme. It loads, validates, and persists
/// theme data, and broadcasts any changes to subscribed listeners.
class Themify implements ThemifyContract {
  /// Creates a [Themify] instance with the provided [ThemifyConfig].
  ///
  /// The constructor performs these steps:
  /// 1. Applies the current configuration to the themify provider.
  /// 2. Loads and applies the initial theme (including any persisted theme data).
  /// 3. Validates the loaded theme against the supported themes.
  Themify(this._config) {
    _applyConfigProvider();
    _applyTheme();
  }

  /// Internal configuration for theming.
  ///
  /// Contains settings such as the supported themes and the initial theme.
  ThemifyConfig _config;

  /// Gets the current theming configuration.
  @override
  ThemifyConfig get config => _config;

  /// Updates the theming configuration.
  ///
  /// When set, the new configuration is applied, the corresponding theme is loaded,
  /// validated, and any change is broadcast to subscribed listeners.
  @override
  set config(ThemifyConfig config) {
    _updateConfig(config);
  }

  /// Updates the internal configuration, reloads and validates the theme,
  /// and then broadcasts the updated theme.
  void _updateConfig(ThemifyConfig newConfig) async {
    _config = newConfig;
    _applyConfigProvider();
    await _applyTheme();
    await _broadcastThemeUpdate();
  }

  /// The currently active theme.
  @override
  late Themable currentTheme;

  /// Stream controller for broadcasting theme changes.
  ///
  /// Subscribers will be notified whenever the theme is updated.
  final StreamController<Themable?> _themeStream =
      StreamController<Themable?>.broadcast();

  /// A stream that emits updates when the current theme changes.
  @override
  Stream<Themable?> get themeStream => _themeStream.stream;

  /// Sets a new theme, validates it, persists the change, and broadcasts the update.
  ///
  /// The method performs these actions:
  /// 1. Sets the received theme as the current theme.
  /// 2. Validates the theme against the supported themes in the configuration.
  /// 3. Persists the validated theme to storage.
  /// 4. Broadcasts the updated theme to all subscribers.
  @override
  Future<void> setTheme(
    Themable theme,
  ) async {
    currentTheme = theme;

    currentTheme = await ThemeUtilities.validateTheme(currentTheme, _config);

    ThemeUtilities.saveToStorage();

    await _broadcastThemeUpdate();
  }

  /// Applies the current configuration to the themify configuration provider.
  void _applyConfigProvider() {
    riverpodContainer()
        .read(themifyConfigNotifierProvider.notifier)
        .themeConfig = _config;
  }

  /// Loads and validates the theme configuration.
  ///
  /// This method performs these actions:
  /// 1. Initializes the current theme from the configuration's initial theme.
  /// 2. Attempts to load any persisted theme data from storage.
  /// 3. Validates that the resolved theme is either the default theme or included
  ///    in the list of supported themes.
  /// 4. Persists the validated theme back to storage.
  Future<void> _applyTheme() async {
    currentTheme = _config.initialTheme;

    ThemeUtilities.loadFromStorage();

    currentTheme = await ThemeUtilities.validateTheme(currentTheme, _config);

    ThemeUtilities.saveToStorage();
  }

  /// Broadcasts the updated theme to all subscribers.
  ///
  /// This method adds the current theme to the theme stream so that any listeners
  /// can react to the change.
  Future<void> _broadcastThemeUpdate() async {
    _themeStream.add(currentTheme);
  }
}

/// A global accessor for the Themify instance.
ThemifyContract get themify => GetIt.I<ThemifyContract>();
