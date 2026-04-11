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

  /// Gets feed posts for a user with cursor-based pagination.
  /// Uses the new get_user_feed RPC which returns posts from friends
  /// published within the last 24 hours.
  ///
  /// Uses rate-limited enrichment (5 concurrent requests) to avoid
  /// overwhelming the server with too many parallel signed URL requests.
  Future<FeedResponseDto> getFeedPosts({
    required String userId,
    int pageSize = 15,
    DateTime? cursor,
  }) async {
    final params = <String, dynamic>{'p_page_size': pageSize};

    if (cursor != null) {
      params['p_cursor'] = cursor.toIso8601String();
    }

    final feedResponse = await supabaseClient.rpc(
      'get_user_feed',
      params: params,
    );
    final feedList = feedResponse as List;
    final postDataList = feedList
        .map((json) => json as Map<String, dynamic>)
        .toList();

    // Enrich posts with rate limiting (15 concurrent requests max)
    // 15 concurrent × 3 URLs each = 45 peak concurrent, reduces enrichment latency ~60%
    await _enrichPostsWithRateLimit(postDataList, concurrency: 15);

    final posts = postDataList
        .map((data) => FeedPostDto.fromJson(data))
        .toList();

    final hasNextPage = posts.length >= pageSize;

    return FeedResponseDto(
      posts: posts,
      totalCount: posts.length,
      hasNextPage: hasNextPage,
    );
  }

  /// Gets a single post by its ID.
  /// Uses auth.uid() server-side for user context.
  Future<FeedPostDto> getPostById({required String postId}) async {
    try {
      final response = await supabaseClient.rpc(
        'get_post_by_id',
        params: {'p_post_id': postId},
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

  /// Enriches posts with signed URLs using rate limiting to avoid
  /// overwhelming the server with too many concurrent requests.
  Future<void> _enrichPostsWithRateLimit(
    List<Map<String, dynamic>> posts, {
    int concurrency = 5,
  }) async {
    if (posts.isEmpty) return;

    // Process posts in batches of [concurrency] size
    for (var i = 0; i < posts.length; i += concurrency) {
      final batch = posts.skip(i).take(concurrency).toList();
      await Future.wait(
        batch.map((post) => enrichmentService.enrichPostWithSignedUrls(post)),
      );
    }
  }
}
