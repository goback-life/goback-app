import 'package:flutter/widgets.dart';

/// Defines the contract for translator configuration.
abstract class TranslatorConfigContract {
  /// The initial [Locale] to be used by the translator.
  Locale get initialLocale;

  /// A flag to determine if the operating system locale should be used.
  bool get shouldUseOperatingSystemLocale;

  /// The fallback [Locale] used when no specific locale is provided.
  Locale get fallbackLocale;

  /// A list of supported [Locale]s for the application.
  List<Locale> get supportedLocales;

  /// The base path where translation files are located.
  String get path;

  /// The [GlobalKey] associated with the navigator, used for navigation purposes.
  GlobalKey<NavigatorState>? get navigatorKey;
}
