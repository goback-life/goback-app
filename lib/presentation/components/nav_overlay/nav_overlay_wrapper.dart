import 'dart:async';

import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/core/features/time_limit/domain/providers/time_limit_tracker_notifier_provider.dart';
import 'package:cloudless/presentation/components/nav_overlay/nav_overlay.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// Wraps the entire app to detect long-press anywhere and show [NavOverlay].
///
/// Uses [Listener] for raw pointer events to avoid gesture arena conflicts
/// with child widgets (scrollable lists, buttons, etc.).
///
/// Disabled when the user is in a lockout or time-limit-reached state.
class NavOverlayWrapper extends HookConsumerWidget {
  const NavOverlayWrapper({super.key, required this.child});

  final Widget child;

  /// Duration the user must hold before the overlay triggers.
  static const _holdDuration = Duration(milliseconds: 500);

  /// Max pointer movement (in logical pixels) before the hold is cancelled.
  static const _moveThreshold = 18.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOverlayVisible = useState(false);
    final timerRef = useRef<Timer?>(null);
    final startPositionRef = useRef<Offset?>(null);

    // Check lockout / time-limit state to disable overlay.
    final lockoutAsync = ref.watch(manualLockoutNotifierProvider);
    final timeLimitAsync = ref.watch(timeLimitTrackerNotifierProvider);
    final isBlocked = lockoutAsync.valueOrNull?.isLockedOut == true ||
        timeLimitAsync.valueOrNull?.isLimitReached == true;

    void cancelTimer() {
      timerRef.value?.cancel();
      timerRef.value = null;
      startPositionRef.value = null;
    }

    void showOverlay() {
      if (!isBlocked && !isOverlayVisible.value) {
        isOverlayVisible.value = true;
      }
    }

    void onPointerDown(PointerDownEvent event) {
      if (isBlocked || isOverlayVisible.value) return;
      startPositionRef.value = event.position;
      timerRef.value = Timer(_holdDuration, showOverlay);
    }

    void onPointerMove(PointerMoveEvent event) {
      final start = startPositionRef.value;
      if (start == null) return;
      if ((event.position - start).distance > _moveThreshold) {
        cancelTimer();
      }
    }

    void onPointerUp(PointerUpEvent event) => cancelTimer();

    // Clean up timer on dispose.
    useEffect(() => cancelTimer, const []);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      onPointerCancel: (_) => cancelTimer(),
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
