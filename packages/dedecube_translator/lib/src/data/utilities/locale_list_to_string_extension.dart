import 'dart:ui';

import 'package:dedecube_translator/src/data/utilities/locale_to_string_extension.dart';

extension LocaleListToString on List<Locale> {
  String asStringList() {
    return map((locale) => locale.asString()).join(',');
  }
}
