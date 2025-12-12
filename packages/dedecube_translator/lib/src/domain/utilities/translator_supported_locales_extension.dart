import 'package:dedecube_translator/src/domain/contracts/translator_contract.dart';
import 'package:flutter/widgets.dart';

/// Extension on [TranslatorContract] to provide access to supported locales.
extension TranslatorSupportedLocalesExtension on TranslatorContract {
  /// Retrieves the list of supported [Locale]s from the translator configuration.
  ///
  /// Returns a list of [Locale] objects representing the supported locales.
  ///
  /// Example:
  ///
  /// ```dart
  /// List<Locale> locales = translator.supportedLocales;
  /// ```
  List<Locale> get supportedLocales => config.supportedLocales;
}
