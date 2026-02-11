import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/core/features/time_limit/domain/providers/time_limit_tracker_notifier_provider.dart';
import 'package:cloudless/presentation/components/nav_overlay/nav_overlay.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// Wraps the entire app to detect long-press anywhere and show [NavOverlay].
///
/// Uses [GestureDetector] with [HitTestBehavior.translucent] so the overlay
/// long-press participates in the gesture arena. Child widgets with their own
/// long-press handlers (e.g. emoji name reveal) will win the arena and take
/// precedence. When the overlay long-press wins, it claims the arena so no
/// residual tap/click reaches the content underneath.
///
/// Disabled when the user is in a lockout or time-limit-reached state.
class NavOverlayWrapper extends HookConsumerWidget {
  const NavOverlayWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOverlayVisible = useState(false);

    // Check lockout / time-limit state to disable overlay.
    final lockoutAsync = ref.watch(manualLockoutNotifierProvider);
    final timeLimitAsync = ref.watch(timeLimitTrackerNotifierProvider);
    final isBlocked = lockoutAsync.valueOrNull?.isLockedOut == true ||
        timeLimitAsync.valueOrNull?.isLimitReached == true;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: isBlocked || isOverlayVisible.value
          ? null
          : (_) => isOverlayVisible.value = true,
      child: Stack(
        children: [
          child,
          if (isOverlayVisible.value)
            Positioned.fill(
              child: NavOverlay(
                onDismiss: () => isOverlayVisible.value = false,
              ),
            ),
        ],
      ),
    );
  }
}
