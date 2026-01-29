import 'package:cloudless/core/features/storage/data/providers/signed_url_provider.dart';
import 'package:cloudless/core/features/supabase/utilities/supabase_buckets.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

/// Service responsible for enriching post data with signed URLs.
class PostEnrichmentService {
  const PostEnrichmentService({required this.ref});

  final Ref ref;

  /// Enriches post data with signed URLs for avatar, thumbnail, and video.
  /// All URLs are fetched in parallel for better performance.
  Future<void> enrichPostWithSignedUrls(Map<String, dynamic> postData) async {
    // Fetch all signed URLs in parallel instead of sequentially
    await Future.wait([
      _enrichAvatarUrl(postData),
      _enrichThumbnailUrl(postData),
      _enrichVideoUrl(postData),
    ]);
  }

  Future<void> _enrichAvatarUrl(Map<String, dynamic> postData) async {
    final authorId = postData['author_id'] as String?;
    if (authorId == null) {
      return;
    }

    try {
      final avatarUrl = await ref.read(
        signedUrlProvider(SupabaseBuckets.avatars, authorId).future,
      );
      postData['author_avatar_url'] = avatarUrl;
    } catch (e) {
      logger.error('Error getting avatar for author $authorId', exception: e);
      postData['author_avatar_url'] = null;
    }
  }

  Future<void> _enrichThumbnailUrl(Map<String, dynamic> postData) async {
    final thumbnailUrl = postData['thumbnail_url'] as String?;
    if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
      return;
    }

    try {
      final signedThumbnailUrl = await ref.read(
        signedUrlProvider(SupabaseBuckets.postMedia, thumbnailUrl).future,
      );
      postData['thumbnail_url'] = signedThumbnailUrl;
    } catch (e) {
      logger.error(
        'Error getting signed URL for thumbnail: $thumbnailUrl',
        exception: e,
      );
      postData['thumbnail_url'] = null;
    }
  }

  Future<void> _enrichVideoUrl(Map<String, dynamic> postData) async {
    final videoUrl = postData['video_url'] as String?;
    if (videoUrl == null || videoUrl.isEmpty) {
      return;
    }

    try {
      final signedVideoUrl = await ref.read(
        signedUrlProvider(SupabaseBuckets.postMedia, videoUrl).future,
      );
      postData['video_url'] = signedVideoUrl;
    } catch (e) {
      logger.error(
        'Error getting signed URL for video: $videoUrl',
        exception: e,
      );
      postData['video_url'] = null;
    }
  }

}
