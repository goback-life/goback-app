import 'package:cloudless/core/features/lockout/data/providers/manual_lockout_storable_provider.dart';
import 'package:cloudless/core/features/lockout/domain/providers/pending_lockout_post_provider.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_post_creation_initialization.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/background_image.dart';
import 'package:cloudless/presentation/pages/home/home_routable.dart';
import 'package:cloudless/presentation/pages/lockout_complete/lockout_complete_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class LockoutCompleteView extends HookConsumerWidget
    with MainLayout, LockoutCompleteLayout {
  const LockoutCompleteView({required this.lockoutSessionId, super.key});

  final String lockoutSessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Use post creation initialization, skipping content type picker (no text posts)
    final postCreationInit = usePostCreationInitialization(
      ref,
      skipContentTypePicker: true,
    );

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
                    translator.translate('pages.lockout_complete.title'),
                    style: textTheme.displaySmall?.copyWith(
                      color: colorScheme.surface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    translator.translate('pages.lockout_complete.subtitle'),
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.surface.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 2),
                  Assets.svg.logoApp.render(width: logoSize, height: logoSize),
                  const Spacer(flex: 3),
                  // Share button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Set pending lockout for content editor (if we have a session ID)
                        logger.info('LockoutComplete: lockoutSessionId = $lockoutSessionId');
                        if (lockoutSessionId.isNotEmpty) {
                          ref
                              .read(pendingLockoutPostProvider.notifier)
                              .setLockoutId(lockoutSessionId);
                          logger.info('LockoutComplete: Set pending lockout ID');
                        } else {
                          logger.warning('LockoutComplete: lockoutSessionId is empty');
                        }
                        // Open media picker, then navigate to content editor
                        postCreationInit.selectMainImage();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.surface,
                        foregroundColor: colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        translator.translate('pages.lockout_complete.share_button'),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: buttonSpacing),
                  // Skip button
                  TextButton(
                    onPressed: () async {
                      // Clear storage and go home
                      final storable = ref.read(manualLockoutStorableProvider);
                      await storable.clearLockout();
                      router.go(const HomeRoutable());
                    },
                    child: Text(
                      translator.translate('pages.lockout_complete.skip_button'),
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.surface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  SizedBox(height: buttonBottomPadding),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
