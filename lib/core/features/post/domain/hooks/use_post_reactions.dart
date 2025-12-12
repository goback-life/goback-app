import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/add_reaction_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/delete_reaction_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/get_post_reactions_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

typedef PostReactionsResult = ({
  AsyncValue<dynamic> reactions,
  bool isLoading,
  Future<void> Function(String emoji) addReaction,
  Future<void> Function() removeReaction,
  VoidCallback refresh,
});

PostReactionsResult usePostReactions(WidgetRef ref, String postId) {
  final currentUser = ref.watch(getCurrentUserProvider);
  final reactions = ref.watch(getPostReactionsProvider(postId: postId));
  final isLoading = useState<bool>(false);

  Future<void> addReaction(String emoji) async {
    if (isLoading.value) {
      return;
    }

    await currentUser.when(
      data: (result) async {
        result.fold(
          (user) async {
            isLoading.value = true;

            try {
              final addResult = await ref.read(
                addReactionProvider(
                  postId: postId,
                  userId: user.id,
                  reaction: emoji,
                ).future,
              );

              addResult.fold(
                (_) {
                  ref.invalidate(getPostReactionsProvider(postId: postId));
                },
                (error) {
                  logger.error('Failed to add reaction', exception: error);
                },
              );
            } finally {
              isLoading.value = false;
            }
          },
          (error) {
            logger.error('User not available', exception: error);
          },
        );
      },
      loading: () {},
      error: (error, _) {
        logger.error('Error getting current user', exception: error);
      },
    );
  }

  Future<void> removeReaction() async {
    if (isLoading.value) {
      return;
    }

    await currentUser.when(
      data: (result) async {
        result.fold(
          (user) async {
            final reactionsResult = await reactions.when(
              data: (result) async => result,
              loading: () async => null,
              error: (_, __) async => null,
            );

            if (reactionsResult == null) {
              return;
            }

            String? userReactionId;
            reactionsResult.fold(
              (reactionsList) {
                final userReaction = reactionsList.firstWhere(
                  (reaction) => reaction.userId == user.id,
                );
                userReactionId = userReaction.id;
              },
              (error) {
                logger.error('Error getting reactions', exception: error);
              },
            );

            if (userReactionId == null) {
              logger.warning('No reaction to remove for current user');
              return;
            }

            isLoading.value = true;

            try {
              final deleteResult = await ref.read(
                deleteReactionProvider(reactionId: userReactionId!).future,
              );

              deleteResult.fold(
                (_) {
                  ref.invalidate(getPostReactionsProvider(postId: postId));
                },
                (error) {
                  logger.error('Failed to remove reaction', exception: error);
                },
              );
            } catch (e) {
              logger.error('Error removing reaction', exception: e);
            } finally {
              isLoading.value = false;
            }
          },
          (error) {
            logger.error('User not available', exception: error);
          },
        );
      },
      loading: () {},
      error: (error, _) {
        logger.error('Error getting current user', exception: error);
      },
    );
  }

  void refresh() {
    ref.invalidate(getPostReactionsProvider(postId: postId));
  }

  return (
    reactions: reactions,
    isLoading: isLoading.value,
    addReaction: addReaction,
    removeReaction: removeReaction,
    refresh: refresh,
  );
}
