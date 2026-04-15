import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/comment/domain/hooks/use_post_comments.dart';
import 'package:cloudless/core/features/comment/domain/models/post_comment_model.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_mention_autocomplete.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:cloudless/core/features/storage/data/providers/signed_url_provider.dart';
import 'package:cloudless/core/features/supabase/utilities/supabase_buckets.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_overlay_input.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_participants.dart';
import 'package:cloudless/presentation/pages/post_detail/utilities/post_detail_navigation.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:cloudless/presentation/utilities/mention_text_parser.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

Widget _cachedAvatar(String? url, double size, {String? name}) {
  const placeholder = Color(0xFF555555);
  if (url != null && url.isNotEmpty) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: size,
      height: size,
      memCacheWidth: (size * 2).toInt(),
      memCacheHeight: (size * 2).toInt(),
      placeholder: (_, __) => _initialCircle(size, name, placeholder),
      errorWidget: (_, __, ___) => _initialCircle(size, name, placeholder),
    );
  }
  return _initialCircle(size, name, placeholder);
}

Widget _initialCircle(double size, String? name, Color bg) {
  if (name != null && name.isNotEmpty) {
    return Container(
      width: size,
      height: size,
      color: bg,
      alignment: Alignment.center,
      child: Text(
        name[0].toUpperCase(),
        style: TextStyle(
          fontFamily: MainFontFamilies.quicksand,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: MainColors.white,
        ),
      ),
    );
  }
  return Container(width: size, height: size, color: bg);
}

/// Scrollable content column for the post detail overlay.
///
/// Renders: author row, description, @tags, comment input pill,
/// "Thoughts" header, and the comments list.
class PostDetailOverlayContent extends HookConsumerWidget {
  const PostDetailOverlayContent({
    required this.post,
    required this.scale,
    required this.scrollController,
    required this.squircleTop,
    required this.squircleSize,
    required this.contentHPad,
    required this.contentWidth,
    this.bottomInset = 0,
    this.readOnly = false,
    super.key,
  });

  final FeedPostModel post;
  final double scale;
  final ScrollController scrollController;
  final double squircleTop;
  final double squircleSize;
  final double contentHPad;
  final double contentWidth;
  final double bottomInset;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsResult = usePostComments(ref, post.id);
    final comments = _extractComments(commentsResult);
    final textController = useTextEditingController();
    final mentionState = useMentionAutocomplete(ref);
    final allUsers = mentionState.allUsers;
    final myFriendIds = useMemoized(() => allUsers.map((u) => u.id).toSet(), [
      allUsers,
    ]);
    final mentionedIds = useState<List<String>>([]);
    final descExpanded = useState(false);

    // Filter comment mentions to users who can see the post.
    // If post author is in viewer's circle, all circle members can see it.
    // If cross-circle lockout post, only lockout participants can see it.
    final commentMentionFilter = useMemoized(() {
      if (!post.isLockoutPost || post.isAuthorConnected) {
        // Author is friend or this is viewer's own post — all circle can see it
        return null;
      }
      // Cross-circle lockout post — only lockout participants + author can see it
      final canSee = {post.authorId, ...post.lockoutParticipantIds};
      return (ProfileModel u) => canSee.contains(u.id);
    }, [post.isLockoutPost, post.isAuthorConnected, post.lockoutParticipantIds]);

    void navigateToUser(String userId) =>
        PostDetailNavigation.navigateToUserProfile(ref, userId, '');
    void navigateToMention(String username) {
      final user = allUsers.where((u) => u.username == username).firstOrNull;
      if (user != null) navigateToUser(user.id);
    }

    // Generate signed avatar URLs directly from Supabase Storage
    final authorIds = <String>{
      post.authorId,
      ...comments.map((c) => c.authorId),
    };
    final avatarUrls = <String, String?>{};
    for (final id in authorIds) {
      avatarUrls[id] = ref
          .watch(signedUrlProvider(SupabaseBuckets.avatars, id))
          .whenOrNull(data: (url) => url);
    }
    String? resolveAvatar(String userId) => avatarUrls[userId];

    final squircleBottom = squircleTop + squircleSize;
    final authorGap = 15.0 * scale;
    final avatarH = 39.0 * scale;
    // Gap before input pill must push it above squircle's corner curve
    final cornerR = squircleSize * 0.15;
    final inputGap = authorGap + cornerR;

