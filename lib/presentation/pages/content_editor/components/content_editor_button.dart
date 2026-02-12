import 'package:cloudless/core/features/lockout/domain/providers/pending_lockout_post_provider.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_post_creation.dart';
import 'package:cloudless/presentation/components/alerts/main_snackbar.dart';
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/pages/content_editor/content_editor_layout.dart';
import 'package:cloudless/presentation/pages/home/home_routable.dart';
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

    final pendingLockoutId = ref.watch(pendingLockoutPostProvider);
    final isLockoutMode = pendingLockoutId != null;

    final buttonText = isLockoutMode
        ? 'Post'
        : translator.translate('pages.content_editor.button');

    // Hooks must be called unconditionally
    final contentCreation = usePostCreation(ref);
    final isPublishing = useState(false);

    return CallToAction.primary.filled(
      horizontalMargin: 0,
      action: isPublishing.value
          ? null
          : () async {
              if (!isLockoutMode) {
                router.push(const PublishContentRoutable());
                return;
              }

              // Lockout mode: publish directly to full circle
              isPublishing.value = true;
              try {
                final result =
                    await contentCreation.publishPostWithExclusions([]);
                if (result != null) {
                  result.fold(
                    (_) {
                      if (context.mounted) {
                        router.go(const HomeRoutable());
                      }
                    },
                    (error) {
                      if (context.mounted) {
                        MainSnackbar.showError(
                          context,
                          'Failed to post. Please try again.',
                        );
                      }
                    },
                  );
                }
              } finally {
                isPublishing.value = false;
              }
            },
      label: isPublishing.value
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            )
          : Text(
              buttonText,
              style:
                  textTheme.titleLarge?.copyWith(color: colorScheme.primary),
            ),
    );
  }
}
