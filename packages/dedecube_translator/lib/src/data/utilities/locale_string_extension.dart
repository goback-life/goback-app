import 'dart:ui';

extension LocaleStringExtension on String? {
  static const String _defaultLocale = 'en';

  Locale toLocale() {
    if (this == null || this!.isEmpty) {
      return const Locale(_defaultLocale);
    }
    final parts = this!.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(this!);
  }

  List<Locale> toLocaleList() {
    if (this == null || this!.isEmpty) {
      return [const Locale(_defaultLocale)];
    }
    return this!.split(',').map((e) => e.toLocale()).toList();
  }
}