    // Only author + description for initial rest position
    var visibleH = avatarH;
    final hasDesc = post.description != null && post.description!.isNotEmpty;
    if (hasDesc) {
      final dp = TextPainter(
        text: TextSpan(
          text: post.description!,
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w400,
            fontSize: 15.0 * scale,
            letterSpacing: -0.9 * scale,
          ),
        ),
        maxLines: descExpanded.value ? null : 5,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: contentWidth);
      visibleH += 12 * scale + dp.size.height;
    }

    void handleSubmit() {
      final text = textController.text.trim();
      if (text.isNotEmpty &&
          !commentsResult.isSubmitting &&
          commentsResult.canAddMore) {
        commentsResult.addComment(text, mentionedUserIds: mentionedIds.value);
        textController.clear();
        mentionedIds.value = [];
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardH = constraints.maxHeight;
        final bottomPad = (cardH - squircleBottom - authorGap - visibleH).clamp(
          0.0,
          cardH,
        );
        // Spacer = squircleBottom so topmost content clears the pinned image
        final scrollEndH = squircleBottom + 15 * scale;

        return ListView(
          controller: scrollController,
          reverse: true,
          padding: EdgeInsets.symmetric(
            horizontal: contentHPad,
          ).copyWith(bottom: bottomPad),
          children: [
            _buildVisibleBlock(
              hasDesc,
              descExpanded: descExpanded,
              onAuthorTap: () => navigateToUser(post.authorId),
              onMentionTap: navigateToMention,
              authorAvatarUrl: resolveAvatar(post.authorId),
            ),
            if (post.isLockoutPost &&
                post.lockoutParticipantIds.isNotEmpty) ...[
              SizedBox(height: 12 * scale),
              PostDetailParticipants(
                participantIds: post.lockoutParticipantIds,
                participantUsernames: post.lockoutParticipantUsernames,
                participantAvatars: post.lockoutParticipantAvatars,
                participantJoinedVia: post.lockoutParticipantJoinedVia,
                myFriendIds: myFriendIds,
                onFriendTap: (userId, username) => navigateToUser(userId),
                onFriendOfFriendTap: (userId, username, _) =>
                    navigateToUser(userId),
              ),
            ],
            SizedBox(height: inputGap),
            if (!readOnly) ...[
              if (commentsResult.canAddMore)
                PostDetailOverlayInput(
                  scale: scale,
                  textController: textController,
                  allUsers: allUsers,
                  userFilter: commentMentionFilter,
                  onMentionsChanged: (ids) => mentionedIds.value = ids,
                  onSubmit: handleSubmit,
                )
              else
                _buildLimitMessage(),
            ],
            SizedBox(height: 16 * scale),
            _buildThoughtsHeader(),
            if (comments.isNotEmpty) SizedBox(height: 16 * scale),
            ..._buildCommentItems(
              comments,
              commentsResult,
              onUserTap: navigateToUser,
              onMentionTap: navigateToMention,
              resolveAvatar: resolveAvatar,
            ),
            SizedBox(height: scrollEndH),
          ],
        );
      },
    );
  }

  Widget _buildVisibleBlock(
    bool hasDesc, {
    required ValueNotifier<bool> descExpanded,
    VoidCallback? onAuthorTap,
    void Function(String)? onMentionTap,
    String? authorAvatarUrl,
  }) {
    final descStyle = TextStyle(
      fontFamily: MainFontFamilies.quicksand,
      fontWeight: FontWeight.w400,
      fontSize: 15.0 * scale,
      color: MainColors.white,
      letterSpacing: -0.9 * scale,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onAuthorTap,
          child: _buildAuthorRow(resolvedAvatarUrl: authorAvatarUrl),
        ),
        if (hasDesc) ...[
          SizedBox(height: 12 * scale),
          GestureDetector(
            onTap: () => descExpanded.value = !descExpanded.value,
            child: RichText(
              text: parseMentions(
                post.description!,
                descStyle,
                onMentionTap: onMentionTap,
              ),
              maxLines: descExpanded.value ? null : 5,
              overflow: descExpanded.value
                  ? TextOverflow.clip
                  : TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLimitMessage() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 8 * scale,
      ),
      decoration: BoxDecoration(
        color: MainColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15 * scale),
      ),
      child: Text(
        'Comment limit reached ($kMaxCommentsPerUserPerPost/$kMaxCommentsPerUserPerPost). Delete a comment to add more.',
        style: TextStyle(
          fontFamily: MainFontFamilies.quicksand,
          fontWeight: FontWeight.w400,
          fontSize: 12.0 * scale,
          color: MainColors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildAuthorRow({String? resolvedAvatarUrl}) {
    final avatarSize = 39.0 * scale;
    final gap = 10.0 * scale;
    final fontSize = 21.5 * scale;
    final ls = -1.29 * scale;
    return Row(
      children: [
        SizedBox(
          width: avatarSize,
          height: avatarSize,
          child: ClipOval(
            child: _cachedAvatar(
              resolvedAvatarUrl ?? post.authorAvatarUrl,
              avatarSize,
              name: post.authorUsername,
            ),
          ),
        ),
        SizedBox(width: gap),
        Flexible(
          child: Text(
            post.authorUsername ?? 'Unknown',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontWeight: FontWeight.w400,
              fontSize: fontSize,
              color: MainColors.white,
              letterSpacing: ls,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThoughtsHeader() {
    final fs = 24.0 * scale;
    final ls = -1.44 * scale;
    return Text(
      'Thoughts',
      style: TextStyle(
        fontFamily: MainFontFamilies.quicksand,
        fontWeight: FontWeight.w500,
        fontSize: fs,
        color: MainColors.white,
        letterSpacing: ls,
      ),
    );
  }

  List<Widget> _buildCommentItems(
    List<PostCommentModel> comments,
    PostCommentsResult commentsResult, {
    required void Function(String userId) onUserTap,
    void Function(String username)? onMentionTap,
    required String? Function(String userId) resolveAvatar,
  }) {
    if (comments.isEmpty) return [];
    return comments
        .map(
          (c) => Padding(
            padding: EdgeInsets.only(bottom: 16 * scale),
            child: _CommentRow(
              comment: c,
              scale: scale,
              canDelete: commentsResult.isOwnComment(c),
              onDelete: () => commentsResult.deleteComment(c.id),
              onAuthorTap: () => onUserTap(c.authorId),
              onMentionTap: onMentionTap,
              resolvedAvatarUrl: resolveAvatar(c.authorId),
            ),
          ),
        )
        .toList();
  }

  List<PostCommentModel> _extractComments(PostCommentsResult result) {
    return result.comments.whenOrNull(
          data: (r) => r.fold((list) => list, (_) => <PostCommentModel>[]),
        ) ??
        [];
  }
}

/// A single comment row: avatar + username + text, with delete X for own.
class _CommentRow extends StatelessWidget {
  const _CommentRow({
    required this.comment,
    required this.scale,
    required this.canDelete,
    required this.onDelete,
    this.onAuthorTap,
    this.onMentionTap,
    this.resolvedAvatarUrl,
  });

  final PostCommentModel comment;
  final double scale;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback? onAuthorTap;
  final void Function(String username)? onMentionTap;
  final String? resolvedAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final avatarSize = 39.0 * scale;
    final gap = 10.0 * scale;
    final nfs = 21.5 * scale;
    final nls = -1.29 * scale;
    final tfs = 15.0 * scale;
    final tls = -0.9 * scale;
    final xSize = 16.0 * scale;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar — fixed width, tappable
        GestureDetector(
          onTap: onAuthorTap,
          child: SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: ClipOval(
              child: _cachedAvatar(
                resolvedAvatarUrl ?? comment.authorAvatarUrl,
                avatarSize,
                name: comment.authorUsername,
              ),
            ),
          ),
        ),
        SizedBox(width: gap),
        // Username + comment text — naturally aligned
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onAuthorTap,
                child: Text(
                  comment.authorUsername,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontWeight: FontWeight.w500,
                    fontSize: nfs,
                    color: MainColors.white,
                    letterSpacing: nls,
                  ),
                ),
              ),
              SizedBox(height: 4 * scale),
              RichText(
                text: parseMentions(
                  comment.content,
                  TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontWeight: FontWeight.w400,
                    fontSize: tfs,
                    color: MainColors.white,
                    letterSpacing: tls,
                  ),
                  onMentionTap: onMentionTap,
                ),
              ),
            ],
          ),
        ),
        if (canDelete)
          Padding(
            padding: EdgeInsets.only(
              left: 8 * scale,
              top: (avatarSize - xSize) / 2,
            ),
            child: GestureDetector(
              onTap: onDelete,
              child: Icon(
                Icons.close,
                size: xSize,
                color: MainColors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
      ],
    );
  }
}
