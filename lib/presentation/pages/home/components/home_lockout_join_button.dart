import 'package:cloudless/core/features/lockout/data/providers/lockout_session_service_provider.dart';
import 'package:cloudless/presentation/pages/home/components/dnd_prompt_dialog.dart';
import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_join_lockout_post.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/presentation/components/alerts/main_snackbar.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/pages/manual_lockout/manual_lockout_routable.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
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

    // Don't show button if not a lockout post or if user is already locked out
    // Uses database flag for security - only posts created through official lockout flow
    if (!post.isLockoutPost) {
      return const SizedBox.shrink();
    }

    final isEnabled = !isAlreadyLockedOut;

    return GestureDetector(
      onTap: isEnabled
          ? () => _handleJoinLockout(context, ref)
          : null,
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: SizedBox(
          width: 40.0,
          height: postHeight,
          child: AppGlassContainer(
            config: GlassConfig(
              variant: GlassVariant.regular,
              cornerRadius: feedPostImageRadius,
              tint: isEnabled ? MainColors.accent : null,
              opacity: isEnabled ? 1.0 : 0.5,
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
        ),
      ),
    );
  }

  Future<void> _handleJoinLockout(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final lockoutNotifier = ref.read(manualLockoutNotifierProvider.notifier);
    final lockoutSessionId = post.lockoutId;

    if (lockoutSessionId == null) {
      logger.warning('Lockout post has no lockoutId');
      return;
    }

    try {
      // Get session details to calculate remaining duration
      final sessionService = ref.read(lockoutSessionServiceProvider);
      final sessionResult = await sessionService.getSessionById(lockoutSessionId);

      Duration? remainingDuration;
      await sessionResult.asyncFold(
        (session) async {
          if (session != null) {
            final endsAt = DateTime.parse(session.endsAt);
            final now = DateTime.now();
            remainingDuration = endsAt.difference(now);

            // Check if session is still active
            if (remainingDuration!.isNegative) {
              throw Exception('expired');
            }
          }
        },
        (error) async {
          throw error;
        },
      );

      await DndPromptDialog.showIfNeeded(context);
      if (!context.mounted) return;

      // Join the lockout using session ID
      await lockoutNotifier.joinLockout(lockoutSessionId);

      // Get post author information (the lockout creator)
      final otherUserId = post.authorId;
      final otherUserUsername = post.authorUsername ?? '';

      // Create a post on the joiner's account
      if (otherUserUsername.isNotEmpty && remainingDuration != null) {
        final postResult = await useJoinLockoutPost(
          ref,
          remainingDuration!,
          otherUserId,
          otherUserUsername,
        );

        postResult?.fold(
          (post) {
            logger.info('Join lockout post created successfully: ${post.id}');
          },
          (error) {
            logger.error(
              'Failed to create join lockout post',
              exception: error,
            );
            // Don't fail the entire join operation if post creation fails
          },
        );
      }

      if (context.mounted) {
        router.go(const ManualLockoutRoutable());
      }
    } catch (e) {
      if (!context.mounted) return;

      final errorMessage = e.toString().contains('expired')
          ? translator.translate('pages.home.lockout_join_error_expired')
          : translator.translate('pages.home.lockout_join_error_already_locked');

      MainSnackbar.showError(context, errorMessage);
    }
  }
}
