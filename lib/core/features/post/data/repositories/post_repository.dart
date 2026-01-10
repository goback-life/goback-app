import 'package:cloudless/core/features/post/data/exceptions/post_report_exception.dart';
import 'package:cloudless/core/features/post/data/mappers/create_post_exception_mapper.dart';
import 'package:cloudless/core/features/post/data/mappers/feed_post_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/post/data/mappers/feed_post_exception_mapper.dart';
import 'package:cloudless/core/features/post/data/mappers/feed_response_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/post/data/mappers/post_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/post/data/mappers/post_reaction_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/post/data/mappers/post_report_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/post/domain/contracts/post_repository_contract.dart';
import 'package:cloudless/core/features/post/domain/contracts/post_service_contract.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/models/feed_response_model.dart';
import 'package:cloudless/core/features/post/domain/models/post_data_model.dart';
import 'package:cloudless/core/features/post/domain/models/post_model.dart';
import 'package:cloudless/core/features/post/domain/models/post_reaction_model.dart';
import 'package:cloudless/core/features/post/domain/models/post_report_model.dart';
import 'package:cloudless/core/features/supabase/data/mixins/supabase_result_processor.dart';
import 'package:dedecube_core/dedecube_core.dart';

class PostRepository
    with SupabaseResultProcessor
    implements PostRepositoryContract {
  const PostRepository({
    required this.postService,
    required this.postMapper,
    required this.feedResponseMapper,
    required this.feedPostMapper,
  });

  final PostServiceContract postService;
  final PostDtoToModelMapper postMapper;
  final FeedResponseDtoToModelMapper feedResponseMapper;
  final FeedPostDtoToModelMapper feedPostMapper;

  @override
  FutureResult<PostModel> createPost(PostDataModel postData) async {
    return processSupabaseResult<dynamic, PostModel>(
      request: () async {
        final draftPost = await postService.createPostWithMedia(
          authorId: postData.authorId,
          contentType: postData.contentType,
          mediaFiles: postData.mediaFiles,
          contentDate: postData.contentDate,
          parentId: postData.parentId,
          description: postData.description,
          thumbnailFile: postData.thumbnailFile,
          publishedTimezone: postData.publishedTimezone,
          isLockoutPost: postData.isLockoutPost,
        );

        if (postData.taggedUserIds.isNotEmpty) {
          await postService.addPostTags(
            postId: draftPost.id,
            taggedUserIds: postData.taggedUserIds,
          );
        }

        if (postData.excludedUserIds.isNotEmpty) {
          await postService.addPostExclusions(
            postId: draftPost.id,
            excludedUserIds: postData.excludedUserIds,
          );
        }

        final publishedPost = await postService.publishPost(draftPost.id);
        return Result.success(publishedPost);
      },
      responseMapper: (publishedPostDto) async {
        return postMapper.mapDto(publishedPostDto);
      },
      exceptionMapper: CreatePostExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<PostModel> updatePost(PostDataModel postData) async {
    return processSupabaseResult<dynamic, PostModel>(
      request: () async {
        if (postData.postId == null) {
          throw Exception('Post ID is required for update');
        }

        final updatedPost = await postService.updatePost(
          postId: postData.postId!,
          description: postData.description ?? '',
          taggedUserIds: postData.taggedUserIds,
          excludedUserIds: postData.excludedUserIds,
          newMediaFile: postData.mediaFiles.isNotEmpty
              ? postData.mediaFiles.first
              : null,
          newThumbnailFile: postData.thumbnailFile,
          authorId: postData.authorId,
          contentType: postData.contentType,
        );

        return Result.success(updatedPost);
      },
      responseMapper: (updatedPostDto) async {
        return postMapper.mapDto(updatedPostDto);
      },
      exceptionMapper: CreatePostExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<FeedResponseModel> getFeedPosts({
    required String userId,
    required DateTime targetDate,
    int pageSize = 15,
    int pageOffset = 0,
    DateTime? cursorBefore,
    DateTime? cursorAfter,
  }) async {
    return processSupabaseResult<dynamic, FeedResponseModel>(
      request: () async {
        final feedResponseDto = await postService.getFeedPosts(
          userId: userId,
          targetDate: targetDate,
          pageSize: pageSize,
          pageOffset: pageOffset,
          cursorBefore: cursorBefore,
          cursorAfter: cursorAfter,
        );
        return Result.success(feedResponseDto);
      },
      responseMapper: (feedResponseDto) async {
        return feedResponseMapper.mapDto(feedResponseDto);
      },
      exceptionMapper: FeedPostExceptionMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<FeedPostModel> getPostById({required String postId}) async {
    return processSupabaseResult<dynamic, FeedPostModel>(
      request: () async {
        final feedPostDto = await postService.getPostById(postId: postId);
        return Result.success(feedPostDto);
      },
      responseMapper: (feedPostDto) async {
        return feedPostMapper.mapDto(feedPostDto);
      },
      exceptionMapper: FeedPostExceptionMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<List<FeedPostModel>> getPostReplies({required String postId}) async {
    return processSupabaseResult<dynamic, List<FeedPostModel>>(
      request: () async {
        final replyDtos = await postService.getPostReplies(postId: postId);
        return Result.success(replyDtos);
      },
      responseMapper: (replyDtos) async {
        return feedPostMapper.mapDtoList(replyDtos);
      },
      exceptionMapper: FeedPostExceptionMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<void> deletePost({
    required String postId,
    required String authorId,
  }) async {
    return processSupabaseResult<void, void>(
      request: () async {
        await postService.deletePost(postId: postId, authorId: authorId);
        return Result.success(null);
      },
      responseMapper: (_) async {},
      exceptionMapper: CreatePostExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<void> hidePost({
    required String postId,
    required String userId,
  }) async {
    return processSupabaseResult<void, void>(
      request: () async {
        await postService.hidePost(postId: postId, userId: userId);
        return Result.success(null);
      },
      responseMapper: (_) async {},
      exceptionMapper: CreatePostExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<PostReportModel> reportPost({
    required String postId,
    required String userId,
    required String reason,
  }) async {
    return processSupabaseResult<dynamic, PostReportModel>(
      request: () async {
        final hasReported = await postService.hasUserReportedPost(
          postId: postId,
          userId: userId,
        );

        if (hasReported) {
          return Result.failure(
            const PostReportException(
              'You have already reported this post',
              'REPORT_ALREADY_EXISTS',
            ),
          );
        }

        final dto = await postService.createReport(
          postId: postId,
          userId: userId,
          reason: reason,
        );

        return Result.success(dto);
      },
      responseMapper: (dto) async {
        final mapper = PostReportDtoToModelMapper();
        return mapper.mapDto(dto);
      },
      exceptionMapper: CreatePostExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<List<PostReactionModel>> getPostReactions({
    required String postId,
  }) async {
    return processSupabaseResult<List<dynamic>, List<PostReactionModel>>(
      request: () async {
        final reactions = await postService.getPostReactions(postId: postId);
        return Result.success(reactions);
      },
      responseMapper: (reactionDtos) async {
        final mapper = PostReactionDtoToModelMapper();
        return reactionDtos.map((dto) => mapper.mapDto(dto)).toList();
      },
      exceptionMapper: CreatePostExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<PostReactionModel> addReaction({
    required String postId,
    required String userId,
    required String reaction,
  }) async {
    return processSupabaseResult<dynamic, PostReactionModel>(
      request: () async {
        final reactionDto = await postService.addReaction(
          postId: postId,
          userId: userId,
          reaction: reaction,
        );
        return Result.success(reactionDto);
      },
      responseMapper: (reactionDto) async {
        final mapper = PostReactionDtoToModelMapper();
        return mapper.mapDto(reactionDto);
      },
      exceptionMapper: CreatePostExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<void> deleteReaction({required String reactionId}) async {
    return processSupabaseResult<void, void>(
      request: () async {
        await postService.deleteReaction(reactionId: reactionId);
        return Result.success(null);
      },
      responseMapper: (_) async {},
      exceptionMapper: CreatePostExceptionsMapper.fromSupabaseException,
    );
  }
}
