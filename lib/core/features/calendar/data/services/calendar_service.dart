import 'package:cloudless/core/features/calendar/data/dtos/calendar_post_dto.dart';
import 'package:cloudless/core/features/calendar/domain/contracts/calendar_service_contract.dart';
import 'package:cloudless/core/features/storage/data/providers/signed_url_provider.dart';
import 'package:cloudless/core/features/supabase/utilities/supabase_buckets.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarService implements CalendarServiceContract {
  const CalendarService({required this.supabaseClient, required this.ref});

  final SupabaseClient supabaseClient;
  final Ref ref;

  @override
  Future<List<CalendarPostDto>> getCalendarPosts({
    required String userId,
    required int year,
    required int month,
  }) async {
    final response = await supabaseClient.rpc(
      'get_user_lockout_calendar',
      params: {
        'p_target_user_id': userId,
        'p_year': year,
        'p_month': month,
      },
    );

    if (response is! List || response.isEmpty) {
      return [];
    }

    // Process all posts in parallel for better performance
    final postFutures = response.map((json) async {
      final postJson = Map<String, dynamic>.from(json as Map<String, dynamic>);
      await _enrichPostWithSignedUrls(postJson);
      return CalendarPostDto.fromJson(postJson);
    });

    return Future.wait(postFutures);
  }

  /// Gets a friend's calendar posts for a given month.
  Future<List<CalendarPostDto>> getFriendCalendarPosts({
    required String friendId,
    required int year,
    required int month,
  }) async {
    // Use the same RPC - it handles friendship check internally
    return getCalendarPosts(userId: friendId, year: year, month: month);
  }

  /// Enriches a post JSON with signed URLs for avatar, thumbnail, and video.
  Future<void> _enrichPostWithSignedUrls(Map<String, dynamic> postJson) async {
    final authorId = postJson['author_id'] as String;
    final thumbnailUrl = postJson['thumbnail_url'] as String?;
    final videoUrl = postJson['video_url'] as String?;

    // Start all URL fetches in parallel
    final futures = <Future<void>>[];

    // Avatar URL
    futures.add(_fetchAvatarUrl(authorId).then((url) {
      postJson['author_avatar_url'] = url;
    }));

    // Thumbnail URL
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      futures.add(_fetchMediaUrl(thumbnailUrl).then((url) {
        postJson['thumbnail_url'] = url;
      }));
    }

    // Video URL
    if (videoUrl != null && videoUrl.isNotEmpty) {
      futures.add(_fetchMediaUrl(videoUrl).then((url) {
        postJson['video_url'] = url;
      }));
    }

    await Future.wait(futures);
  }

  Future<String?> _fetchAvatarUrl(String authorId) async {
    try {
      return await ref.read(
        signedUrlProvider(SupabaseBuckets.avatars, authorId).future,
      );
    } on StorageException catch (_) {
      return null;
    }
  }

  Future<String?> _fetchMediaUrl(String path) async {
    try {
      return await ref.read(
        signedUrlProvider(SupabaseBuckets.postMedia, path).future,
      );
    } catch (e) {
      logger.error('Error getting signed URL for media: $path', exception: e);
      return null;
    }
  }
}
