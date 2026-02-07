import 'package:cloudless/core/features/post/data/dtos/post_dto.dart';
import 'package:cloudless/core/features/post/data/dtos/post_media_dto.dart';
import 'package:cloudless/core/features/post/data/dtos/post_tag_dto.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for CRUD operations on posts.
///
/// Handles creation of draft posts, publishing, updating,
/// and managing post-related entities (media, tags, exclusions).
class PostCrudService {
  PostCrudService(this._supabaseClient);
  final SupabaseClient _supabaseClient;

  /// Creates a draft post in the database.
  Future<PostDto> createDraftPost({
    required String authorId,
    required ContentType contentType,
    required String thumbnailUrl,
    required int thumbnailWidth,
    required int thumbnailHeight,
    String? description,
    /// Reference to lockout_sessions table if this is a lockout post
    String? lockoutId,
    /// List of user IDs to exclude from seeing this post (stored as UUID[])
    List<String>? excludedUserIds,
  }) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      logger.error('User not authenticated');
    }

    if (currentUser!.id != authorId) {
      logger.error('User ID mismatch: ${currentUser.id} vs $authorId');
    }

    final insertData = <String, dynamic>{
      'author_id': authorId,
      'content_type': contentType.name.toLowerCase(),
      'thumbnail_url': thumbnailUrl,
      'thumbnail_width': thumbnailWidth,
      'thumbnail_height': thumbnailHeight,
      'description': description,
      'lockout_id': lockoutId,
    };

    // Set excluded_user_ids as UUID[] array if provided
    if (excludedUserIds != null && excludedUserIds.isNotEmpty) {
      insertData['excluded_user_ids'] = excludedUserIds;
    }

    final response = await _supabaseClient
        .from('posts')
        .insert(insertData)
        .select()
        .single();

    return PostDto.fromJson(response);
  }

  /// Adds media files to a post.
  /// For videos, [durationSeconds] should be provided to enable server-side validation.
  Future<List<PostMediaDto>> addPostMedia({
    required String postId,
    required List<String> mediaUrls,
    required ContentType contentType,
    double? durationSeconds,
  }) async {
    final List<Map<String, dynamic>> mediaDataList = [];

    for (final url in mediaUrls) {
      final data = <String, dynamic>{
        'post_id': postId,
        'media_url': url,
        'media_type': contentType.name.toLowerCase(),
      };
      // Add duration for videos (first URL assumed to be the video)
      if (contentType == ContentType.video && durationSeconds != null) {
        data['duration_seconds'] = durationSeconds;
      }
      mediaDataList.add(data);
    }

    final response = await _supabaseClient
        .from('post_media')
        .insert(mediaDataList)
        .select();

    return response.map((json) => PostMediaDto.fromJson(json)).toList();
  }

  /// Adds tags to a post.
  Future<List<PostTagDto>> addPostTags({
    required String postId,
    required List<String> taggedUserIds,
  }) async {
    final List<Map<String, dynamic>> tagDataList = [];

    for (final tagId in taggedUserIds) {
      tagDataList.add({'post_id': postId, 'tagged_user_id': tagId});
    }

    final response = await _supabaseClient
        .from('post_tags')
        .insert(tagDataList)
        .select();

    return response.map((json) => PostTagDto.fromJson(json)).toList();
  }

  /// Sets exclusions (privacy settings) on a post.
  /// Stores excluded user IDs as a UUID[] array directly on the posts table.
  Future<void> setPostExclusions({
    required String postId,
    required List<String> excludedUserIds,
  }) async {
    await _supabaseClient
        .from('posts')
        .update({'excluded_user_ids': excludedUserIds})
        .eq('id', postId);
  }

  /// Publishes a draft post by setting the published_at timestamp.
  Future<PostDto> publishPost(String postId) async {
    final now = DateTime.now();
    final timezone = now.timeZoneName;

    final response = await _supabaseClient
        .from('posts')
        .update({
          'published_at': now.toUtc().toIso8601String(),
          'published_timezone': timezone,
        })
        .eq('id', postId)
        .select()
        .single();

    return PostDto.fromJson(response);
  }

  /// Updates an existing post.
  Future<PostDto> updatePost({
    required String postId,
    String? description,
    String? thumbnailUrl,
    int? thumbnailWidth,
    int? thumbnailHeight,
    ContentType? contentType,
    List<String>? excludedUserIds,
  }) async {
    final Map<String, dynamic> updates = {};

    if (description != null) {
      updates['description'] = description;
    }
    if (thumbnailUrl != null) {
      updates['thumbnail_url'] = thumbnailUrl;
    }
    if (thumbnailWidth != null) {
      updates['thumbnail_width'] = thumbnailWidth;
    }
    if (thumbnailHeight != null) {
      updates['thumbnail_height'] = thumbnailHeight;
    }
    if (contentType != null) {
      updates['content_type'] = contentType.name.toLowerCase();
    }
    if (excludedUserIds != null) {
      updates['excluded_user_ids'] = excludedUserIds;
    }

    final response = await _supabaseClient
        .from('posts')
        .update(updates)
        .eq('id', postId)
        .select()
        .single();

    return PostDto.fromJson(response);
  }

  /// Updates the thumbnail URL of a post.
  Future<PostDto> updatePostThumbnail(
    String postId,
    String thumbnailUrl,
  ) async {
    final response = await _supabaseClient
        .from('posts')
        .update({'thumbnail_url': thumbnailUrl})
        .eq('id', postId)
        .select()
        .single();

    return PostDto.fromJson(response);
  }

  /// Deletes a post from the database.
  Future<void> deletePost(String postId) async {
    await _supabaseClient.from('posts').delete().eq('id', postId);
  }

  /// Hides a post (soft delete).
  Future<void> hidePost(String postId) async {
    await _supabaseClient
        .from('posts')
        .update({'hidden_at': DateTime.now().toIso8601String()})
        .eq('id', postId);
  }
}
