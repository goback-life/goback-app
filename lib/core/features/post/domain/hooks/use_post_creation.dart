import 'dart:io';

import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/post/data/dtos/post_creation_dto.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/features/post/domain/models/post_data_model.dart';
import 'package:cloudless/core/features/post/domain/models/post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/create_post_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/parent_post_reference_notifier_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/post_action_notifier_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/post_creation_lock_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/post_creation_notifier_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/update_post_provider.dart';
import 'package:cloudless/core/features/timezone/data/providers/current_timezone_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

typedef PostCreationResult = ({
  PostCreationDto data,
  File? mainImage,
  File? thumbnail,
  bool isLoading,
  bool canPublish,
  ValueChanged<String> updateDescription,
  ValueChanged<List<String>> updateTaggedUsers,
  ValueChanged<List<String>> updateExcludedUsers,
  Future<void> Function(File) updateImage,
  ValueChanged<File?> updateFirstFrame,
  ValueChanged<File?> updateThumbnail,
  Future<Result<PostModel>?> Function() publishPost,
  Future<Result<PostModel>?> Function(List<String> excludedUserIds)
  publishPostWithExclusions,
  VoidCallback resetCreation,
});

PostCreationResult usePostCreation(WidgetRef ref) {
  final postCreationData = ref.watch(postCreationNotifierProvider);
  final postCreationNotifier = ref.read(postCreationNotifierProvider.notifier);
  final currentUser = ref.watch(getCurrentUserProvider);
  final isLoading = useState<bool>(false);

  void updateDescription(String description) {
    postCreationNotifier.updateDescription(description);
  }

  void updateTaggedUsers(List<String> taggedUserIds) {
    postCreationNotifier.updateTaggedUsers(taggedUserIds);
  }

  void updateExcludedUsers(List<String> excludedUserIds) {
    postCreationNotifier.updateExcludedUsers(excludedUserIds);
  }

  Future<void> updateImage(File image) async {
    await postCreationNotifier.updateImage(image);
  }

  void updateFirstFrame(File? firstFrame) {
    postCreationNotifier.updateFirstFrame(firstFrame);
  }

  void updateThumbnail(File? thumbnail) {
    postCreationNotifier.updateThumbnail(thumbnail);
  }

  void resetCreation() {
    postCreationNotifier.reset();
  }

  Future<Result<PostModel>?> publishPostWithExclusions(
    List<String> excludedUserIds,
  ) async {
    if (!postCreationData.isValid) {
      return null;
    }

    // For text posts, mainImage is not required
    // For other posts, mainImage is required (unless editing)
    if (!postCreationData.isEditing &&
        postCreationData.contentType != ContentType.text &&
        postCreationData.mainImage == null) {
      return null;
    }

    return currentUser.when(
      data: (userResult) => userResult.fold(
        (user) async {
          // Check if a post creation is already in progress for this user
          final lockNotifier = ref.read(postCreationLockProvider.notifier);

          if (lockNotifier.isLocked(user.id)) {
            logger.warning(
              'Post creation already in progress for user ${user.id}',
            );
            return null;
          }

          // Lock to prevent duplicate submissions
          lockNotifier.lock(user.id);
          isLoading.value = true;

          try {
            final timezone = await ref.read(currentTimezoneProvider.future);

            final postData = PostDataModel(
              postId: postCreationData.postId,
              parentId: postCreationData.parentId,
              authorId: user.id,
              contentType: postCreationData.contentType,
              mediaFiles: postCreationData.mainImage != null
                  ? [postCreationData.mainImage!]
                  : [],
              thumbnailFile: postCreationData.thumbnailForUpload,
              contentDate: postCreationData.effectiveCreatedAt,
              description: postCreationData.description.isEmpty
                  ? null
                  : postCreationData.description,
              taggedUserIds: postCreationData.taggedUserIds,
              excludedUserIds: excludedUserIds,
              publishedTimezone: timezone,
            );

            final Result<PostModel> result;

            if (postCreationData.isEditing) {
              result = await ref.read(updatePostProvider(postData).future);
            } else {
              result = await ref.read(createPostProvider(postData).future);
            }

            result.fold(
              (post) {
                postCreationNotifier.reset();
                ref.read(parentPostReferenceNotifierProvider.notifier).clear();

                if (postCreationData.isEditing) {
                  ref
                      .read(postActionNotifierProvider.notifier)
                      .notifyPostUpdated();
                } else {
                  ref
                      .read(postActionNotifierProvider.notifier)
                      .notifyPostCreated();
                }
              },
              (error) {
                logger.error(
                  'Failed to ${postCreationData.isEditing ? "update" : "create"} post',
                  exception: error,
                );
              },
            );

            return result;
          } catch (e, stackTrace) {
            logger.error(
              'Unexpected error during post ${postCreationData.isEditing ? "update" : "creation"}',
              exception: e,
              stackTrace: stackTrace,
            );
            return Result.failure(Exception(e.toString()));
          } finally {
            isLoading.value = false;
            // Always unlock, even if an error occurred
            lockNotifier.unlock(user.id);
          }
        },
        (error) async {
          logger.error('User auth error', exception: error);
          return Result.failure(error);
        },
      ),
      loading: () async => null,
      error: (error, _) async {
        logger.error('User provider error', exception: error);
        return Result.failure(Exception(error.toString()));
      },
    );
  }

  Future<Result<PostModel>?> publishPost() async {
    return publishPostWithExclusions([]);
  }

  final canPublish =
      postCreationData.isValid && !isLoading.value && currentUser.hasValue;

  return (
    data: postCreationData,
    mainImage: postCreationData.mainImage,
    thumbnail: postCreationData.thumbnail,
    isLoading: isLoading.value,
    canPublish: canPublish,
    updateDescription: updateDescription,
    updateTaggedUsers: updateTaggedUsers,
    updateExcludedUsers: updateExcludedUsers,
    updateImage: updateImage,
    updateFirstFrame: updateFirstFrame,
    updateThumbnail: updateThumbnail,
    publishPost: publishPost,
    publishPostWithExclusions: publishPostWithExclusions,
    resetCreation: resetCreation,
  );
}
