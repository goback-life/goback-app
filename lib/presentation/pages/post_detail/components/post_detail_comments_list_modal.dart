import 'package:cloudless/core/features/comment/domain/hooks/use_post_comments.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_comment_input.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_comment_item.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class PostDetailCommentsListModal extends HookConsumerWidget
    with MainLayout, PostDetailLayout {
  const PostDetailCommentsListModal({
    required this.postId,
    required this.canComment,
    super.key,
  });

  final String postId;
  final bool canComment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final commentsResult = usePostComments(ref, postId);

    return AppGlassContainer(
      config: GlassConfig(
        variant: GlassVariant.regular,
        cornerRadius: commentsListBorderRadius,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * commentsListMaxHeightRatio,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(top: commentsListTopPadding),
              child: Container(
                width: commentsListHandleWidth,
                height: commentsListHandleHeight,
                decoration: BoxDecoration(
                  color: MainColors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(commentsListHandleRadius),
                ),
              ),
            ),
            SizedBox(height: commentsListHandleToContent),

            Flexible(
              child: commentsResult.comments.when(
                data: (result) {
                  return result.fold(
                    (comments) {
                      if (comments.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: commentsListHorizontalPadding,
                            vertical: 32,
                          ),
                          child: Text(
                            'No comments yet',
                            style: textTheme.bodyMedium?.copyWith(
                              color: MainColors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.symmetric(
                          horizontal: commentsListHorizontalPadding,
                        ),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return PostDetailCommentItem(
                            comment: comment,
                            isOwnComment: commentsResult.isOwnComment(comment),
                            onDelete: () =>
                                commentsResult.deleteComment(comment.id),
                          );
                        },
                      );
                    },
                    (error) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: commentsListHorizontalPadding,
                          vertical: 32,
                        ),
                        child: Text(
                          'Failed to load comments',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: commentsListHorizontalPadding,
                    vertical: 32,
                  ),
                  child: Text(
                    'Failed to load comments',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),

            if (canComment && commentsResult.canAddMore)
              PostDetailCommentInput(
                onSubmit: commentsResult.addComment,
                isSubmitting: commentsResult.isSubmitting,
              )
            else if (canComment && !commentsResult.canAddMore)
              Padding(
                padding: EdgeInsets.all(commentsListInputPadding),
                child: SafeArea(
                  top: false,
                  child: Text(
                    'You have reached the limit of ${kMaxCommentsPerUserPerPost} comments on this post',
                    style: textTheme.bodySmall?.copyWith(
                      color: MainColors.white.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              SizedBox(height: commentsListBottomPadding),
          ],
        ),
      ),
    );
  }
}
