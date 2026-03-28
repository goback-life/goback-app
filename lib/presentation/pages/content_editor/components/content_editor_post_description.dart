import 'package:cloudless/core/models/profile_model.dart';
import 'package:cloudless/presentation/components/main_member/main_member_item.dart';
import 'package:cloudless/presentation/pages/content_editor/components/mention_helpers.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class ContentEditorPostDescription extends HookWidget {
  const ContentEditorPostDescription({
    required this.initialText,
    required this.onChanged,
    required this.allUsers,
    super.key,
    this.maxLength = 200,
  });

  final String initialText;
  final ValueChanged<String> onChanged;
  final List<ProfileModel> allUsers;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final controller = useTextEditingController(text: initialText);
    final currentChars = useState(initialText.length);
    final focusNode = useFocusNode();
    final mentionQuery = useState<String?>(null);
    final mentionStartIndex = useState<int?>(null);

    final filteredUsers = useMemoized(
      () => filterMentionUsers(mentionQuery.value, allUsers),
      [mentionQuery.value, allUsers],
    );

    void onMentionSelected(ProfileModel user) {
      if (mentionStartIndex.value == null) return;
      final newText = insertMention(
        controller: controller,
        user: user,
        mentionStartIndex: mentionStartIndex.value!,
      );
      mentionQuery.value = null;
      mentionStartIndex.value = null;
      onChanged(newText);
    }

    useEffect(() {
      void listener() {
        currentChars.value = controller.text.length;
        onChanged(controller.text);
      }

      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Column(
            children: [
              TextField(
                textCapitalization: TextCapitalization.sentences,
                cursorColor: colorScheme.tertiary,
                onTapOutside: (event) => context.unfocus(),
                controller: controller,
                focusNode: focusNode,
                maxLines: 5,
                maxLength: maxLength,
                style: textTheme.bodyMedium,
                onChanged: (value) {
                  if (focusNode.hasFocus) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (focusNode.hasFocus) {
                        final result = detectMention(
                          controller.text,
                          controller.selection.baseOffset,
                        );
                        mentionQuery.value = result.query;
                        mentionStartIndex.value = result.startIndex;
                      }
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: translator.translate(
                    'pages.content_editor.hint_text',
                  ),
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.shadow,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
              // User mention suggestions dropdown
              if (mentionQuery.value != null && filteredUsers.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: MainColors.dark.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return MainMemberItem(
                        member: user,
                        action: MemberItemAction.none,
                        onTap: () => onMentionSelected(user),
                      );
                    },
                  ),
                ),
              if (currentChars.value >= (maxLength * 0.75).round())
                Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    translator.translate(
                      'pages.content_editor.character_count',
                      arguments: {
                        'current': currentChars.value.toString(),
                        'max': maxLength.toString(),
                      },
                    ),
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
