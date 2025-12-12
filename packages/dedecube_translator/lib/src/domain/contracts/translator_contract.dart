import 'package:dedecube_translator/src/data/configs/translator_config.dart';
import 'package:flutter/widgets.dart';

/// Defines the contract for translator functionality.
abstract class TranslatorContract {
  /// Gets the current [TranslatorConfig].
  TranslatorConfig get config;

  /// Sets a new [TranslatorConfig].
  set config(TranslatorConfig config);

  /// The current locale being used by the translator.
  Locale get currentLocale;

  /// Stream controller that broadcasts locale changes.
  Stream<Locale?> get localeStream;

  /// Translates a given [key] into the localized string.
  ///
  /// - [key]: The key to translate.
  /// - [context]: The build context (optional). If not provided, the navigator key's
  ///   current context will be used.
  /// - [arguments]: Any arguments for the translation.
  ///
  /// Returns the localized string associated with [key], or [key] if translation fails.
  String translate(
    String key, {
    BuildContext? context,
    Map<String, String>? arguments,
  });

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
  Future<void> setLocale(
    Locale locale, {
    BuildContext? context,
  });
}
