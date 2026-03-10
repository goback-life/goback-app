import 'package:cloudless/core/features/onboarding/data/storables/tutorial_completed_storable.dart';
import 'package:cloudless/core/features/onboarding/data/storables/tutorial_phase_storable.dart';
import 'package:cloudless/presentation/pages/home/home_routable.dart';
import 'package:cloudless/presentation/pages/tutorial/views/tutorial_feed_phase.dart';
import 'package:cloudless/presentation/pages/tutorial/views/tutorial_lockout_phase.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

enum TutorialPhase { feed, lockout }

/// Root view for the tutorial flow.
///
/// Reads persisted phase on mount (crash recovery), switches between
/// [TutorialFeedPhase] and [TutorialLockoutPhase], and marks completion
/// when done.
class TutorialView extends HookWidget {
  const TutorialView({super.key});

  @override
  Widget build(BuildContext context) {
    final phase = useState<TutorialPhase?>(null);

    // Restore persisted phase on mount
    useEffect(() {
      Future<void> restore() async {
        final stored = await TutorialPhaseStorable().get(defaultValue: 'feed');
        if (stored == 'lockout') {
          phase.value = TutorialPhase.lockout;
        } else {
          phase.value = TutorialPhase.feed;
        }
      }
      restore();
      return null;
    }, []);

    if (phase.value == null) return const SizedBox.shrink();

    void transitionToLockout() {
      TutorialPhaseStorable().set('lockout');
      phase.value = TutorialPhase.lockout;
    }

    Future<void> completeTutorial() async {
      await TutorialCompletedStorable().set(true);
      await TutorialPhaseStorable().remove();
      router.go(const HomeRoutable());
    }

    return switch (phase.value!) {
      TutorialPhase.feed => TutorialFeedPhase(
          onStartLockout: transitionToLockout,
        ),
      TutorialPhase.lockout => TutorialLockoutPhase(
          onComplete: completeTutorial,
        ),
    };
  }
}
