import 'dart:math' as math;

import 'package:cloudless/core/features/lockout/domain/providers/friends_locked_out_cache_provider.dart';
import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/core/features/time_limit/domain/providers/time_limit_tracker_notifier_provider.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/home/components/manual_lockout_dialog.dart';
import 'package:cloudless/presentation/pages/manual_lockout/manual_lockout_routable.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Glass lockout button with rotated triangle SVG.
///
/// Positioned by the parent [FeedView] at bottom-center with a slight
/// left offset. Tapping shows [ManualLockoutDialog] then navigates.
class FeedLockoutButton extends HookConsumerWidget {
  const FeedLockoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final s = screenWidth / 402.0;

    // Hide when daily limit reached
    final timeLimitAsync = ref.watch(timeLimitTrackerNotifierProvider);
    final isDailyLimitReached = timeLimitAsync.whenOrNull(
          data: (tl) => tl.isLimitReached,
        ) ??
        false;

    if (isDailyLimitReached) return const SizedBox.shrink();

    // Button dimensions: proportional to squircle size
    final buttonSize = 60 * s;

    return GestureDetector(
      onTap: () => _onTap(context, ref),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF191919).withValues(alpha: 0.25),
              offset: Offset(0, 4 * s),
              blurRadius: 4 * s,
            ),
          ],
        ),
        child: AppGlassContainer(
          config: const GlassConfig(
            variant: GlassVariant.regular,
            tint: MainColors.accent,
            interactive: true,
            cornerRadius: 24,
          ),
          child: SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: Center(
              child: Transform.rotate(
                angle: -math.pi / 2, // -90 degrees to point left
                child: SvgPicture.asset(
                  'assets/images/svgs/lockout_arrow.svg',
                  width: 32 * s,
                  height: 27 * s,
                  colorFilter: MainColors.white.asSrcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    ref.read(friendsLockedOutCacheProvider.notifier).ensureFresh();

    final duration = await ManualLockoutDialog.show(context);
    if (duration == null || !context.mounted) return;

    try {
      final notifier = ref.read(manualLockoutNotifierProvider.notifier);
      await notifier.setLockout(duration);
      ref.invalidate(timeLimitTrackerNotifierProvider);
      if (context.mounted) {
        router.go(const ManualLockoutRoutable());
      }
    } catch (e, st) {
      logger.error('Error setting manual lockout', exception: e, stackTrace: st);
    }
  }
}
