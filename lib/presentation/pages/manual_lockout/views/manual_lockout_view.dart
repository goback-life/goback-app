import 'dart:async';

import 'package:cloudless/core/features/lockout/data/providers/manual_lockout_storable_provider.dart';
import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/background_image.dart';
import 'package:cloudless/presentation/pages/home/home_routable.dart';
import 'package:cloudless/presentation/pages/lockout_complete/lockout_complete_routable.dart';
import 'package:cloudless/presentation/pages/manual_lockout/components/friends_locked_out_list.dart';
import 'package:cloudless/presentation/pages/manual_lockout/components/manual_lockout_exit_button.dart';
import 'package:cloudless/presentation/pages/manual_lockout/manual_lockout_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class ManualLockoutView extends HookConsumerWidget
    with MainLayout, ManualLockoutLayout {
  const ManualLockoutView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final lockoutStateAsync = ref.watch(manualLockoutNotifierProvider);
    final countdown = useState('');
    final hasNavigated = useState(false);

    useEffect(() {
      Timer? timer;

      lockoutStateAsync.whenData((lockoutState) {
        if (!lockoutState.isLockedOut && !hasNavigated.value) {
          // Lockout expired, navigate to lockout complete screen
          hasNavigated.value = true;
          _navigateToLockoutComplete(ref);
          return;
        }

        // Update countdown periodically
        timer?.cancel();
        timer = Timer.periodic(const Duration(seconds: 1), (_) {
          ref.read(manualLockoutNotifierProvider.notifier).refresh().then((_) {
            final updatedState = ref.read(manualLockoutNotifierProvider);
            updatedState.whenData((state) {
              if (state.isLockedOut && state.remainingDuration != null) {
                countdown.value = _formatDuration(state.remainingDuration!);
              } else if (!hasNavigated.value) {
                // Lockout expired
                hasNavigated.value = true;
                _navigateToLockoutComplete(ref);
              }
            });
          });
        });

        // Initial countdown
        if (lockoutState.remainingDuration != null) {
          countdown.value = _formatDuration(lockoutState.remainingDuration!);
        }
      });

      return () {
        timer?.cancel();
      };
    }, [lockoutStateAsync]);

    return BackgroundImage(
      backgroundImage: Assets.png.backgroundGoback.provider(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.6],
            colors: [
              colorScheme.secondary.withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: topPadding),
                  Text(
                    translator.translate('pages.manual_lockout.title'),
                    style: textTheme.displaySmall?.copyWith(
                      color: colorScheme.surface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  if (countdown.value.isNotEmpty)
                    Text(
                      countdown.value,
                      style: textTheme.headlineLarge?.copyWith(
                        color: colorScheme.surface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const Spacer(flex: 2),
                  Assets.svg.logoApp.render(width: logoSize, height: logoSize),
                  const Spacer(flex: 2),
                  const FriendsLockedOutList(),
                  const Spacer(flex: 1),
                  const ManualLockoutExitButton(),
                  SizedBox(height: buttonBottomPadding),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _navigateToLockoutComplete(WidgetRef ref) async {
    final storable = ref.read(manualLockoutStorableProvider);
    final sessionId = await storable.getLockoutSessionId();

    logger.info('Lockout complete - sessionId: $sessionId');

    // Always navigate to lockout complete screen, even without sessionId
    // User can still create a post, it just won't be linked to a session
    final effectiveSessionId = sessionId ?? '';
    logger.info('Navigating to LockoutComplete screen with sessionId: $effectiveSessionId');
    router.go(LockoutCompleteRoutable(lockoutSessionId: effectiveSessionId));
  }
}

