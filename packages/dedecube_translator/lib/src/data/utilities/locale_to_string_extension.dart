import 'dart:ui';

extension LocaleToStringExtension on Locale {
  String asString() {
    return countryCode != null && countryCode!.isNotEmpty
        ? '${languageCode}_$countryCode'
        : languageCode;
  }
}
