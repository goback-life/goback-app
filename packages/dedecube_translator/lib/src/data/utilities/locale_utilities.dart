import 'dart:ui';

import 'package:dedecube_translator/src/data/configs/translator_config.dart';
import 'package:dedecube_translator/src/data/exceptions/translator_file_not_found_exception.dart';
import 'package:dedecube_translator/src/data/exceptions/translator_locale_not_found_exception.dart';
import 'package:dedecube_translator/src/data/utilities/asset_utilities.dart';

class LocaleUtilities {
  /// Checks the validity of the [currentLocale].
  ///
  /// Ensures that the [currentLocale] is within the list of supported locales and that
  /// the corresponding locale file exists. If the [currentLocale] is unsupported or
  /// its locale file is missing, attempts to fallback to the config.fallbackLocale.
  ///
  /// Throws a [TranslatorLocaleNotFoundException] if the fallback locale is also unsupported.
  /// Throws a [TranslatorFileNotFoundException] if the locale file does not exist and no
  /// fallback locale is available.
  static Future<Locale> validateLocale(
    Locale currentLocale,
    TranslatorConfig config,
  ) async {
    if (!config.supportedLocales.contains(currentLocale)) {
      if (config.supportedLocales.contains(config.fallbackLocale)) {
        return config.fallbackLocale;
      } else {
        throw TranslatorLocaleNotFoundException(currentLocale);
      }
    }

    final String localeFilePath =
        '${config.path}/${currentLocale.languageCode}.json';
    if (!await AssetUtilities.checkIfExists(localeFilePath)) {
      final String fallbackFilePath =
          '${config.path}/${config.fallbackLocale.languageCode}.json';

      if (await AssetUtilities.checkIfExists(fallbackFilePath)) {
        return config.fallbackLocale;
      } else {
        throw TranslatorFileNotFoundException(fallbackFilePath);
      }
    }

    return currentLocale;
  }

  /// Loads the locale from the operating system if it is supported.
  ///
  /// Retrieves the system locale using [PlatformDispatcher]. If the locale's language code
  /// is supported, sets it as the current locale.
  static Locale loadFromOS() {
    final Locale osLocale = PlatformDispatcher.instance.locale;
    final String languageCode = osLocale.languageCode;
    final Locale locale = Locale(languageCode);

    return locale;
  }

  /// Get the currentLocale from persistent storage.
  ///
  /// This method performs the following actions:
  /// - ...
  static void loadFromStorage() async {
    return null;

    // TODO: get from storage
  }

  /// Set the currentLocale to persistent storage.
  ///
  /// This method performs the following actions:
  /// - ...
  static void saveToStorage() {
    // TODO: set in storage
  }
}
