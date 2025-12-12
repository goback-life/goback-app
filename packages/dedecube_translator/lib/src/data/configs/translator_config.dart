import 'package:dedecube_translator/src/data/utilities/locale_string_extension.dart';
import 'package:dedecube_translator/src/domain/contracts/translator_config_contract.dart';
import 'package:flutter/widgets.dart';

/// Implementation of [TranslatorConfigContract] to manage localization configurations.
///
/// This class handles the initialization and updates of translator settings.
class TranslatorConfig implements TranslatorConfigContract {
  TranslatorConfig({
    String? initialLocale,
    bool? shouldUseOperatingSystemLocale,
    String? fallbackLocale,
    String? supportedLocales,
    String? path,
    this.navigatorKey,
  })  : initialLocale = initialLocale.toLocale(),
        shouldUseOperatingSystemLocale =
            shouldUseOperatingSystemLocale ?? false,
        fallbackLocale = fallbackLocale.toLocale(),
        supportedLocales = supportedLocales.toLocaleList(),
        path = path ?? _defaultPath;

  /// The default path for translation assets.
  static const String _defaultPath = 'assets/translations';

  /// The initial [Locale] to be used by the translator.
  @override
  final Locale initialLocale;

  /// A flag to determine if the operating system locale should be used.
  @override
  final bool shouldUseOperatingSystemLocale;

  /// The fallback [Locale] used when no specific locale is provided.
  @override
  final Locale fallbackLocale;

  /// A list of supported [Locale]s for the application.
  @override
  final List<Locale> supportedLocales;

  /// The base path where translation files are located.
  @override
  final String path;

  /// The [GlobalKey] associated with the navigator, used for navigation purposes.
  @override
  final GlobalKey<NavigatorState>? navigatorKey;
}
