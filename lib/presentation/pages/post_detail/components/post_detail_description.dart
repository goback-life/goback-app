import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:cloudless/presentation/utilities/mention_text_parser.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class PostDetailDescription extends HookWidget
    with MainLayout, PostDetailLayout {
  const PostDetailDescription({
    required this.description,
    this.contentType,
    this.onMentionTap,
    this.taggedUsernames,
    super.key,
  });

  final String description;
  final ContentType? contentType;
  final void Function(String username)? onMentionTap;

  /// Only @usernames in this set will be rendered as bold/clickable.
  /// If null, all @patterns are bolded (legacy behavior).
  final Set<String>? taggedUsernames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final mediaQuery = MediaQuery.of(context);
    final isLongText = useState(false);
    final showFullText = useState(false);

    useEffect(() {
      final textPainter = TextPainter(
        text: TextSpan(text: description, style: theme.textTheme.bodyMedium),
        maxLines: descriptionMaxLines.toInt(),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: mediaQuery.size.width - (horizontalPadding * 2));
      isLongText.value = textPainter.didExceedMaxLines;

      return null;
    }, [description, mediaQuery.size.width]);

    // For text posts, always show full text without expand/collapse
    if (contentType == ContentType.text) {
      final baseStyle =
          textTheme.bodyMedium?.copyWith(
            color: colorScheme.outlineVariant,
            height: 20.5 / 14.0,
          ) ??
          const TextStyle();
      return RichText(
        text: parseMentions(
          description,
          baseStyle,
          taggedUsernames: taggedUsernames,
          onMentionTap: onMentionTap,
        ),
      );
    }

    // For other post types, show expand/collapse functionality
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: isLongText.value
            ? () => showFullText.value = !showFullText.value
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (_) {
                final baseStyle =
                    textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outlineVariant,
                      height: 20.5 / 14.0,
                    ) ??
                    const TextStyle();
                return RichText(
                  text: parseMentions(
                    description,
                    baseStyle,
                    taggedUsernames: taggedUsernames,
                    onMentionTap: onMentionTap,
                  ),
                  maxLines: showFullText.value
                      ? null
                      : (isLongText.value ? descriptionMaxLines.toInt() : null),
                  overflow: showFullText.value
                      ? TextOverflow.clip
                      : TextOverflow.ellipsis,
                );
              },
            ),
            if (isLongText.value) ...[
              SizedBox(height: descriptionTruncatorSpacing),
              Center(
                child: Icon(
                  showFullText.value
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: arrowIconSize,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
