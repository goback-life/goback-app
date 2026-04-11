import 'package:cloudless/core/features/post/domain/hooks/use_mention_autocomplete.dart';
import 'package:cloudless/presentation/components/mention_text_field/mention_text_field.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class PostDetailCommentInput extends HookConsumerWidget
    with MainLayout, PostDetailLayout {
  const PostDetailCommentInput({
    required this.onSubmit,
    required this.isSubmitting,
    super.key,
  });

  final Future<void> Function(String content, {List<String>? mentionedUserIds})
  onSubmit;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final controller = useTextEditingController();
    final isEmpty = useState(true);
    final mentionState = useMentionAutocomplete(ref);
    final collectedMentions = useState<List<String>>([]);

    useEffect(() {
      void listener() {
        isEmpty.value = controller.text.trim().isEmpty;
      }

      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);

    Future<void> handleSubmit() async {
      final text = controller.text.trim();
      if (text.isEmpty || isSubmitting) return;

      // Parse mentions from the text and combine with manually selected mentions
      final parsedMentions = mentionState.parseMentions(text);
      final allMentions = <String>{
        ...collectedMentions.value,
        ...parsedMentions,
      }.toList();

      await onSubmit(
        text,
        mentionedUserIds: allMentions.isNotEmpty ? allMentions : null,
      );
      controller.clear();
      collectedMentions.value = [];
    }

    return Container(
      padding: EdgeInsets.all(commentsListInputPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: commentInputMaxHeight),
                child: MentionTextField(
                  controller: controller,
                  allUsers: mentionState.allUsers,
                  onMentionsChanged: (mentions) {
                    collectedMentions.value = mentions;
                  },
                  maxLines: null,
                  maxLength: commentMaxLength.toInt(),
                  textInputAction: TextInputAction.newline,
                  hintText: 'Add a comment...',
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(reactionBorderRadius),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.primaryContainer.withValues(
                      alpha: 0.1,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    counterText: '',
                  ),
                  style: textTheme.bodyMedium,
                ),
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: isEmpty.value || isSubmitting ? null : handleSubmit,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEmpty.value || isSubmitting
                      ? colorScheme.primaryContainer.withValues(alpha: 0.1)
                      : colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.send,
                        size: 20,
                        color: isEmpty.value
                            ? colorScheme.onSurface.withValues(alpha: 0.3)
                            : colorScheme.onPrimary,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
