import 'package:cloudless/core/features/post/data/dtos/post_dto.dart';
import 'package:cloudless/core/features/post/data/dtos/post_exclusion_dto.dart';
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
    required DateTime contentDate,
    String? parentId,
    String? description,
  }) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      logger.error('User not authenticated');
    }

    if (currentUser!.id != authorId) {
      logger.error('User ID mismatch: ${currentUser.id} vs $authorId');
    }

    final response = await _supabaseClient
        .from('posts')
        .insert({
          'author_id': authorId,
          'content_type': contentType.name.toLowerCase(),
          'thumbnail_url': thumbnailUrl,
          'thumbnail_width': thumbnailWidth,
          'thumbnail_height': thumbnailHeight,
          'content_date': contentDate.toIso8601String(),
          'parent_id': parentId,
          'description': description,
        })
        .select()
        .single();

    return PostDto.fromJson(response);
  }

  /// Adds media files to a post.
  Future<List<PostMediaDto>> addPostMedia({
    required String postId,
    required List<String> mediaUrls,
    required ContentType contentType,
  }) async {
    final List<Map<String, dynamic>> mediaDataList = [];

    for (final url in mediaUrls) {
      mediaDataList.add({
        'post_id': postId,
        'media_url': url,
        'media_type': contentType.name.toLowerCase(),
      });
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

  /// Adds exclusions (privacy settings) to a post.
  Future<List<PostExclusionDto>> addPostExclusions({
    required String postId,
    required List<String> excludedUserIds,
  }) async {
    final List<Map<String, dynamic>> exclusionDataList = [];

    for (final userId in excludedUserIds) {
      exclusionDataList.add({'post_id': postId, 'excluded_user_id': userId});
    }

    final response = await _supabaseClient
        .from('post_exclusions')
        .insert(exclusionDataList)
        .select();

    return response.map((json) => PostExclusionDto.fromJson(json)).toList();
  }

  /// Publishes a draft post.
  Future<PostDto> publishPost(String postId) async {
    final response = await _supabaseClient
        .from('posts')
        .update({'status': 'published'})
        .eq('id', postId)
        .select()
        .single();

    return PostDto.fromJson(response);
  }

  /// Updates an existing post.
  Future<PostDto> updatePost({
    required String postId,
    String? description,
    DateTime? contentDate,
    String? thumbnailUrl,
    int? thumbnailWidth,
    int? thumbnailHeight,
    ContentType? contentType,
  }) async {
    final Map<String, dynamic> updates = {};

    if (description != null) {
      updates['description'] = description;
    }
    if (contentDate != null) {
      updates['content_date'] = contentDate.toIso8601String();
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
