import 'dart:async';

import 'package:cloudless/core/features/lockout/data/providers/lockout_session_service_provider.dart';
import 'package:cloudless/core/features/lockout/domain/providers/pending_lockout_post_provider.dart';
import 'package:cloudless/core/features/onboarding/data/storables/tutorial_completed_storable.dart';
import 'package:cloudless/core/features/onboarding/data/storables/tutorial_phase_storable.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_post_creation_initialization.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/pages/tutorial/components/tutorial_cutout_painter.dart';
import 'package:cloudless/presentation/pages/tutorial/components/tutorial_friend_adder.dart';
import 'package:cloudless/presentation/pages/tutorial/components/tutorial_tooltip.dart';
import 'package:cloudless/presentation/pages/tutorial/tutorial_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// Lockout phase of the tutorial.
///
/// Sub-steps:
///   0 → Explanation tooltip ("A lockout locks you out of goback…")
///   1 → Friend-adding UI with 2-min countdown
///   2 → "Share your goback" tooltip with Share / Skip options
///
/// Completes when timer expires OR 4 friend requests are sent,
/// then shows the post step before finishing.
class TutorialLockoutPhase extends HookConsumerWidget {
  const TutorialLockoutPhase({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subStep = useState(
      0,
    ); // 0 = explanation, 1 = friend adding, 2 = share prompt
    final remainingSeconds = useState(120);
    final friendsAdded = useState(0);

    final postCreationInit = usePostCreationInitialization(
      ref,
      skipContentTypePicker: true,
    );

    // Start countdown only after explanation is dismissed
    useEffect(() {
      if (subStep.value != 1) return null;
      final timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (remainingSeconds.value > 0) {
          remainingSeconds.value--;
        }
      });
      return timer.cancel;
    }, [subStep.value]);

    // Transition to share prompt when exit conditions are met
    useEffect(() {
      if (subStep.value != 1) return null;
      if (remainingSeconds.value <= 0 || friendsAdded.value >= 4) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          subStep.value = 2;
        });
      }
      return null;
    }, [remainingSeconds.value, friendsAdded.value, subStep.value]);

    final surface = Theme.of(context).colorScheme.surface;
    final bgColor = surface.computeLuminance() < 0.5
        ? MainColors.white
        : MainColors.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    final minutes = remainingSeconds.value ~/ 60;
    final seconds = remainingSeconds.value % 60;
    final countdownStr = subStep.value == 2
        ? '0:00'
        : '$minutes:${seconds.toString().padLeft(2, '0')}';

    // Absorb long-press so NavOverlayWrapper doesn't trigger.
    return GestureDetector(
      onLongPress: () {},
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Sky image
          Assets.png.backgroundGoback.render(
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // Layer 2: Cutout painter (timer + triangle)
          Positioned.fill(
            child: CustomPaint(
              painter: TutorialCutoutPainter(
                bgColor: bgColor,
                countdown: countdownStr,
              ),
            ),
          ),

          // Layer 3: Content per sub-step
          if (subStep.value == 0)
            TutorialTooltip(
              message:
                  'A lockout locks you out of goback for a set time.\n\n'
                  'Use this time to be present. When the timer ends, '
                  'you can share a photo of what you did.\n\n'
                  'Now, add 4 friends to get started.',
              onTap: () => subStep.value = 1,
              bottomOffset: 180,
            )
          else if (subStep.value == 1)
            Positioned(
              top: screenHeight * TutorialLayout.friendAdderTopFraction,
              left: 0,
              right: 0,
              bottom: 0,
              child: TutorialFriendAdder(
                friendsAdded: friendsAdded.value,
                onFriendAdded: () {
                  if (friendsAdded.value < 4) {
                    friendsAdded.value++;
                  }
                },
              ),
            )
          else
            TutorialTooltip(
              message:
                  'Your lockout is over!\n\n'
                  'Now you can share a photo of what you did.',
              buttonLabel: 'Share your goback',
              onTap: () async {
                final sessionService = ref.read(lockoutSessionServiceProvider);
                final result = await sessionService.createSession(
                  duration: const Duration(minutes: 2),
                );
                result.fold((session) {
                  ref
                      .read(pendingLockoutPostProvider.notifier)
                      .setLockoutId(session.id);
                  // Mark tutorial done without navigating — widget must stay
                  // mounted so the media picker → content editor flow works.
                  TutorialCompletedStorable().set(true);
                  TutorialPhaseStorable().remove();
                  postCreationInit.selectMainImage();
                }, (_) => onComplete());
              },
              secondaryButtonLabel: 'Skip',
              onSecondaryTap: onComplete,
              bottomOffset: 180,
            ),
        ],
      ),
    );
  }
}
