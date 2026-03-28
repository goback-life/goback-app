import 'package:cloudless/core/features/post/domain/models/post_reaction_model.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/components/main_member/main_member_item.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/pages/post_detail/utilities/post_detail_navigation.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class PostDetailReactionsListModal extends HookConsumerWidget
    with MainLayout, PostDetailLayout {
  const PostDetailReactionsListModal({required this.reactions, super.key});

  final List<PostReactionModel> reactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppGlassContainer(
      config: GlassConfig(
        variant: GlassVariant.regular,
        cornerRadius: reactionsListBorderRadius,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * reactionsListMaxHeightRatio,
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
                color: MainColors.white.withValues(alpha: 0.3),
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
      ),
    );
  }

  void _navigateToUserProfile(WidgetRef ref, String userId) =>
      PostDetailNavigation.navigateToUserProfile(ref, userId, '');
}
