import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/presentation/pages/manual_lockout/manual_lockout_routable.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/widgets.dart';

/// Widget that listens to manual lockout changes and navigates to lockout screen.
class LockoutListenerWidget extends HookConsumerWidget {
  const LockoutListenerWidget({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(manualLockoutNotifierProvider, (previous, next) {
      next.whenData((lockoutState) {
        if (lockoutState.isLockedOut &&
            !(previous?.value?.isLockedOut ?? false)) {
          logger.info('Manual lockout just activated - navigating to lockout screen');
          router.go(const ManualLockoutRoutable());
        }
      });
    });

    return child;
  }
}
