import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/is_user_connected_provider.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/presentation/components/squircle_clipper.dart';
import 'package:cloudless/presentation/pages/circle_profile/circle_profile_routable.dart';
import 'package:cloudless/presentation/pages/external_profile/external_profile_routable.dart';
import 'package:cloudless/presentation/pages/feed/feed_layout.dart';
import 'package:cloudless/presentation/pages/profile/profile_routable.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class FeedPostCard extends HookConsumerWidget {
  const FeedPostCard({
    required this.post,
    required this.isCurrentUser,
    this.onTap,
    super.key,
  });

  final FeedPostModel post;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final s = screenWidth / 402.0;

    final squircleSize = FeedLayout.squircleSize * s;
    final avatarSize = FeedLayout.avatarSize * s;
    final avatarInset = FeedLayout.avatarInsetFromSquircle * s;
    final avatarToName = FeedLayout.avatarToNameGap * s;
    final squircleToAuthor = FeedLayout.squircleToAuthorGap * s;
    final fontSize = FeedLayout.usernameFontSize * s;
    final letterSpacing = FeedLayout.usernameLetterSpacing * s;
    final nameMaxW = FeedLayout.nameMaxWidth(screenWidth);

    final leftInset = FeedLayout.leftPostInset * s;
    final rightInset = FeedLayout.rightPostInsetFromRight * s;

    final displayImageUrl = post.imageUrl ?? '';
    final displayName = post.authorUsername ?? 'Unknown';

    return Padding(
      padding: EdgeInsets.only(
        left: isCurrentUser ? 0 : leftInset,
        right: isCurrentUser ? rightInset : 0,
      ),
      child: Align(
        alignment:
            isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: SizedBox(
          width: squircleSize,
          child: Column(
            crossAxisAlignment: isCurrentUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Squircle image
              GestureDetector(
                onTap: onTap,
                child: SizedBox(
                  width: squircleSize,
                  height: squircleSize,
                  child: ClipSquircle(
                    child: displayImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: displayImageUrl,
                            fit: BoxFit.cover,
                            width: squircleSize,
                            height: squircleSize,
                            memCacheWidth: (squircleSize * 2).toInt(),
                            memCacheHeight: (squircleSize * 2).toInt(),
                            fadeInDuration: const Duration(milliseconds: 200),
                            fadeOutDuration: const Duration(milliseconds: 100),
                            placeholder: (_, __) => Container(
                              color: MainColors.grey400,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: MainColors.grey400,
                            ),
                          )
                        : Container(color: MainColors.grey400),
                  ),
                ),
              ),

              SizedBox(height: squircleToAuthor),

              // Author row: avatar + name
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _navigateToUserProfile(ref),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 6 * s,
                    horizontal: avatarInset,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Circular avatar
                      SizedBox(
                        width: avatarSize,
                        height: avatarSize,
                        child: ClipOval(
                          child: (post.authorAvatarUrl != null &&
                                  post.authorAvatarUrl!.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: post.authorAvatarUrl!,
                                  fit: BoxFit.cover,
                                  width: avatarSize,
                                  height: avatarSize,
                                  memCacheWidth: (avatarSize * 2).toInt(),
                                  memCacheHeight: (avatarSize * 2).toInt(),
                                  placeholder: (_, __) =>
                                      Container(color: MainColors.grey400),
                                  errorWidget: (_, __, ___) =>
                                      Container(color: MainColors.grey400),
                                )
                              : Container(color: MainColors.grey400),
                        ),
                      ),
                      SizedBox(width: avatarToName),
                      // Display name
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: nameMaxW),
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: MainFontFamilies.quicksand,
                            fontWeight: FontWeight.w500,
                            fontSize: fontSize,
                            color: MainColors.white,
                            letterSpacing: letterSpacing,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToUserProfile(WidgetRef ref) async {
    final currentUserAsync = ref.read(getCurrentUserProvider);
    final isSelf = currentUserAsync.whenOrNull(
          data: (r) => r.fold((u) => u.id == post.authorId, (_) => false),
        ) ??
        false;

    if (isSelf) {
      router.push(const ProfileRoutable());
    } else {
      final result = await ref.read(
        isUserConnectedProvider(post.authorId).future,
      );
      final isConnected = result.fold((v) => v, (error) {
        logger.error('Failed to check user connection', exception: error);
        return false;
      });

      if (isConnected) {
        router.push(CircleProfileRoutable(userId: post.authorId));
      } else {
        router.push(ExternalProfileRoutable(userId: post.authorId));
      }
    }
  }
}
