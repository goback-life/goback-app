import 'package:cloudless/core/features/comment/domain/hooks/use_post_comments.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_comment_add_button.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_comment_counter.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_comments_list_modal.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class PostDetailComments extends HookConsumerWidget
    with MainLayout, PostDetailLayout {
  const PostDetailComments({
    required this.post,
    required this.isCurrentUserPost,
    super.key,
  });

  final FeedPostModel post;
  final bool isCurrentUserPost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsResult = usePostComments(ref, post.id);
    final canComment = isCurrentUserPost || post.isAuthorConnected;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (commentsResult.commentCount > 0) ...[
          PostDetailCommentCounter(
            count: commentsResult.commentCount,
            onTap: () => _showCommentsList(context, canComment),
          ),
          if (canComment) SizedBox(width: commentCounterSpacing),
        ],
        if (canComment)
          PostDetailCommentAddButton(
            onTap: () => _showCommentsList(context, canComment),
          ),
      ],
    );
  }

  void _showCommentsList(BuildContext context, bool canComment) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PostDetailCommentsListModal(
        postId: post.id,
        canComment: canComment,
      ),
    );
  }
}
