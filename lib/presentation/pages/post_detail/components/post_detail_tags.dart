import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class PostDetailTags extends StatelessWidget with MainLayout, PostDetailLayout {
  const PostDetailTags({
    required this.taggedUsernames,
    required this.taggedUserIds,
    this.onUserTap,
    super.key,
  });

  final List<String> taggedUsernames;
  final List<String> taggedUserIds;
  final void Function(String userId, String username)? onUserTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (taggedUsernames.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Assets.svg.tag.render(),
        SizedBox(width: tagSpacing),
        Expanded(
          child: Wrap(
            spacing: 4.0,
            runSpacing: 4.0,
            children: List.generate(taggedUsernames.length, (index) {
              final username = taggedUsernames[index];
              final userId = index < taggedUserIds.length
                  ? taggedUserIds[index]
                  : '';
              final isLast = index == taggedUsernames.length - 1;

              return GestureDetector(
                onTap: () => onUserTap?.call(userId, username),
                child: Text(
                  '@$username${isLast ? '' : ','}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outlineVariant,
                    fontWeight: FontWeight.w500,
                    height: 20.5 / 14.0,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
