import 'package:cloudless/core/features/lockout/domain/providers/get_friends_locked_out_provider.dart';
import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/presentation/components/alerts/main_snackbar.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image.dart';
import 'package:cloudless/presentation/pages/manual_lockout/manual_lockout_routable.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class FriendsLockedOutView extends HookConsumerWidget with MainLayout {
  const FriendsLockedOutView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final friendsLockedOutAsync = ref.watch(getFriendsLockedOutProvider);

    return friendsLockedOutAsync.when(
      data: (result) {
        return result.fold(
          (lockouts) {
            // ignore: avoid_print
            print('[FriendsLockedOutView] received ${lockouts.length} lockouts');
            for (final l in lockouts) {
              // ignore: avoid_print
              print('[FriendsLockedOutView]   ${l.username} (${l.id}), endsAt=${l.endsAt}');
            }
            if (lockouts.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone_locked_outlined,
                        size: 64,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        translator.translate('pages.friends_locked_out.empty'),
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return NotificationListener<OverscrollNotification>(
              onNotification: (notification) {
                // Pull-up: positive overscroll at bottom of list
                if (notification.overscroll > 10) {
                  ref.invalidate(getFriendsLockedOutProvider);
                }
                return false;
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                itemCount: lockouts.length,
                itemBuilder: (context, index) {
                  final lockout = lockouts[index];
                  final minutesRemaining = lockout.endsAt
                      .difference(DateTime.now())
                      .inMinutes;
                  final isJoinable = minutesRemaining > 30;

                  Future<void> joinLockout() async {
                    try {
                      await ref
                          .read(manualLockoutNotifierProvider.notifier)
                          .joinLockout(lockout.id);
                      if (context.mounted) {
                        router.go(const ManualLockoutRoutable());
                      }
                    } catch (e) {
                      if (context.mounted) {
                        MainSnackbar.showError(
                          context,
                          translator.translate(
                            'pages.friends_locked_out.join_error',
                          ),
                        );
                      }
                    }
                  }

                  return _FriendLockoutItem(
                    username: lockout.username ?? 'Unknown',
                    avatarUrl: lockout.avatarUrl,
                    actionText: lockout.actionText,
                    locationName: lockout.locationName,
                    minutesRemaining: minutesRemaining,
                    isJoinable: isJoinable,
                    onTap: isJoinable ? joinLockout : null,
                    onJoin: isJoinable ? joinLockout : null,
                  );
                },
              ),
            );
          },
          (error) => Center(
            child: Text(
              translator.translate('pages.friends_locked_out.error'),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(
          translator.translate('pages.friends_locked_out.error'),
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.error,
          ),
        ),
      ),
    );
  }
}

class _FriendLockoutItem extends StatelessWidget with MainLayout {
  const _FriendLockoutItem({
    required this.username,
    required this.minutesRemaining,
    required this.isJoinable,
    this.avatarUrl,
    this.actionText,
    this.locationName,
    this.onTap,
    this.onJoin,
  });

  final String username;
  final String? avatarUrl;
  final String? actionText;
  final String? locationName;
  final int minutesRemaining;
  final bool isJoinable;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: ProfileImage(
              imageUrl: avatarUrl,
              isEditable: false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (actionText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    actionText!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatTimeRemaining(minutesRemaining),
                  style: textTheme.bodySmall?.copyWith(
                    color: isJoinable
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isJoinable)
            ElevatedButton(
              onPressed: onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: MainColors.accent,
                foregroundColor: MainColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                translator.translate('pages.friends_locked_out.join'),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                translator.translate('pages.friends_locked_out.ending_soon'),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }

  String _formatTimeRemaining(int minutes) {
    if (minutes < 60) {
      return '$minutes min remaining';
    }
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    if (remainingMins == 0) {
      return '$hours ${hours == 1 ? 'hour' : 'hours'} remaining';
    }
    return '${hours}h ${remainingMins}m remaining';
  }
}
