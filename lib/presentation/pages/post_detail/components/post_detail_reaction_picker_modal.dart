import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class PostDetailReactionPickerModal extends HookConsumerWidget
    with MainLayout, PostDetailLayout {
  const PostDetailReactionPickerModal({
    required this.onReactionSelected,
    this.initialSelectedEmoji,
    super.key,
  });

  final void Function(String? emoji) onReactionSelected;
  final String? initialSelectedEmoji;

  static const List<String> availableEmojis = [
    '😀',
    '😜',
    '😎',
    '🤔',
    '🤬',
    '🥴',
    '🔥',
    '😂',
    '😍',
    '😮',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final selectedEmojiNotifier = useMemoized(
      () => ValueNotifier<String?>(initialSelectedEmoji),
      [initialSelectedEmoji],
    );

    final selectedEmoji = useValueListenable(selectedEmojiNotifier);

    useEffect(() {
      return null;
    }, [initialSelectedEmoji]);

    void handleEmojiTap(String emoji) {
      if (selectedEmojiNotifier.value == emoji) {
        selectedEmojiNotifier.value = null;
      } else {
        selectedEmojiNotifier.value = emoji;
      }

      onReactionSelected(selectedEmojiNotifier.value);
    }

    return AppGlassContainer(
      config: GlassConfig(
        variant: GlassVariant.regular,
        cornerRadius: reactionPickerBorderRadius,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: reactionPickerVerticalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: reactionPickerHandleWidth,
              height: reactionPickerHandleHeight,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(reactionPickerHandleRadius),
              ),
            ),
            SizedBox(height: reactionPickerHandleToEmojis),

            Wrap(
              spacing: reactionPickerEmojiSpacing,
              runSpacing: reactionPickerEmojiSpacing,
              alignment: WrapAlignment.center,
              children: PostDetailReactionPickerModal.availableEmojis.map((
                emoji,
              ) {
                final isSelected = selectedEmoji == emoji;

                return GestureDetector(
                  onTap: () => handleEmojiTap(emoji),
                  child: Container(
                    padding: EdgeInsets.all(reactionPickerEmojiPadding),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.surfaceContainer
                          : colorScheme.primary,
                      borderRadius: BorderRadius.circular(
                        reactionPickerEmojiRadius,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.secondary.withValues(alpha: 0.25),
                          blurRadius: 2,
                          spreadRadius: 0,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      emoji,
                      style: TextStyle(fontSize: reactionPickerEmojiFontSize),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: reactionPickerBottomSpacing),
          ],
        ),
      ),
    );
  }
}
