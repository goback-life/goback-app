import 'dart:io';

import 'package:cloudless/core/features/post/data/dtos/feed_post_dto.dart';
import 'package:cloudless/core/features/post/data/dtos/feed_response_dto.dart';
import 'package:cloudless/core/features/post/data/dtos/post_dto.dart';
import 'package:cloudless/core/features/post/data/dtos/post_media_dto.dart';
import 'package:cloudless/core/features/post/data/dtos/post_reaction_dto.dart';
import 'package:cloudless/core/features/post/data/dtos/post_report_dto.dart';
import 'package:cloudless/core/features/post/data/dtos/post_tag_dto.dart';
import 'package:cloudless/core/features/post/data/services/post_crud_service.dart';
import 'package:cloudless/core/features/post/data/services/post_enrichment_service.dart';
import 'package:cloudless/core/features/post/data/services/post_media_delete_service.dart';
import 'package:cloudless/core/features/post/data/services/post_media_upload_service.dart';
import 'package:cloudless/core/features/post/data/services/post_query_service.dart';
import 'package:cloudless/core/features/post/data/services/post_reaction_service.dart';
import 'package:cloudless/core/features/post/data/services/post_report_service.dart';
import 'package:cloudless/core/features/post/domain/contracts/post_service_contract.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/utilities/video_thumbnail_helper.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostService implements PostServiceContract {
  const PostService({required this.supabaseClient, required this.ref});

  final SupabaseClient supabaseClient;
  final Ref ref;

  PostMediaUploadService get _uploadService =>
      PostMediaUploadService(supabaseClient: supabaseClient);

  PostMediaDeleteService get _deleteService =>
      PostMediaDeleteService(supabaseClient: supabaseClient);

  PostEnrichmentService get _enrichmentService =>
      PostEnrichmentService(ref: ref);

  PostReactionService get _reactionService =>
      PostReactionService(supabaseClient: supabaseClient);

  PostReportService get _reportService =>
      PostReportService(supabaseClient: supabaseClient);

  PostQueryService get _queryService => PostQueryService(
        supabaseClient: supabaseClient,
        enrichmentService: _enrichmentService,
      );

  PostCrudService get _crudService =>
      PostCrudService(supabaseClient);

  @override
  Future<PostDto> createPostWithMedia({
    required String authorId,
    required ContentType contentType,
    required List<File> mediaFiles,
    required String publishedTimezone,
    String? description,
    File? thumbnailFile,
    String? lockoutId,
    List<String>? excludedUserIds,
  }) async {
    int thumbnailWidth = 1080;
    int thumbnailHeight = 1080;

    // Handle text posts - skip media upload and use default dimensions
    if (contentType == ContentType.text) {
      thumbnailWidth = 1080;
      thumbnailHeight = 400; // Minimum height for text posts

      final post = await createDraftPost(
        authorId: authorId,
        contentType: contentType,
        thumbnailUrl: '', // Empty for text posts - render text directly
        thumbnailWidth: thumbnailWidth,
        thumbnailHeight: thumbnailHeight,
        description: description,
        lockoutId: lockoutId,
        excludedUserIds: excludedUserIds,
      );

      // Text posts don't need thumbnail update - return the draft post as is
      return post;
    }

    File? videoThumbnailFile;
    if (contentType == ContentType.video) {
      final thumbnailToUse =
          thumbnailFile ??
          await VideoThumbnailHelper.extractThumbnail(mediaFiles.first);
      videoThumbnailFile = thumbnailFile == null ? thumbnailToUse : null;
      final dimensions = await _uploadService.getImageDimensions(
        thumbnailToUse,
      );
      thumbnailWidth = dimensions.$1;
      thumbnailHeight = dimensions.$2;
    } else if (contentType == ContentType.image ||
        contentType == ContentType.doubleImage) {
      final dimensions = await _uploadService.getImageDimensions(
        mediaFiles.first,
      );
      thumbnailWidth = dimensions.$1;
      thumbnailHeight = dimensions.$2;
    }

    final post = await createDraftPost(
      authorId: authorId,
      contentType: contentType,
      thumbnailUrl: '',
      thumbnailWidth: thumbnailWidth,
      thumbnailHeight: thumbnailHeight,
      description: description,
      lockoutId: lockoutId,
      excludedUserIds: excludedUserIds,
    );

    try {
      String thumbnailUrl;

      if (contentType == ContentType.video) {
        final thumbnailToUpload = thumbnailFile ?? videoThumbnailFile!;
        thumbnailUrl = await _uploadService.uploadThumbnail(
          authorId,
          thumbnailToUpload,
          post.id,
        );

        final videoUrls = await _uploadService.uploadMediaFiles(
          authorId,
          mediaFiles,
          contentType,
          post.id,
        );

        await addPostMedia(
          postId: post.id,
          mediaUrls: videoUrls,
          contentType: contentType,
        );
      } else {
        final mediaUrls = await _uploadService.uploadMediaFiles(
          authorId,
          mediaFiles,
          contentType,
          post.id,
        );
        thumbnailUrl = mediaUrls.first;

        if (contentType != ContentType.image) {
          await addPostMedia(
            postId: post.id,
            mediaUrls: mediaUrls,
            contentType: contentType,
          );
        }
      }

      final updatedPost = await _crudService.updatePostThumbnail(
        post.id,
        thumbnailUrl,
      );

      if (videoThumbnailFile != null) {
        try {
          await videoThumbnailFile.delete();
        } catch (e) {
          logger.error('Failed to delete temp thumbnail file', exception: e);
        }
      }

      return updatedPost;
    } catch (e) {
      logger.error('Upload failed, deleting post ${post.id}', exception: e);
      await _deletePost(post.id);

      if (videoThumbnailFile != null) {
        try {
          await videoThumbnailFile.delete();
        } catch (_) {}
      }

      rethrow;
    }
  }

  @override
  Future<List<String>> uploadMediaFiles(
    String userId,
    List<File> mediaFiles,
    ContentType contentType, [
    String? postId,
  ]) async {
    return _uploadService.uploadMediaFiles(
      userId,
      mediaFiles,
      contentType,
      postId,
    );
  }

  @override
  Future<PostDto> createDraftPost({
    required String authorId,
    required ContentType contentType,
    required String thumbnailUrl,
    required int thumbnailWidth,
    required int thumbnailHeight,
    String? description,
    String? lockoutId,
    List<String>? excludedUserIds,
  }) async {
    return _crudService.createDraftPost(
      authorId: authorId,
      contentType: contentType,
      thumbnailUrl: thumbnailUrl,
      thumbnailWidth: thumbnailWidth,
      thumbnailHeight: thumbnailHeight,
      description: description,
      lockoutId: lockoutId,
      excludedUserIds: excludedUserIds,
    );
  }

  @override
  Future<List<PostMediaDto>> addPostMedia({
    required String postId,
    required List<String> mediaUrls,
    required ContentType contentType,
  }) async {
    return _crudService.addPostMedia(
      postId: postId,
      mediaUrls: mediaUrls,
      contentType: contentType,
    );
  }

  @override
  Future<List<PostTagDto>> addPostTags({
    required String postId,
    required List<String> taggedUserIds,
  }) async {
    return _crudService.addPostTags(
      postId: postId,
      taggedUserIds: taggedUserIds,
    );
  }

  @override
  Future<void> setPostExclusions({
    required String postId,
    required List<String> excludedUserIds,
  }) async {
    return _crudService.setPostExclusions(
      postId: postId,
      excludedUserIds: excludedUserIds,
    );
  }

  @override
  Future<PostDto> publishPost(String postId) async {
    return _crudService.publishPost(postId);
  }

  @override
  Future<PostDto> updatePost({
    required String postId,
    required String description,
    required List<String> taggedUserIds,
    required List<String> excludedUserIds,
    required String authorId,
    required ContentType contentType,
    File? newMediaFile,
    File? newThumbnailFile,
  }) async {
    final updateData = <String, dynamic>{'description': description};

    if (newMediaFile != null) {
      await _deleteService.deletePostMediaFiles(authorId, postId);

      File? videoThumbnailFile;
      String thumbnailUrl;

      if (contentType == ContentType.video) {
        final thumbnailToUse =
            newThumbnailFile ??
            await VideoThumbnailHelper.extractThumbnail(newMediaFile);

        videoThumbnailFile = newThumbnailFile == null ? thumbnailToUse : null;

        final dimensions = await _uploadService.getImageDimensions(
          thumbnailToUse,
        );
        final thumbnailWidth = dimensions.$1;
        final thumbnailHeight = dimensions.$2;

        thumbnailUrl = await _uploadService.uploadThumbnail(
          authorId,
          thumbnailToUse,
          postId,
        );

        final videoUrls = await _uploadService.uploadMediaFiles(
          authorId,
          [newMediaFile],
          contentType,
          postId,
        );

        updateData['thumbnail_url'] = thumbnailUrl;
        updateData['thumbnail_width'] = thumbnailWidth;
        updateData['thumbnail_height'] = thumbnailHeight;

        await _crudService.deletePostMediaRecords(postId);
        await addPostMedia(
          postId: postId,
          mediaUrls: videoUrls,
          contentType: contentType,
        );

        if (videoThumbnailFile != null) {
          try {
            await videoThumbnailFile.delete();
          } catch (e) {
            logger.error('Failed to delete temp thumbnail file', exception: e);
          }
        }
      } else {
        final dimensions = await _uploadService.getImageDimensions(
          newMediaFile,
        );
        final thumbnailWidth = dimensions.$1;
        final thumbnailHeight = dimensions.$2;

        final mediaUrls = await _uploadService.uploadMediaFiles(
          authorId,
          [newMediaFile],
          contentType,
          postId,
        );

        updateData['thumbnail_url'] = mediaUrls.first;
        updateData['thumbnail_width'] = thumbnailWidth;
        updateData['thumbnail_height'] = thumbnailHeight;

        await _crudService.deletePostMediaRecords(postId);

        if (contentType != ContentType.image) {
          await addPostMedia(
            postId: postId,
            mediaUrls: mediaUrls,
            contentType: contentType,
          );
        }
      }
    } else if (newThumbnailFile != null && contentType == ContentType.video) {
      final currentPost = await _crudService.getPostField(postId, 'thumbnail_url');
      final oldThumbnailUrl = currentPost['thumbnail_url'] as String?;

      if (oldThumbnailUrl != null && oldThumbnailUrl.isNotEmpty) {
        await _deleteService.deleteThumbnailByUrl(oldThumbnailUrl);
      }

      final thumbnailUrl = await _uploadService.uploadThumbnail(
        authorId,
        newThumbnailFile,
        postId,
      );

      updateData['thumbnail_url'] = thumbnailUrl;
    }

    final updatedPost = await _crudService.updatePostData(postId, updateData);

    await _crudService.deletePostTagRecords(postId);
    if (taggedUserIds.isNotEmpty) {
      await addPostTags(postId: postId, taggedUserIds: taggedUserIds);
    }
    await setPostExclusions(postId: postId, excludedUserIds: excludedUserIds);

    return updatedPost;
  }

  @override
  Future<void> deletePost({
    required String postId,
    required String authorId,
  }) async {
    await supabaseClient.rpc('soft_delete_post', params: {'post_id': postId});

    logger.info('Post $postId soft deleted successfully');
  }

  @override
  Future<void> hidePost({
    required String postId,
    required String userId,
  }) async {
    // Use atomic RPC to prevent race conditions when hiding from multiple devices
    final result = await supabaseClient.rpc(
      'hide_post_for_user',
      params: {'p_post_id': postId, 'p_user_id': userId},
    );

    if (result == true) {
      logger.info('Post $postId hidden for user $userId');
    } else {
      logger.info('Post $postId already hidden for user $userId (no-op)');
    }
  }

  Future<void> _deletePost(String postId) async {
    try {
      await _crudService.deletePost(postId);
      logger.info('Post $postId deleted successfully');
    } catch (e) {
      logger.error('Failed to delete post $postId', exception: e);
      rethrow;
    }
  }

  @override
  Future<bool> hasUserReportedPost({
    required String postId,
    required String userId,
  }) async {
    return _reportService.hasUserReportedPost(
      postId: postId,
      userId: userId,
    );
  }

  @override
  Future<PostReportDto> createReport({
    required String postId,
    required String userId,
    required String reason,
  }) async {
    return _reportService.createReport(
      postId: postId,
      userId: userId,
      reason: reason,
    );
  }

  @override
  Future<FeedResponseDto> getFeedPosts({
    required String userId,
    int pageSize = 15,
    DateTime? cursor,
  }) async {
    return _queryService.getFeedPosts(
      userId: userId,
      pageSize: pageSize,
      cursor: cursor,
    );
  }

  @override
  Future<FeedPostDto> getPostById({required String postId}) async {
    return _queryService.getPostById(postId: postId);
  }

  @override
  Future<List<PostReactionDto>> getPostReactions({
    required String postId,
  }) async {
    return _reactionService.getPostReactions(postId: postId);
  }

  @override
  Future<PostReactionDto> addReaction({
    required String postId,
    required String userId,
    required String reaction,
  }) async {
    return _reactionService.addReaction(
      postId: postId,
      userId: userId,
      reaction: reaction,
    );
  }

  @override
  Future<void> deleteReaction({required String reactionId}) async {
    return _reactionService.deleteReaction(reactionId: reactionId);
  }
}
