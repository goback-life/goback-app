import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

/// Helper to convert asset files to temporary File instances
class AssetToFileHelper {
  /// Copies an asset to a temporary file and returns the File
  /// 
  /// [assetPath] should be the path relative to the assets directory
  /// (e.g., 'assets/images/pngs/app_icon_full.png')
  static Future<File> copyAssetToFile(String assetPath) async {
    try {
      // Load asset as byte data
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = assetPath.split('/').last;
      final tempFile = File('${tempDir.path}/$fileName');

      // Write bytes to temp file
      await tempFile.writeAsBytes(bytes);

      logger.info('Copied asset $assetPath to temporary file: ${tempFile.path}');
      return tempFile;
    } catch (e, stackTrace) {
      logger.error(
        'Error copying asset to file',
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Copies the app icon to a temporary file
  static Future<File> copyAppIconToFile() async {
    return copyAssetToFile('assets/images/pngs/app_icon_full.png');
  }
}

