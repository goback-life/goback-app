import 'package:cloudless/core/features/post/domain/constants/text_post_constants.dart';
import 'package:cloudless/presentation/components/text/linkable_text.dart';
import 'package:cloudless/presentation/pages/content_editor/components/markdown_link_formatter.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final focusNode = useFocusNode();

    useEffect(() {
      void listener() {
        final newLength = controller.text.length;
        currentChars.value = newLength;
        onChanged(controller.text);
      }

      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);

    // Parse markdown links to track their positions
    final markdownLinks = useMemoized(() {
      final text = controller.text;
      final markdownLinkPattern = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
      return markdownLinkPattern.allMatches(text).map((match) {
        return (
          alias: match.group(1)!,
          url: match.group(2)!,
          start: match.start,
          end: match.end,
        );
      }).toList();
    }, [controller.text]);

    final isOverLimit = currentChars.value > TextPostConstants.maxTextPostLength;
    final remainingChars = TextPostConstants.maxTextPostLength - currentChars.value;

    // Check if text has any links for showing rendered preview
    final hasLinks = useMemoized(() {
      return markdownLinks.isNotEmpty;
    }, [markdownLinks]);

    // Generate display text with markdown links rendered (show domain alias, not markdown)
    final displayText = useMemoized(() {
      final text = controller.text;
      String result = text;
      
      // Replace all [alias](url) with just the alias text (domain)
      for (final link in markdownLinks.reversed) {
        result = result.replaceRange(link.start, link.end, link.alias);
      }
      
      return result;
    }, [controller.text, markdownLinks]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            Container(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Column(
                children: [
                  Stack(
                    children: [
                      // Rendered text overlay (shown when not focused and has links)
                      // Shows markdown links as styled domain text
                      if (!focusNode.hasFocus && hasLinks)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 0),
                              child: LinkableText(
                                text: displayText,
                                style: textTheme.bodyMedium,
                                maxLines: null,
                              ),
                            ),
                          ),
                        ),
                      // Actual text field - shows markdown when editing, display text when not focused
                      TextField(
                        textCapitalization: TextCapitalization.sentences,
                        cursorColor: colorScheme.tertiary,
                        onTapOutside: (event) => context.unfocus(),
                        controller: controller,
                        focusNode: focusNode,
                        maxLines: null,
                        minLines: 5,
                        maxLength: null, // We handle limit manually
                        inputFormatters: [
                          MarkdownLinkFormatter(), // Handle markdown link deletion
                        ],
                        style: textTheme.bodyMedium?.copyWith(
                          // Make text transparent when showing rendered overlay
                          color: (!focusNode.hasFocus && hasLinks)
                              ? Colors.transparent
                              : null,
                        ),
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
                    ],
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

