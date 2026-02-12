import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_manual_lockout_post.dart';
import 'package:cloudless/presentation/pages/home/components/manual_lockout_dialog.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/pages/manual_lockout/manual_lockout_routable.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class HomeGoBackButton extends HookConsumerWidget
    with MainLayout, HomeLayout {
  const HomeGoBackButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: () async {
        // Show time selection dialog
        final duration = await ManualLockoutDialog.show(context);
        if (duration == null || !context.mounted) {
          return;
        }

        try {
          // Create post with app logo
          final postResult = await useManualLockoutPost(ref, duration);
          postResult?.fold(
            (post) {
              logger.info('Manual lockout post created successfully');
            },
            (error) {
              logger.error(
                'Failed to create manual lockout post',
                exception: error,
              );
            },
          );

          // Set lockout
          final lockoutNotifier = ref.read(manualLockoutNotifierProvider.notifier);
          await lockoutNotifier.setLockout(duration);

          // Navigate to lockout screen
          if (context.mounted) {
            router.go(const ManualLockoutRoutable());
          }
        } catch (e, stackTrace) {
          logger.error(
            'Error setting manual lockout',
            exception: e,
            stackTrace: stackTrace,
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          translator.translate('pages.home.go_back_button'),
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

