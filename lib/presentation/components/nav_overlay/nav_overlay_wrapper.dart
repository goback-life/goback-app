import 'dart:async';

import 'package:cloudless/core/features/auth/domain/providers/is_authenticated_provider.dart';
import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/core/features/onboarding/data/storables/tutorial_completed_storable.dart';
import 'package:cloudless/core/features/profile/data/storables/profile_completed_storable.dart';
import 'dart:ui' as ui;

import 'package:cloudless/presentation/components/nav_overlay/nav_overlay.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps the entire app to detect long-press anywhere and show [NavOverlay].
///
/// Uses [GestureDetector] with [HitTestBehavior.translucent] so the overlay
/// long-press participates in the gesture arena. Child widgets with their own
/// long-press handlers (e.g. emoji name reveal) will win the arena and take
/// precedence. When the overlay long-press wins, it claims the arena so no
/// residual tap/click reaches the content underneath.
///
/// Disabled when the user is in a lockout, time-limit-reached, or signup state.
class NavOverlayWrapper extends HookConsumerWidget {
  const NavOverlayWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOverlayVisible = useState(false);

    // Check if the user has completed signup (auth + profile).
    // NavOverlayWrapper sits above the Navigator (in MaterialApp.builder)
    // so it does NOT rebuild on route changes. Poll the storable after auth
    // until confirmed, then stop.
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final profileCompleted = useState(false);
    useEffect(() {
      if (!isAuthenticated) {
        profileCompleted.value = false;
        return null;
      }
      void check() {
        ProfileCompletedStorable().get(defaultValue: false).then((v) {
          if (v && !profileCompleted.value) profileCompleted.value = true;
        });
      }

      check();
      final timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!profileCompleted.value) check();
      });
      return timer.cancel;
    }, [isAuthenticated]);
    final hasCompletedSignup = isAuthenticated && profileCompleted.value;

    // Check tutorial completion — block overlay during tutorial.
    final tutorialCompleted = useState(true);
    useEffect(() {
      if (!isAuthenticated) return null;
      void check() {
        TutorialCompletedStorable().get(defaultValue: true).then((v) {
          if (v != tutorialCompleted.value) tutorialCompleted.value = v;
        });
      }

      check();
      final timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!tutorialCompleted.value) check();
      });
      return timer.cancel;
    }, [isAuthenticated]);

    // Check lockout state to disable overlay.
    final lockoutAsync = ref.watch(manualLockoutNotifierProvider);
    final lockoutState = lockoutAsync.valueOrNull;
    final isBlocked =
        !hasCompletedSignup ||
        lockoutState?.isLockedOut == true ||
        lockoutState?.isCompletionPending == true ||
        !tutorialCompleted.value;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: isBlocked || isOverlayVisible.value
          ? null
          : (_) {
              HapticFeedback.heavyImpact();
              isOverlayVisible.value = true;
            },
      child: Stack(
        children: [
          if (isOverlayVisible.value)
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: child,
            )
          else
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
