import 'dart:async';

import 'package:cloudless/core/features/auth/domain/providers/is_authenticated_provider.dart';
import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/core/features/onboarding/data/storables/tutorial_completed_storable.dart';
import 'package:cloudless/core/features/profile/data/storables/profile_completed_storable.dart';
import 'dart:ui' as ui;

import 'package:cloudless/presentation/components/nav_overlay/nav_overlay.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps the entire app to detect a quick hold or force-press and show [NavOverlay].
///
/// Two activation paths:
/// - **Hold** (200 ms): [LongPressGestureRecognizer] with a shorter duration
///   than Flutter's default 500 ms.
/// - **Force press**: [ForcePressGestureRecognizer] for instant activation on
///   devices that report pressure data (e.g. iOS 3D Touch / Haptic Touch).
///
/// Uses [HitTestBehavior.translucent] so child widgets with their own
/// gesture handlers participate in the gesture arena and can take precedence.
///
/// Disabled when the user is in a lockout, time-limit-reached, or signup state,
/// or when a modal (like the lockout bottom sheet) sets [suppress] to true.
class NavOverlayWrapper extends HookConsumerWidget {
  const NavOverlayWrapper({super.key, required this.child});

  final Widget child;

  /// Set to `true` to temporarily suppress the nav overlay (e.g. while a
  /// modal sheet that needs drag gestures is open). Revert to `false` on
  /// dismiss.
  static final suppress = ValueNotifier<bool>(false);

  /// How long the user must hold before the overlay activates.
  static const _holdDuration = Duration(milliseconds: 200);

  /// Normalized force-press threshold (0.0–1.0). Lower = more sensitive.
  static const _forcePressure = 0.35;

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

    final isSuppressed = useValueListenable(suppress);
    final isEnabled = !isBlocked && !isOverlayVisible.value && !isSuppressed;

    void activate() {
      HapticFeedback.heavyImpact();
      isOverlayVisible.value = true;
    }

    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: isEnabled
          ? <Type, GestureRecognizerFactory>{
              LongPressGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    LongPressGestureRecognizer
                  >(() => LongPressGestureRecognizer(duration: _holdDuration), (
                    instance,
                  ) {
                    instance.onLongPressStart = (_) => activate();
                  }),
              ForcePressGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    ForcePressGestureRecognizer
                  >(
                    () => ForcePressGestureRecognizer(
                      startPressure: _forcePressure,
                    ),
                    (instance) {
                      instance.onStart = (_) => activate();
                    },
                  ),
            }
          : <Type, GestureRecognizerFactory>{},
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
