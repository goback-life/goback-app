import 'package:flutter/services.dart';

class AssetUtilities {
  /// Checks if an asset exists at the given [path].
  ///
  /// - [path]: The asset path to check.
  ///
  /// Returns `true` if the asset exists, `false` otherwise.
  ///
  /// Uses [rootBundle] to attempt loading the asset. If an exception occurs, it assumes
  /// the asset does not exist.
  static Future<bool> checkIfExists(String path) async {
    try {
      await rootBundle.loadString(path);
      return true;
    } catch (e) {
      return false;
    }
  }
}
