import 'dart:io';

import 'package:cloudless/core/features/post/data/dtos/feed_post_dto.dart';
import 'package:cloudless/core/features/post/data/dtos/feed_response_dto.dart';
import 'package:cloudless/core/features/post/data/dtos/post_dto.dart';
import 'package:cloudless/core/features/post/data/dtos/post_media_dto.dart';
import 'package:cloudless/core/features/post/data/dtos/post_reaction_dto.dart';
import 'package:cloudless/core/features/post/data/dtos/post_report_dto.dart';
import 'package:cloudless/core/features/post/data/dtos/post_tag_dto.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';

abstract class PostServiceContract {
  Future<PostDto> createPostWithMedia({
    required String authorId,
    required ContentType contentType,
    required List<File> mediaFiles,
    required String publishedTimezone,
    String? description,
    File? thumbnailFile,

    /// Reference to lockout_sessions table if this is a lockout post
    String? lockoutId,

    /// List of user IDs to exclude from seeing this post
    List<String>? excludedUserIds,
  });

  Future<List<String>> uploadMediaFiles(
    String userId,
    List<File> mediaFiles,
    ContentType contentType, [
    String? postId,
  ]);

  Future<PostDto> createDraftPost({
    required String authorId,
    required ContentType contentType,
    required String thumbnailUrl,
    required int thumbnailWidth,
    required int thumbnailHeight,
    String? description,

    /// Reference to lockout_sessions table if this is a lockout post
    String? lockoutId,

    /// List of user IDs to exclude from seeing this post
    List<String>? excludedUserIds,
  });

  /// Adds media entries to the post_media table.
  /// This is only used for non-image content types (video, audio, doubleImage).
  /// For ContentType.image, the thumbnail_url in the posts table is sufficient.
  Future<List<PostMediaDto>> addPostMedia({
    required String postId,
    required List<String> mediaUrls,
    required ContentType contentType,
  });

  Future<List<PostTagDto>> addPostTags({
    required String postId,
    required List<String> taggedUserIds,
  });

  /// Sets exclusions (privacy settings) on a post.
  /// Stores excluded user IDs as a UUID[] array directly on the posts table.
  Future<void> setPostExclusions({
    required String postId,
    required List<String> excludedUserIds,
  });

  Future<PostDto> publishPost(String postId);

  /// Updates a post with new data.
  ///
  /// For video posts:
  /// - [newMediaFile] replaces the video
  /// - [newThumbnailFile] replaces the thumbnail (can be first frame or custom preview)
  ///
  /// For image posts:
  /// - [newMediaFile] replaces the image
  /// - [newThumbnailFile] is ignored
  Future<PostDto> updatePost({
    required String postId,
    required String description,
    required List<String> taggedUserIds,
    required List<String> excludedUserIds,
    required String authorId,
    required ContentType contentType,
    File? newMediaFile,
    File? newThumbnailFile,
  });

  Future<FeedResponseDto> getFeedPosts({
    required String userId,
    int pageSize = 15,
    DateTime? cursor,
  });

  Future<FeedPostDto> getPostById({required String postId});

  Future<void> deletePost({required String postId, required String authorId});

  Future<void> hidePost({required String postId, required String userId});

  Future<bool> hasUserReportedPost({
    required String postId,
    required String userId,
  });

  Future<PostReportDto> createReport({
    required String postId,
    required String userId,
    required String reason,
  });

  Future<List<PostReactionDto>> getPostReactions({required String postId});

  Future<PostReactionDto> addReaction({
    required String postId,
    required String userId,
    required String reaction,
  });

  Future<void> deleteReaction({required String reactionId});
}
