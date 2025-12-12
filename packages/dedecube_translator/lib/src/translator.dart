import 'dart:async';

import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_translator/src/data/configs/translator_config.dart';
import 'package:dedecube_translator/src/data/providers/translator_config_provider.dart';
import 'package:dedecube_translator/src/data/utilities/locale_utilities.dart';
import 'package:dedecube_translator/src/domain/contracts/translator_contract.dart';
import 'package:dedecube_translator/src/domain/providers/set_locale_provider.dart';
import 'package:dedecube_translator/src/domain/providers/translate_provider.dart';
import 'package:flutter/widgets.dart';

/// A [Translator] class to handle translation operations.
///
/// This class provides methods to translate strings based on localization
/// configurations and allows updating the translation configuration dynamically.
class Translator implements TranslatorContract {
  /// Creates a [Translator] instance with the given [TranslatorConfig].
  ///
  /// - Initializes the translator with the provided [config].
  /// - Sets the initial locale and loads the locale from the operating system if configured.
  /// - Checks the validity of the current locale and saves it.
  Translator(this._config) {
    _applyConfigProvider();
    _applyLocale();
  }

  /// The internal configuration for the translator.
  ///
  /// Holds settings such as supported locales, fallback locale, and asset paths.
  TranslatorConfig _config;

  /// Gets the current [TranslatorConfig].
  ///
  /// Provides access to the current logging configuration.
  @override
  TranslatorConfig get config => _config;

  /// Sets a new [TranslatorConfig].
  ///
  /// - Updates the internal configuration.
  /// - Updates the initial locale and loads the locale from the operating system if configured.
  /// - Checks the validity of the current locale and saves it.
  /// - Updates the locale and broadcasts the change after a short delay.
  @override
  set config(TranslatorConfig config) {
    _updateConfig(config);
  }

  void _updateConfig(TranslatorConfig newConfig) async {
    _config = newConfig;
    _applyConfigProvider();
    await _applyLocale();
    await _broadcastLocaleUpdate(reassemble: true);
  }

  /// The current locale being used by the translator.
  @override
  late Locale currentLocale;

  /// Stream controller that broadcasts locale changes.
  ///
  /// Listeners can subscribe to [localeStream] to receive updates when the locale changes.
  final StreamController<Locale?> _localeStream =
      StreamController<Locale?>.broadcast();

  /// A stream of [Locale] that emits when the current locale changes.
  @override
  Stream<Locale?> get localeStream => _localeStream.stream;

  /// Translates a given [key] into the localized string.
  ///
  /// - [key]: The key to translate.
  /// - [context]: The build context (optional). If not provided, the navigator key's
  ///   current context will be used.
  /// - [arguments]: Any arguments for the translation.
  ///
  /// Returns the localized string associated with [key], or [key] if translation fails.
  @override
  String translate(
    String key, {
    BuildContext? context,
    Map<String, String>? arguments,
  }) {
    return riverpodContainer().read(
          translateProvider(
            key,
            context: context,
            arguments: arguments,
          ),
        ) ??
        key;
  }

  /// Updates the current locale if it is supported and refreshes the translations.
  ///
  /// - [locale]: The new locale to set.
  /// - [context]: The build context (optional). If not provided, the navigator key's
  ///   current context will be used.
  ///
  /// This method performs the following actions:
  /// - Sets the [currentLocale] to the new locale.
  /// - Checks if the new locale is supported and has an existing locale file.
  /// - Saves the new locale to storage.
  /// - Updates the locale in the application and notifies listeners.
  @override
  Future<void> setLocale(
    Locale locale, {
    BuildContext? context,
  }) async {
    currentLocale = locale;

    currentLocale =
        await LocaleUtilities.validateLocale(currentLocale, _config);

    LocaleUtilities.saveToStorage();

    if (context != null && !context.mounted) {
      return;
    }

    await _broadcastLocaleUpdate(reassemble: false, context: context);
  }

  void _applyConfigProvider() {
    riverpodContainer()
        .read(translatorConfigNotifierProvider.notifier)
        .translatorConfig = _config;
  }

  /// Configure the locale.
  Future<void> _applyLocale() async {
    currentLocale = (_config.shouldUseOperatingSystemLocale)
        ? LocaleUtilities.loadFromOS()
        : _config.initialLocale;

    LocaleUtilities.loadFromStorage();

    currentLocale =
        await LocaleUtilities.validateLocale(currentLocale, _config);

    LocaleUtilities.saveToStorage();
  }

  /// Updates the current locale and broadcasts the change.
  ///
  /// - [context]: The build context, if any.
  ///
  /// This method performs the following actions:
  /// - Calls the [setLocaleProvider] to update the locale in the application.
  /// - Emits the updated [currentLocale] to the [_localeStream].
  Future<void> _broadcastLocaleUpdate({
    required bool reassemble,
    BuildContext? context,
  }) async {
    await riverpodContainer().read(
      setLocaleProvider(currentLocale, reassemble: reassemble, context: context)
          .future,
    );

    _localeStream.add(currentLocale);
  }
}

TranslatorContract get translator => GetIt.I<TranslatorContract>();
