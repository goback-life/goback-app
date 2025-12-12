import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_themify/dedecube_themify.dart';

final themeProvider = StreamProvider<ThemifyThemeContract?>((ref) {
  return themify.themeStream;
});
