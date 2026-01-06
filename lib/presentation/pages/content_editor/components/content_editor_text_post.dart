import 'package:cloudless/core/features/post/domain/constants/text_post_constants.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class ContentEditorTextPost extends HookWidget {
  const ContentEditorTextPost({
    required this.initialText,
    required this.onChanged,
    super.key,
  });

  final String initialText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final controller = useTextEditingController(text: initialText);
    final currentChars = useState(initialText.length);

    useEffect(() {
      void listener() {
        final newLength = controller.text.length;
        currentChars.value = newLength;
        onChanged(controller.text);
      }

      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);

    final isOverLimit = currentChars.value > TextPostConstants.maxTextPostLength;
    final remainingChars = TextPostConstants.maxTextPostLength - currentChars.value;

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
                maxLines: null,
                minLines: 5,
                maxLength: null, // We handle limit manually
                style: textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: translator.translate(
                    'pages.content_editor.text_post.placeholder',
                  ),
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.shadow,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  counterText: '',
                ),
                onChanged: (value) {
                  // Enforce character limit
                  if (value.length > TextPostConstants.maxTextPostLength) {
                    controller.value = TextEditingValue(
                      text: value.substring(0, TextPostConstants.maxTextPostLength),
                      selection: TextSelection.collapsed(
                        offset: TextPostConstants.maxTextPostLength,
                      ),
                    );
                  }
                },
              ),
              Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  isOverLimit
                      ? translator.translate(
                          'pages.content_editor.text_post.characters_over_limit',
                          arguments: {
                            'count': (currentChars.value -
                                    TextPostConstants.maxTextPostLength)
                                .toString(),
                          },
                        )
                      : translator.translate(
                          'pages.content_editor.text_post.characters_remaining',
                          arguments: {
                            'count': remainingChars.toString(),
                          },
                        ),
                  style: textTheme.labelMedium?.copyWith(
                    color: isOverLimit
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
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

