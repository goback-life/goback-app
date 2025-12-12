import 'dart:io';

import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/features/supabase/utilities/supabase_buckets.dart';
import 'package:image/image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for uploading media files and thumbnails for posts.
class PostMediaUploadService {
  const PostMediaUploadService({required this.supabaseClient});

  final SupabaseClient supabaseClient;

  /// Uploads multiple media files to Supabase storage.
  /// Returns a list of storage paths for the uploaded files.
  Future<List<String>> uploadMediaFiles(
    String userId,
    List<File> mediaFiles,
    ContentType contentType, [
    String? postId,
  ]) async {
    final uploadedUrls = <String>[];

    for (int i = 0; i < mediaFiles.length; i++) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await Future.delayed(const Duration(milliseconds: 2));

      final file = mediaFiles[i];
      final extension = getExtensionFromContentType(contentType, file);
      final fileName = 'media_${timestamp}_$i.$extension';
      final path = postId != null
          ? '$userId/$postId/$fileName'
          : '$userId/$fileName';

      await supabaseClient.storage
          .from(SupabaseBuckets.postMedia)
          .upload(path, file);

      uploadedUrls.add(path);
    }

    return uploadedUrls;
  }

  /// Uploads a thumbnail file to Supabase storage.
  /// Returns the storage path for the uploaded thumbnail.
  Future<String> uploadThumbnail(
    String userId,
    File thumbnailFile,
    String postId,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'thumbnail_$timestamp.jpg';
    final path = '$userId/$postId/$fileName';

    await supabaseClient.storage
        .from(SupabaseBuckets.postMedia)
        .upload(path, thumbnailFile);

    return path;
  }

  /// Gets the file extension based on content type.
  String getExtensionFromContentType(ContentType contentType, File file) {
    switch (contentType) {
      case ContentType.video:
        return 'mp4';
      case ContentType.audio:
        return 'mp3';
      case ContentType.image:
      case ContentType.doubleImage:
        final path = file.path.toLowerCase();
        if (path.endsWith('.png')) {
          return 'png';
        }
        return 'jpg';
    }
  }

  /// Gets the dimensions of an image file.
  /// Returns a tuple of (width, height).
  /// Returns (1080, 1080) as fallback if dimensions cannot be determined.
  Future<(int, int)> getImageDimensions(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = decodeImage(bytes);
    if (image != null) {
      return (image.width, image.height);
    }
    return (1080, 1080);
  }
}
