import 'dart:ui';

import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_translator/dedecube_translator.dart';

final localeProvider = StreamProvider<Locale?>((ref) {
  return translator.localeStream;
});
