import 'dart:io';

import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Helper for extracting thumbnails from videos.
class VideoThumbnailHelper {
  /// Extracts the first frame of a video as a thumbnail.
  ///
  /// Returns a [File] containing the thumbnail as a JPG image.
  /// Throws an exception in case of error.
  static Future<File> extractThumbnail(File videoFile) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: (await Directory.systemTemp.createTemp()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 1920,
        quality: 85,
        timeMs: 0,
      );

      if (thumbnailPath == null) {
        throw Exception('Failed to generate video thumbnail');
      }

      final thumbnailFile = File(thumbnailPath);

      return thumbnailFile;
    } catch (e, stackTrace) {
      logger.error(
        'Error extracting video thumbnail',
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Extracts the first frame of a video and returns the thumbnail path.
  ///
  /// Returns the path as a [String], or `null` if extraction fails.
  static Future<String?> extractThumbnailPath(String videoPath) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await Directory.systemTemp.createTemp()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 1920,
        quality: 85,
        timeMs: 0,
      );

      return thumbnailPath;
    } catch (e, stackTrace) {
      logger.error(
        'Error extracting video thumbnail path',
        exception: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
