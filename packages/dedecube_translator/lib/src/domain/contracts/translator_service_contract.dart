import 'package:flutter/widgets.dart';

/// Defines the contract for translator service.
///
/// Any implementation of this contract must provide methods to translate strings
/// based on localization configurations.
abstract class TranslatorServiceContract {
  /// Translates a given key into the localized string.
  String? translate(
    String key, {
    BuildContext? context,
    Map<String, String>? arguments,
  });

  /// Updates the application's current locale.
  Future<void> setLocale(
    Locale locale, {
    required bool reassemble,
    BuildContext? context,
  });
}
