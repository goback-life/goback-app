import 'package:cloudless/core/features/post/data/dtos/feed_post_dto.dart';
import 'package:cloudless/core/features/post/data/dtos/feed_response_dto.dart';
import 'package:cloudless/core/features/post/data/services/post_enrichment_service.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for querying posts from the database.
class PostQueryService {
  const PostQueryService({
    required this.supabaseClient,
    required this.enrichmentService,
  });

  final SupabaseClient supabaseClient;
  final PostEnrichmentService enrichmentService;

  /// Gets feed posts for a user with pagination support.
  Future<FeedResponseDto> getFeedPosts({
    required String userId,
    required DateTime targetDate,
    int pageSize = 15,
    int pageOffset = 0,
    DateTime? cursorBefore,
    DateTime? cursorAfter,
  }) async {
    late dynamic feedResponse;
    late dynamic countResponse;

    try {
      final params = {
        'p_user_id': userId,
        'target_date': targetDate.toIso8601String().split('T')[0],
        'page_size': pageSize,
      };

      if (cursorBefore != null) {
        params['cursor_before'] = cursorBefore.toIso8601String();
      } else if (cursorAfter != null) {
        params['cursor_after'] = cursorAfter.toIso8601String();
      } else {
        params['page_offset'] = pageOffset;
      }

      feedResponse = await supabaseClient.rpc('get_user_feed', params: params);

      countResponse = await supabaseClient.rpc(
        'get_user_feed_count',
        params: {
          'p_user_id': userId,
          'target_date': targetDate.toIso8601String().split('T')[0],
        },
      );
    } catch (e) {
      rethrow;
    }

    final totalCount = countResponse as int;
    final feedList = feedResponse as List;

    final posts = <FeedPostDto>[];
    for (final json in feedList) {
      final postData = json as Map<String, dynamic>;
      await enrichmentService.enrichPostWithSignedUrls(postData);
      posts.add(FeedPostDto.fromJson(postData));
    }

    final hasNextPage = cursorBefore != null || cursorAfter != null
        ? posts.length >= pageSize
        : (pageOffset + pageSize) < totalCount;

    return FeedResponseDto(
      posts: posts,
      totalCount: totalCount,
      hasNextPage: hasNextPage,
    );
  }

  /// Gets a single post by its ID.
  Future<FeedPostDto> getPostById({required String postId}) async {
    try {
      final currentUserId = supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await supabaseClient.rpc(
        'get_post_by_id',
        params: {'p_post_id': postId, 'p_user_id': currentUserId},
      );

      if (response == null || (response is List && response.isEmpty)) {
        throw Exception('Post not found or access denied');
      }

      final postData = response is List
          ? Map<String, dynamic>.from(response.first as Map)
          : Map<String, dynamic>.from(response as Map);

      await enrichmentService.enrichPostWithSignedUrls(postData);

      return FeedPostDto.fromJson(postData);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to get post by ID: $postId',
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
