import 'dart:async';

class TranslatorVersioning {
  static final StreamController<int> _versionController =
      StreamController<int>.broadcast();
  static int _version = 0;

  static int get version => _version;

  /// Stream that emits a new integer every time the translations are updated.
  static Stream<int> get versionStream => _versionController.stream;

  /// Call this method every time the translation file (e.g., it.json) is updated.
  static void updateTranslations() {
    _version++;
    _versionController.add(_version);
  }

  static void dispose() {
    _versionController.close();
  }
}
