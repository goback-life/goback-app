import 'package:cloudless/core/features/lockout/domain/providers/friends_locked_out_cache_provider.dart';
import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/pages/home/components/manual_lockout_dialog.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/pages/manual_lockout/manual_lockout_routable.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class HomeLockoutButton extends HookConsumerWidget
    with MainLayout, HomeLayout {
  const HomeLockoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () async {
        // Pre-fetch friends locked out while user selects duration
        // This ensures data is cached by the time lockout screen loads
        ref.read(friendsLockedOutCacheProvider.notifier).ensureFresh();

        // Show time selection dialog
        final result = await ManualLockoutDialog.show(context);
        if (result == null || !context.mounted) {
          return;
        }

        try {
          // Set lockout (post will be created after lockout ends)
          final lockoutNotifier = ref.read(manualLockoutNotifierProvider.notifier);
          await lockoutNotifier.setLockout(
            result.duration,
            actionText: result.actionText,
          );

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
        padding: EdgeInsets.all(feedPostImageBorderRadius),
        width: createContentButtonSize,
        height: createContentButtonSize,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
        ),
        child: Assets.svg.back.render(
          colorFilter: colorScheme.primaryContainer.asSrcIn,
        ),
      ),
    );
  }
}

