import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class ProfileWeeklyStats extends HookConsumerWidget {
  const ProfileWeeklyStats({
    super.key,
    this.weeklyLockoutMinutes,
    this.hasResolvedData = false,
  });

  /// Pre-resolved lockout minutes (avoids redundant provider watches).
  final int? weeklyLockoutMinutes;

  /// When true, uses [weeklyLockoutMinutes] directly instead of watching
  /// providers. This allows the parent to resolve profile data once.
  final bool hasResolvedData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (hasResolvedData) {
      return _buildDisplay(
        context,
        weeklyLockoutMinutes,
        textTheme,
        colorScheme,
      );
    }

    final currentUserAsync = ref.watch(getCurrentUserProvider);

    return currentUserAsync.when(
      data: (userResult) => userResult.fold(
        (user) =>
            _buildWithProfile(context, ref, user.id, textTheme, colorScheme),
        (_) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox(height: 18),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildWithProfile(
    BuildContext context,
    WidgetRef ref,
    String userId,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final profileAsync = ref.watch(getProfileProvider(userId));

    return profileAsync.when(
      data: (profileResult) => profileResult.fold(
        (profile) => _buildDisplay(
          context,
          profile?.weeklyLockoutMinutes,
          textTheme,
          colorScheme,
        ),
        (_) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox(height: 18),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildDisplay(
    BuildContext context,
    int? weeklyLockoutMinutes,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final String displayText;
    if (weeklyLockoutMinutes == null || weeklyLockoutMinutes == 0) {
      displayText = translator.translate(
        'pages.profile.weekly_stats.no_lockouts',
      );
    } else {
      final hours = (weeklyLockoutMinutes / 60).toStringAsFixed(2);
      displayText = translator.translate(
        'pages.profile.weekly_stats.hours_format',
        context: context,
        arguments: {'hours': hours},
      );
    }

    return Text(
      displayText,
      textAlign: TextAlign.center,
      style: textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }
}
