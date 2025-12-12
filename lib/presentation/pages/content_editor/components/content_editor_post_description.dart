import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class ContentEditorPostDescription extends HookWidget {
  const ContentEditorPostDescription({
    required this.initialText,
    required this.onChanged,
    super.key,
    this.maxLength = 500,
  });

  final String initialText;
  final ValueChanged<String> onChanged;
  final int maxLength;

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
                maxLines: 5,
                maxLength: maxLength,
                style: textTheme.bodyMedium,
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
