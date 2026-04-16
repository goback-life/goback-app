import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_post_reactions.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/models/post_reaction_model.dart';
import 'package:cloudless/core/models/user_model.dart';
import 'package:cloudless/presentation/components/custom_emoji_picker.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_reaction_add_button.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_reaction_counter.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_reaction_picker_modal.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_reactions_list_modal.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class PostDetailReactions extends HookConsumerWidget
    with MainLayout, PostDetailLayout {
  const PostDetailReactions({
    required this.post,
    required this.isCurrentUserPost,
    this.isFromCalendar = false,
    super.key,
  });

  final FeedPostModel post;
  final bool isCurrentUserPost;
  final bool isFromCalendar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final reactionsResult = usePostReactions(ref, post.id);
    final AsyncValue<Result<List<PostReactionModel>>> reactions =
        reactionsResult.reactions
            as AsyncValue<Result<List<PostReactionModel>>>;
    final AsyncValue<Result<UserModel>> currentUserAsync = ref.watch(
      getCurrentUserProvider,
    );

    final isPickerOpen = useState(false);

    final canAddReactions = isCurrentUserPost || post.isAuthorConnected;

    String? currentUserReaction;
    final currentUserId = currentUserAsync.whenOrNull(
      data: (userResult) => userResult.fold((user) => user.id, (_) => null),
    );

    if (currentUserId != null) {
      reactions.whenData((result) {
        result.fold((reactionsList) {
          final userReaction = reactionsList
              .where((reaction) => reaction.userId == currentUserId)
              .toList();
          if (userReaction.isNotEmpty) {
            currentUserReaction = userReaction.first.reaction;
          }
        }, (_) {});
      });
    }

    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            reactions.when(
              data: (result) {
                return result.fold(
                  (reactionsList) {
                    if (reactionsList.isEmpty) {
                      if (!canAddReactions) {
                        return const SizedBox.shrink();
                      }

                      return PostDetailReactionAddButton(
                        onTap: () {
                          _showFullEmojiPicker(
                            context,
                            currentUserReaction,
                            reactionsResult,
                          );
                        },
                      );
                    }

                    final groupedReactions = _groupReactions(reactionsList);
                    final totalCount = reactionsList.length;
                    final uniqueEmojis = groupedReactions.keys.take(3).toList();

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PostDetailReactionCounter(
                          uniqueEmojis: uniqueEmojis,
                          totalCount: totalCount,
                          onTap: isPickerOpen.value
                              ? null
                              : () {
                                  _showReactionsList(context, reactionsList);
                                },
                        ),
                        if (canAddReactions) ...[
                          SizedBox(width: reactionIconSpacing),
                          PostDetailReactionAddButton(
                            onTap: () {
                              _showFullEmojiPicker(
                                context,
                                currentUserReaction,
                                reactionsResult,
                              );
                            },
                          ),
                        ],
                      ],
                    );
                  },
                  (error) {
                    if (!canAddReactions) {
                      return const SizedBox.shrink();
                    }

                    return PostDetailReactionAddButton(
                      onTap: () {
                        _showReactionPickerModal(
                          context,
                          ref,
                          reactionsResult,
                          currentUserAsync,
                        );
                      },
                    );
                  },
                );
              },
              loading: () {
                if (!canAddReactions) {
                  return const SizedBox.shrink();
                }
                return PostDetailReactionAddButton(onTap: () {});
              },
              error: (error, stack) {
                if (!canAddReactions) {
                  return const SizedBox.shrink();
                }
                return PostDetailReactionAddButton(onTap: () => {});
              },
            ),
          ],
        ),
      ],
    );
  }

  Map<String, int> _groupReactions(List<PostReactionModel> reactions) {
    final grouped = <String, int>{};
    for (final reaction in reactions) {
      grouped[reaction.reaction] = (grouped[reaction.reaction] ?? 0) + 1;
    }
    return grouped;
  }

  void _showReactionsList(
    BuildContext context,
    List<PostReactionModel> reactions,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PostDetailReactionsListModal(reactions: reactions),
    );
  }

  void _showReactionPickerModal(
    BuildContext context,
    WidgetRef ref,
    PostReactionsResult reactionsResult,
    AsyncValue<Result<UserModel>> currentUserAsync,
  ) {
    final AsyncValue<Result<List<PostReactionModel>>> reactions =
        reactionsResult.reactions
            as AsyncValue<Result<List<PostReactionModel>>>;
    String? currentUserReaction;

    final currentUserId = currentUserAsync.whenOrNull(
      data: (userResult) => userResult.fold((user) => user.id, (_) => null),
    );

    if (currentUserId != null) {
      reactions.whenData((result) {
        result.fold((reactionsList) {
          final userReaction = reactionsList
              .where((reaction) => reaction.userId == currentUserId)
              .toList();
          if (userReaction.isNotEmpty) {
            currentUserReaction = userReaction.first.reaction;
          }
        }, (_) {});
      });
    }

    String? lastSelectedEmoji = currentUserReaction;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => PostDetailReactionPickerModal(
        initialSelectedEmoji: currentUserReaction,
        onReactionSelected: (emoji) {
          lastSelectedEmoji = emoji;
        },
      ),
    ).then((_) async {
      if (lastSelectedEmoji == currentUserReaction) {
        return;
      }

      if (lastSelectedEmoji == null && currentUserReaction != null) {
        await reactionsResult.removeReaction();
      } else if (lastSelectedEmoji != null) {
        await reactionsResult.addReaction(lastSelectedEmoji!);
      }
    });
  }

  void _showFullEmojiPicker(
    BuildContext context,
    String? currentUserReaction,
    PostReactionsResult reactionsResult,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Full emoji picker
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  height: 400,
                  child: CustomEmojiPicker(
                    onEmojiSelected: (emoji) async {
                      await reactionsResult.addReaction(emoji.char);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
