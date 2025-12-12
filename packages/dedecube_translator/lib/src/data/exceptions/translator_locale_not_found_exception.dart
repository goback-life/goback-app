import 'package:dedecube_translator/src/data/utilities/locale_to_string_extension.dart';
import 'package:flutter/widgets.dart';

class TranslatorLocaleNotFoundException implements Exception {
  TranslatorLocaleNotFoundException(this.locale);
  final Locale locale;

  @override
  String toString() =>
      'TranslatorLocaleNotFoundException: Unable to retrieve the locale ${locale.asString()}.';
}
