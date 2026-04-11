import 'package:cloudless/core/features/lockout/data/storables/dnd_prompt_dismissed_storable.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class DndPromptDialog extends HookWidget {
  const DndPromptDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    try {
      final dismissed = await DndPromptDismissedStorable().get(
        defaultValue: false,
      );
      if (dismissed || !context.mounted) return;
    } catch (_) {
      if (!context.mounted) return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const DndPromptDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final dontRemind = useState(false);

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              translator.translate(
                'pages.manual_lockout.dialog.dnd_prompt.title',
              ),
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              translator.translate(
                'pages.manual_lockout.dialog.dnd_prompt.body',
              ),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => dontRemind.value = !dontRemind.value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: dontRemind.value,
                      onChanged: (v) => dontRemind.value = v ?? false,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    translator.translate(
                      'pages.manual_lockout.dialog.dnd_prompt.dismiss',
                    ),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (dontRemind.value) {
                    await DndPromptDismissedStorable().set(true);
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: Text(
                  translator.translate(
                    'pages.manual_lockout.dialog.dnd_prompt.confirm',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
