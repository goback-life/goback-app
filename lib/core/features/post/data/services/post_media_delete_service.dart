import 'package:cloudless/core/features/supabase/utilities/supabase_buckets.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for deleting media files and thumbnails from storage.
class PostMediaDeleteService {
  const PostMediaDeleteService({required this.supabaseClient});

  final SupabaseClient supabaseClient;

  /// Deletes all media files associated with a post from storage.
  Future<void> deletePostMediaFiles(String authorId, String postId) async {
    try {
      final folderPath = '$authorId/$postId';

      final files = await supabaseClient.storage
          .from(SupabaseBuckets.postMedia)
          .list(path: folderPath);

      if (files.isEmpty) {
        logger.info('No media files found for post $postId');
        return;
      }

      final filePaths = files
          .map((file) => '$folderPath/${file.name}')
          .toList();

      await supabaseClient.storage
          .from(SupabaseBuckets.postMedia)
          .remove(filePaths);

      logger.info('Deleted ${filePaths.length} media files for post $postId');
    } catch (e) {
      logger.error(
        'Failed to delete media files for post $postId',
        exception: e,
      );
    }
  }

  /// Deletes a thumbnail file from storage given its URL.
  Future<void> deleteThumbnailByUrl(String thumbnailUrl) async {
    try {
      final uri = Uri.parse(thumbnailUrl);
      final pathSegments = uri.pathSegments;

      final bucketIndex = pathSegments.indexOf(SupabaseBuckets.postMedia);
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        logger.info('Invalid thumbnail URL format: $thumbnailUrl');
        return;
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      await supabaseClient.storage.from(SupabaseBuckets.postMedia).remove([
        filePath,
      ]);
    } catch (e) {
      logger.error('Failed to delete thumbnail by URL', exception: e);
    }
  }
}
