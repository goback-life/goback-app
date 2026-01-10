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
        'target_timestamp': targetDate.toIso8601String(),
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
          'target_timestamp': targetDate.toIso8601String(),
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

  /// Gets all replies to a post, ordered by creation date (latest first).
  Future<List<FeedPostDto>> getPostReplies({required String postId}) async {
    try {
      final currentUserId = supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Try using RPC function first (if it exists)
      try {
        final response = await supabaseClient.rpc(
          'get_post_replies',
          params: {'p_post_id': postId, 'p_user_id': currentUserId},
        );

        if (response == null) {
          return [];
        }

        final responseList = response is List ? response : [response];
        final replies = <FeedPostDto>[];
        for (final json in responseList) {
          final postData = Map<String, dynamic>.from(json as Map);
          await enrichmentService.enrichPostWithSignedUrls(postData);
          replies.add(FeedPostDto.fromJson(postData));
        }

        return replies;
      } catch (e) {
        // If RPC function doesn't exist, use a simple query
        // Query basic post fields (video_url is in post_media table, not posts table)
        // Published posts have status = 'published'
        final response = await supabaseClient
            .from('posts')
            .select('id, author_id, thumbnail_url, thumbnail_width, thumbnail_height, content_date, published_at, published_timezone, created_at, updated_at, content_type, parent_id, description')
            .eq('parent_id', postId)
            .eq('status', 'published')
            .order('created_at', ascending: false);

        final responseList = response as List? ?? [];
        final replies = <FeedPostDto>[];
        
        // Map posts to DTOs and fetch profile data for each author
        for (final json in responseList) {
          final postData = Map<String, dynamic>.from(json as Map);
          final authorId = postData['author_id'] as String?;
          
          // Fetch profile data for this author
          // Note: avatar_url is not in profiles table, it's in storage and handled by enrichment service
          if (authorId != null) {
            try {
              final profileResponse = await supabaseClient
                  .from('profiles')
                  .select('username')
                  .eq('id', authorId)
                  .maybeSingle();
              
              if (profileResponse != null) {
                final profileData = Map<String, dynamic>.from(profileResponse);
                postData['author_username'] = profileData['username'];
              } else {
                logger.warning('Profile not found for author $authorId');
                postData['author_username'] = null;
              }
            } catch (e) {
              logger.error(
                'Failed to fetch profile for author $authorId',
                exception: e,
              );
              postData['author_username'] = null;
            }
          } else {
            postData['author_username'] = null;
          }
          
          // Avatar URL will be set by enrichment service
          postData['author_avatar_url'] = null;
          
          // Set defaults for required fields
          postData['video_url'] = null; // Video URLs are in post_media table, not posts
          postData['is_author_connected'] = false;
          postData['tagged_usernames'] = null;
          postData['tagged_user_ids'] = null;
          postData['excluded_user_ids'] = null;
          postData['parent_excluded_user_ids'] = '';
          postData['link_previews'] = null;
          
          await enrichmentService.enrichPostWithSignedUrls(postData);
          replies.add(FeedPostDto.fromJson(postData));
        }

        return replies;
      }
    } catch (e, stackTrace) {
      logger.error(
        'Failed to get post replies: $postId',
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
