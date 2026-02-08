import 'package:cloudless/core/features/comment/domain/models/post_comment_model.dart';
import 'package:cloudless/core/utilities/date_formatter.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class PostDetailCommentItem extends StatelessWidget
    with MainLayout, PostDetailLayout {
  const PostDetailCommentItem({
    required this.comment,
    required this.isOwnComment,
    required this.onDelete,
    super.key,
  });

  final PostCommentModel comment;
  final bool isOwnComment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: commentContentSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileImage(
            imageUrl: comment.authorAvatarUrl,
            username: comment.authorUsername,
            size: commentAvatarSize,
            isEditable: false,
            showFromProfile: false,
            showFullScreen: false,
            showLoading: false,
          ),
          SizedBox(width: commentItemSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: comment.authorUsername,
                              style: textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: '  ${DateFormatter.formatTimeWithDateIfNeeded(
                                comment.createdAt,
                                translator.currentLocale.toString(),
                              )}',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isOwnComment)
                      GestureDetector(
                        onTap: onDelete,
                        child: Icon(
                          Icons.close,
                          size: commentDeleteIconSize,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  comment.content,
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
