import 'package:cloudless/core/features/calendar/data/dtos/calendar_operation_response_dto.dart';
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
      'get_user_calendar',
      params: {
        'target_user_id': userId,
        'p_year': year,
        'p_month': month,
      },
    );

    if (response is List) {
      final posts = <CalendarPostDto>[];

      for (final json in response) {
        final postJson = json as Map<String, dynamic>;
        final authorId = postJson['author_id'] as String;

        // Fetch avatar URL from storage
        String? avatarUrl;
        try {
          avatarUrl = await ref.read(
            signedUrlProvider(SupabaseBuckets.avatars, authorId).future,
          );
        } on StorageException catch (_) {
          avatarUrl = null;
        }

        postJson['author_avatar_url'] = avatarUrl;

        final thumbnailUrl = postJson['thumbnail_url'] as String?;
        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
          try {
            final signedThumbnailUrl = await ref.read(
              signedUrlProvider(SupabaseBuckets.postMedia, thumbnailUrl).future,
            );
            postJson['thumbnail_url'] = signedThumbnailUrl;
          } catch (e) {
            logger.error(
              'Error getting signed URL for thumbnail: $thumbnailUrl',
              exception: e,
            );
            postJson['thumbnail_url'] = null;
          }
        }

        final videoUrl = postJson['video_url'] as String?;
        if (videoUrl != null && videoUrl.isNotEmpty) {
          try {
            final signedVideoUrl = await ref.read(
              signedUrlProvider(SupabaseBuckets.postMedia, videoUrl).future,
            );
            postJson['video_url'] = signedVideoUrl;
          } catch (e) {
            logger.error(
              'Error getting signed URL for video: $videoUrl',
              exception: e,
            );
            postJson['video_url'] = null;
          }
        }

        posts.add(CalendarPostDto.fromJson(postJson));
      }

      return posts;
    }

    return [];
  }

  /// Gets a friend's calendar posts for a given month.
  Future<List<CalendarPostDto>> getFriendCalendarPosts({
    required String friendId,
    required int year,
    required int month,
  }) async {
    final response = await supabaseClient.rpc(
      'get_user_calendar',
      params: {
        'target_user_id': friendId,
        'p_year': year,
        'p_month': month,
      },
    );

    if (response is List) {
      final posts = <CalendarPostDto>[];

      for (final json in response) {
        final postJson = json as Map<String, dynamic>;
        final authorId = postJson['author_id'] as String;

        // Avatar URL now comes directly from profile
        String? avatarUrl = postJson['author_avatar_url'] as String?;
        if (avatarUrl == null || avatarUrl.isEmpty) {
          try {
            avatarUrl = await ref.read(
              signedUrlProvider(SupabaseBuckets.avatars, authorId).future,
            );
          } on StorageException catch (_) {
            avatarUrl = null;
          }
          postJson['author_avatar_url'] = avatarUrl;
        }

        final thumbnailUrl = postJson['thumbnail_url'] as String?;
        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
          try {
            final signedThumbnailUrl = await ref.read(
              signedUrlProvider(SupabaseBuckets.postMedia, thumbnailUrl).future,
            );
            postJson['thumbnail_url'] = signedThumbnailUrl;
          } catch (e) {
            logger.error(
              'Error getting signed URL for thumbnail: $thumbnailUrl',
              exception: e,
            );
            postJson['thumbnail_url'] = null;
          }
        }

        final videoUrl = postJson['video_url'] as String?;
        if (videoUrl != null && videoUrl.isNotEmpty) {
          try {
            final signedVideoUrl = await ref.read(
              signedUrlProvider(SupabaseBuckets.postMedia, videoUrl).future,
            );
            postJson['video_url'] = signedVideoUrl;
          } catch (e) {
            logger.error(
              'Error getting signed URL for video: $videoUrl',
              exception: e,
            );
            postJson['video_url'] = null;
          }
        }

        posts.add(CalendarPostDto.fromJson(postJson));
      }

      return posts;
    }

    return [];
  }

  @override
  Future<CalendarOperationResponseDto> addPostToCalendar({
    required String postId,
  }) async {
    final response = await supabaseClient.rpc(
      'save_post_to_calendar',
      params: {'p_post_id': postId},
    );

    if (response is Map<String, dynamic>) {
      return CalendarOperationResponseDto.fromJson(response);
    }

    // If response is null or not a map, treat as success (void return from RPC)
    return const CalendarOperationResponseDto(success: true);
  }

  @override
  Future<CalendarOperationResponseDto> removePostFromCalendar({
    required String postId,
  }) async {
    // Clear the calendar_saved_at field
    try {
      await supabaseClient
          .from('posts')
          .update({'calendar_saved_at': null})
          .eq('id', postId);

      return const CalendarOperationResponseDto(success: true);
    } catch (e) {
      logger.error(
        'CalendarService.removePostFromCalendar - Error: $e',
      );
      return CalendarOperationResponseDto(
        success: false,
        error: e.toString(),
      );
    }
  }
}
