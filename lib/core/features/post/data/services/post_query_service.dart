import 'dart:async';

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
    final stopwatch = Stopwatch()..start();
    late dynamic feedResponse;

    try {
      final params = <String, dynamic>{
        'p_page_size': pageSize,
      };

      if (cursor != null) {
        params['p_cursor'] = cursor.toIso8601String();
      }

      feedResponse = await supabaseClient.rpc('get_user_feed', params: params);
      // ignore: avoid_print
      print('[FeedPosts] RPC completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      // ignore: avoid_print
      print('[FeedPosts] RPC error: $e');
      rethrow;
    }

    final feedList = feedResponse as List;
    // ignore: avoid_print
    print('[FeedPosts] RPC returned ${feedList.length} posts');
    final postDataList = feedList
        .map((json) => json as Map<String, dynamic>)
        .toList();

    // Enrich posts with rate limiting (5 concurrent requests max)
    // This prevents overwhelming the server with too many parallel requests
    final enrichStart = stopwatch.elapsedMilliseconds;
    await _enrichPostsWithRateLimit(postDataList, concurrency: 5);
    // ignore: avoid_print
    print('[FeedPosts] Enrichment of ${postDataList.length} posts completed in ${stopwatch.elapsedMilliseconds - enrichStart}ms');

    final posts = postDataList.map((data) => FeedPostDto.fromJson(data)).toList();
    // ignore: avoid_print
    print('[FeedPosts] Total feed load: ${stopwatch.elapsedMilliseconds}ms');

    final hasNextPage = posts.length >= pageSize;

    return FeedResponseDto(
      posts: posts,
      totalCount: posts.length,
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
