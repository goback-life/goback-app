import 'package:cloudless/core/features/post/domain/providers/post_creation_notifier_provider.dart';
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/pages/content_editor/content_editor_layout.dart';
import 'package:cloudless/presentation/pages/publish_content/publish_content_routable.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ContentEditorButton extends HookConsumerWidget
    with MainLayout, ContentEditorLayout {
  const ContentEditorButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final postCreationState = ref.watch(postCreationNotifierProvider);
    final isReplyMode = postCreationState.parentId != null;
    final buttonText = isReplyMode
        ? 'Create Reply'
        : translator.translate('pages.content_editor.button');

    return CallToAction.primary.filled(
      horizontalMargin: 0,
      action: () {
        router.push(const PublishContentRoutable());
      },
      label: Text(
        buttonText,
        style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
      ),
    );
  }
}
