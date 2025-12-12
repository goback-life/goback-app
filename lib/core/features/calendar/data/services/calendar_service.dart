import 'package:cloudless/core/features/calendar/data/dtos/calendar_operation_response_dto.dart';
import 'package:cloudless/core/features/calendar/data/dtos/calendar_post_dto.dart';
import 'package:cloudless/core/features/calendar/domain/contracts/calendar_service_contract.dart';
import 'package:cloudless/core/features/calendar/domain/enums/calendar_load_direction.dart';
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
    required DateTime referenceDate,
    required CalendarLoadDirection direction,
    int limit = 42,
  }) async {
    final response = await supabaseClient.rpc(
      'get_calendar_posts',
      params: {
        'p_user_id': userId,
        'p_reference_date': referenceDate.toIso8601String().split('T')[0],
        'p_direction': direction.value,
        'p_limit': limit,
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

        final parentThumbnailUrl = postJson['parent_thumbnail_url'] as String?;
        if (parentThumbnailUrl != null && parentThumbnailUrl.isNotEmpty) {
          try {
            final signedParentThumbnailUrl = await ref.read(
              signedUrlProvider(
                SupabaseBuckets.postMedia,
                parentThumbnailUrl,
              ).future,
            );
            postJson['parent_thumbnail_url'] = signedParentThumbnailUrl;
          } catch (e) {
            logger.error(
              'Error getting signed URL for parent thumbnail: $parentThumbnailUrl',
              exception: e,
            );
            postJson['parent_thumbnail_url'] = null;
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
    required DateTime calendarDate,
  }) async {
    final dateString = calendarDate.toIso8601String().split('T')[0];

    final response = await supabaseClient.rpc(
      'add_post_to_calendar',
      params: {'p_post_id': postId, 'p_calendar_date': dateString},
    );

    if (response is Map<String, dynamic>) {
      return CalendarOperationResponseDto.fromJson(response);
    }

    logger.error(
      'CalendarService.addPostToCalendar - Invalid response type: ${response.runtimeType}',
    );
    return const CalendarOperationResponseDto(
      success: false,
      error: 'Invalid response from server',
    );
  }

  @override
  Future<CalendarOperationResponseDto> removePostFromCalendar({
    required DateTime calendarDate,
  }) async {
    final dateString = calendarDate.toIso8601String().split('T')[0];

    final response = await supabaseClient.rpc(
      'remove_post_from_calendar',
      params: {'p_calendar_date': dateString},
    );

    if (response is Map<String, dynamic>) {
      return CalendarOperationResponseDto.fromJson(response);
    }

    logger.error(
      'CalendarService.removePostFromCalendar - Invalid response type: ${response.runtimeType}',
    );
    return const CalendarOperationResponseDto(
      success: false,
      error: 'Invalid response from server',
    );
  }
}
