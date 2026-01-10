import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/pages/manual_lockout/manual_lockout_routable.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class HomeLockoutJoinButton extends HookConsumerWidget
    with MainLayout, HomeLayout {
  const HomeLockoutJoinButton({
    required this.post,
    required this.postHeight,
    super.key,
  });

  final FeedPostModel post;
  final double postHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Check if current user is already locked out
    final lockoutStateAsync = ref.watch(manualLockoutNotifierProvider);
    final isAlreadyLockedOut = lockoutStateAsync.whenOrNull(
          data: (lockoutState) => lockoutState.isLockedOut,
        ) ??
        false;

    // Get lockout end time from post
    final lockoutEndTime = post.getLockoutEndTime();
    final now = DateTime.now();
    final remainingDuration =
        lockoutEndTime != null ? lockoutEndTime.difference(now) : null;
    final isLockoutActive =
        remainingDuration != null && remainingDuration > Duration.zero;
    final isEnabled = isLockoutActive && !isAlreadyLockedOut;

    // Don't show button if not a lockout post or if lockout expired
    // Uses database flag for security - only posts created through official lockout flow
    if (!post.isLockoutPost || !isLockoutActive) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: isEnabled
          ? () => _handleJoinLockout(context, ref, lockoutEndTime!)
          : null,
      child: Container(
        width: 40.0,
        height: postHeight,
        margin: const EdgeInsets.only(left: 8.0),
        decoration: BoxDecoration(
          color: isEnabled
              ? colorScheme.primaryContainer
              : colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(feedPostImageRadius),
        ),
        child: Center(
          child: RotatedBox(
            quarterTurns: 1,
            child: Text(
              translator.translate('pages.home.lockout_join_button'),
              style: textTheme.bodyMedium?.copyWith(
                color: isEnabled
                    ? Colors.white
                    : colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleJoinLockout(
    BuildContext context,
    WidgetRef ref,
    DateTime lockoutEndTime,
  ) async {
    final lockoutNotifier = ref.read(manualLockoutNotifierProvider.notifier);

    try {
      await lockoutNotifier.joinLockout(lockoutEndTime);

      if (context.mounted) {
        router.go(const ManualLockoutRoutable());
      }
    } catch (e) {
      if (!context.mounted) return;

      final errorMessage = e.toString().contains('expired')
          ? translator.translate('pages.home.lockout_join_error_expired')
          : translator.translate('pages.home.lockout_join_error_already_locked');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
