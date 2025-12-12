import 'package:cloudless/core/features/time_limit/domain/providers/time_limit_tracker_notifier_provider.dart';
import 'package:cloudless/presentation/pages/time_limit_reached/time_limit_reached_routable.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/widgets.dart';

/// Widget that listens to time limit changes and navigates to block screen when limit is reached
class TimeLimitListenerWidget extends HookConsumerWidget {
  const TimeLimitListenerWidget({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for limit reached events
    ref.listen(timeLimitTrackerNotifierProvider, (previous, next) {
      next.whenData((timeLimit) {
        if (timeLimit.isLimitReached &&
            !(previous?.value?.isLimitReached ?? false)) {
          logger.info('Time limit just reached - navigating to block screen');
          router.go(const TimeLimitReachedRoutable());
        }
      });
    });

    return child;
  }
}
