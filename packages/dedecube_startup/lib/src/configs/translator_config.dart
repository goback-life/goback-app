import 'package:dedecube_environment/dedecube_environment.dart';
import 'package:dedecube_startup/src/utilities/startup_navigator_key.dart';
import 'package:dedecube_translator/dedecube_translator.dart';

/// Configuration for the translator service.
///
/// This getter provides a [TranslatorConfig] instance with settings loaded from environment variables:
/// * initialLocale: The default locale when app starts ('TRANSLATOR_INITIAL_LOCALE')
/// * shouldUseOperatingSystemLocale: Whether to use the device locale ('TRANSLATOR_SHOULD_USE_OPERATING_SYSTEM_LOCALE')
/// * fallbackLocale: The locale to use when a translation is not available ('TRANSLATOR_FALLBACK_LOCALE')
/// * supportedLocales: List of locales supported by the application ('TRANSLATOR_SUPPORTED_LOCALES')
/// * path: Path to translation files ('TRANSLATOR_PATH')
/// * navigatorKey: Global navigator key for the app
TranslatorConfig get translatorConfig {
  final translatorConfig = TranslatorConfig(
    initialLocale: environment.tryGetString('TRANSLATOR_INITIAL_LOCALE'),
    shouldUseOperatingSystemLocale: environment.tryGetBool(
      'TRANSLATOR_SHOULD_USE_OPERATING_SYSTEM_LOCALE',
    ),
    fallbackLocale: environment.tryGetString('TRANSLATOR_FALLBACK_LOCALE'),
    supportedLocales: environment.tryGetString('TRANSLATOR_SUPPORTED_LOCALES'),
    path: environment.tryGetString('TRANSLATOR_PATH'),
    navigatorKey: startupNavigatorKey,
  );

  return translatorConfig;
}
