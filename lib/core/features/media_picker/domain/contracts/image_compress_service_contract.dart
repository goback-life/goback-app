import 'dart:io';

abstract interface class ImageCompressServiceContract {
  /// Compress an image file and return the new compressed file.
  ///
  /// [file]: the image file to compress.
  /// [initialQuality]: initial compression quality (default 80).
  /// [minQuality]: minimum accepted quality (default 30).
  /// [maxSizeBytes]: desired maximum size in bytes (default 2MB).
  ///
  /// Returns a compressed [File] if compression is successful, otherwise null.

  Future<File?> compressImage(
    File file, {
    int initialQuality,
    int minQuality,
    int maxSizeBytes,
  });
}
