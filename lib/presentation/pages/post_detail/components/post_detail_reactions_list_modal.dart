import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/is_user_connected_provider.dart';
import 'package:cloudless/core/features/post/domain/models/post_reaction_model.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/presentation/components/main_member/main_member_item.dart';
import 'package:cloudless/presentation/pages/circle_profile/circle_profile_routable.dart';
import 'package:cloudless/presentation/pages/external_profile/external_profile_routable.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/pages/profile/profile_routable.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class PostDetailReactionsListModal extends HookConsumerWidget
    with MainLayout, PostDetailLayout {
  const PostDetailReactionsListModal({required this.reactions, super.key});

  final List<PostReactionModel> reactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height * reactionsListMaxHeightRatio,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(reactionsListBorderRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(top: reactionsListTopPadding),
            child: Container(
              width: reactionsListHandleWidth,
              height: reactionsListHandleHeight,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(reactionsListHandleRadius),
              ),
            ),
          ),
          SizedBox(height: reactionsListHandleToContent),

          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: reactionsListHorizontalPadding,
              ),
              itemCount: reactions.length,
              itemBuilder: (context, index) {
                final reaction = reactions[index];
                final profileAsync = ref.watch(
                  getProfileProvider(reaction.userId),
                );

                return profileAsync.when(
                  data: (result) {
                    return result.fold((profile) {
                      if (profile == null) {
                        return const SizedBox.shrink();
                      }

                      return MainMemberItem(
                        member: profile,
                        action: MemberItemAction.reaction,
                        reactionEmoji: reaction.reaction,
                        onTap: () =>
                            _navigateToUserProfile(ref, reaction.userId),
                      );
                    }, (error) => const SizedBox.shrink());
                  },
                  loading: () => const SizedBox(
                    height: 60,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
          ),
          SizedBox(height: reactionsListBottomPadding),
        ],
      ),
    );
  }

  void _navigateToUserProfile(WidgetRef ref, String userId) async {
    final currentUserAsync = ref.read(getCurrentUserProvider);
    final isCurrentUser =
        currentUserAsync.whenOrNull(
          data: (userResult) =>
              userResult.fold((user) => user.id == userId, (error) => false),
        ) ??
        false;

    if (isCurrentUser) {
      router.push(const ProfileRoutable());
    } else {
      final connectionResult = await ref.read(
        isUserConnectedProvider(userId).future,
      );
      final isConnected = connectionResult.fold((isConnected) => isConnected, (
        error,
      ) {
        return false;
      });

      if (isConnected) {
        router.push(CircleProfileRoutable(userId: userId));
      } else {
        router.push(ExternalProfileRoutable(userId: userId));
      }
    }
  }
}
