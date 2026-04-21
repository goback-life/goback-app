import 'dart:io';

import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/lockout/data/providers/lockout_session_service_provider.dart';
import 'package:cloudless/core/features/lockout/data/providers/manual_lockout_storable_provider.dart';
import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/core/features/lockout/domain/providers/pending_lockout_post_provider.dart';
import 'package:cloudless/core/features/supabase/data/providers/supabase_client_provider.dart';
import 'package:cloudless/core/features/post/data/dtos/post_creation_dto.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/features/post/domain/models/post_data_model.dart';
import 'package:cloudless/core/features/post/domain/models/post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/create_post_provider.dart';
import 'package:cloudless/core/features/post/domain/utilities/url_shortener.dart';
import 'package:cloudless/core/features/post/domain/exceptions/post_exception.dart';
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

    // Lockout guard: new posts require a lockout session (defense in depth)
    // Editing existing posts does not require lockout context
    final pendingLockoutId = ref.read(pendingLockoutPostProvider);
    if (!postCreationData.isEditing && pendingLockoutId == null) {
      logger.warning('Post creation blocked: no lockout session');
      return Result.failure(
        const PostException(
          'Post creation requires lockout session',
          'lockout_required',
        ),
      );
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

            // Check if this is a lockout post
            final pendingLockoutId = ref.read(pendingLockoutPostProvider);
            logger.info(
              'Creating post with pendingLockoutId: $pendingLockoutId',
            );

            // Manual @mentions only — lockout participants are derived from
            // lockout_participants table at read time (no auto-tagging needed)
            final finalTaggedUserIds = List<String>.from(
              postCreationData.taggedUserIds,
            );

            // Fetch lockout owner ID (needed for updateSessionPostId below)
            String? lockoutOwnerId;
            if (pendingLockoutId != null) {
              final sessionService = ref.read(lockoutSessionServiceProvider);
              final sessionResult = await sessionService.getSessionById(
                pendingLockoutId,
              );
              sessionResult.fold(
                (session) {
                  lockoutOwnerId = session?.userId;
                },
                (error) =>
                    logger.warning('Failed to fetch lockout session: $error'),
              );
            }

            // Auto-tag venue companions (friends at same venue during lockout)
            if (pendingLockoutId != null) {
              final sessionService = ref.read(lockoutSessionServiceProvider);
              final companions = await sessionService.getVenueCompanions(
                pendingLockoutId,
              );
              for (final companion in companions) {
                final companionId = companion['user_id'] as String?;
                if (companionId != null &&
                    companionId != user.id &&
                    !finalTaggedUserIds.contains(companionId)) {
                  finalTaggedUserIds.add(companionId);
                }
              }
              if (companions.isNotEmpty) {
                logger.info(
                  'Auto-tagged ${companions.length} venue companions',
                );
              }
            }

            // Shorten URLs in description for text posts (convert to markdown with domain alias)
            final description =
                postCreationData.contentType == ContentType.text &&
                    postCreationData.description.isNotEmpty
                ? UrlShortener.shortenUrlsInText(postCreationData.description)
                : (postCreationData.description.isEmpty
                      ? null
                      : postCreationData.description);

            final postData = PostDataModel(
              postId: postCreationData.postId,
              authorId: user.id,
              contentType: postCreationData.contentType,
              mediaFiles: postCreationData.mainImage != null
                  ? [postCreationData.mainImage!]
                  : [],
              thumbnailFile: postCreationData.thumbnailForUpload,
              description: description,
              taggedUserIds: finalTaggedUserIds,
              excludedUserIds: excludedUserIds,
              publishedTimezone: timezone,
              lockoutId: pendingLockoutId,
            );

            final Result<PostModel> result;

            if (postCreationData.isEditing) {
              result = await ref.read(updatePostProvider(postData).future);
            } else {
              result = await ref.read(createPostProvider(postData).future);
            }

            // Handle post-creation cleanup before returning (must await)
            await result.asyncFold(
              (post) async {
                postCreationNotifier.reset();
                ref.read(parentPostReferenceNotifierProvider.notifier).clear();

                // Link post to lockout session and update weekly stats
                if (pendingLockoutId != null) {
                  final sessionService = ref.read(
                    lockoutSessionServiceProvider,
                  );
                  final storable = ref.read(manualLockoutStorableProvider);
                  final userStartedAt = await storable.getLockoutStart();

                  // Only session owner sets post_id; joiners link via posts.lockout_id
                  if (lockoutOwnerId == user.id) {
                    final updateResult = await sessionService
                        .updateSessionPostId(
                          sessionId: pendingLockoutId,
                          postId: post.id,
                        );
                    updateResult.fold(
                      (_) => logger.info(
                        'Linked post ${post.id} to lockout session $pendingLockoutId',
                      ),
                      (error) => logger.warning(
                        'Failed to link post to lockout session: $error',
                      ),
                    );
                  }

                  // Notify lockout participants about the new post
                  try {
                    await ref
                        .read(supabaseClientProvider)
                        .rpc(
                          'notify_lockout_participants',
                          params: {
                            'p_post_id': post.id,
                            'p_lockout_id': pendingLockoutId,
                            'p_author_id': user.id,
                          },
                        );
                  } catch (e) {
                    logger.warning('Failed to notify lockout participants: $e');
                  }

                  // Update weekly stats with user's actual start time (important for joiners)
                  await sessionService.completeSessionWithStats(
                    pendingLockoutId,
                    userStartedAt: userStartedAt,
                  );

                  // Notify feed BEFORE clearing lockout state — clearing
                  // pendingLockoutPostProvider triggers the content editor
                  // guard which navigates home. The feed must have the
                  // create event so it can fetch the new post.
                  ref
                      .read(postActionNotifierProvider.notifier)
                      .notifyPostCreated(postId: post.id);

                  ref.read(pendingLockoutPostProvider.notifier).clear();
                  await storable.clearLockout();
                  await ref
                      .read(manualLockoutNotifierProvider.notifier)
                      .clearLockout();
                }

                if (postCreationData.isEditing) {
                  ref
                      .read(postActionNotifierProvider.notifier)
                      .notifyPostUpdated();
                } else if (pendingLockoutId == null) {
                  // Non-lockout posts: notify here (lockout posts notify
                  // earlier, before clearing pendingLockoutPostProvider).
                  ref
                      .read(postActionNotifierProvider.notifier)
                      .notifyPostCreated(postId: post.id);
                }
              },
              (error) async {
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
            // Guard: widget may have been disposed by lockout cleanup
            try {
              isLoading.value = false;
            } catch (_) {}
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
