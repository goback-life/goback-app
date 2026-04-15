import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/utilities/date_formatter.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class PostDetailHeader extends HookConsumerWidget
    with MainLayout, PostDetailLayout {
  const PostDetailHeader({
    required this.post,
    required this.onUserTap,
    super.key,
  });

  final FeedPostModel post;
  final VoidCallback onUserTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final locale = translator.currentLocale.toString();

    return Row(
      children: [
        GestureDetector(
          onTap: onUserTap,
          child: Row(
            children: [
              ProfileImage(
                imageUrl: post.authorAvatarUrl,
                username: post.authorUsername,
                size: headerAvatarSize,
                showFromProfile: false,
                isEditable: false,
              ),
              SizedBox(width: headerImageToUser),
              Text(
                post.authorUsername ?? 'Unknown User',
                style: textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          DateFormatter.formatTimeWithDateIfNeeded(
            post.localPublishedAt(ref),
            locale,
            convertToLocal: false,
          ),
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.outlineVariant,
          ),
        ),
        SizedBox(width: headerTimeToClose),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => router.pop(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: SizedBox(
                width: headerIconSize,
                height: headerIconSize,
                child: Assets.svg.close.render(
                  colorFilter: colorScheme.onSurface.asSrcIn,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
