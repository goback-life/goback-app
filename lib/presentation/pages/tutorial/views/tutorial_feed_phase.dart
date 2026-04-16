import 'dart:ui' as ui;

import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/feed/components/feed_lockout_button.dart';
import 'package:cloudless/presentation/pages/feed/feed_layout.dart';
import 'package:cloudless/presentation/pages/tutorial/components/tutorial_nav_overlay.dart';
import 'package:cloudless/presentation/pages/tutorial/components/tutorial_post_card.dart';
import 'package:cloudless/presentation/pages/tutorial/components/tutorial_tooltip.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// Feed phase of the tutorial.
///
/// Shows fictitious posts, teaches nav overlay via long-press,
/// then guides user to tap the lockout button.
///
/// Instructional steps:
///   0 → Welcome tooltip ("This is your feed…") + tap to continue
///   1 → Nav overlay tooltip ("Press and hold…") → long-press anywhere shows overlay
///   2 → Lockout tooltip ("Tap the triangle…") → tap lockout button → done
class TutorialFeedPhase extends HookWidget {
  const TutorialFeedPhase({super.key, required this.onStartLockout});

  final VoidCallback onStartLockout;

  static const _posts = <({String asset, String user, bool right})>[
    (asset: 'assets/images/tutorial/post_1.jpg', user: 'eb1', right: false),
    (asset: 'assets/images/tutorial/post_2.jpg', user: 'bilo', right: true),
    (asset: 'assets/images/tutorial/post_3.jpg', user: 'leo', right: false),
    (asset: 'assets/images/tutorial/post_4.jpg', user: 'eb1', right: true),
    (asset: 'assets/images/tutorial/post_5.jpg', user: 'bilo', right: false),
    (asset: 'assets/images/tutorial/post_6.jpg', user: 'leo', right: true),
    (asset: 'assets/images/tutorial/post_7.jpg', user: 'eb1', right: false),
    (asset: 'assets/images/tutorial/post_8.jpg', user: 'bilo', right: true),
    (asset: 'assets/images/tutorial/post_9.jpg', user: 'leo', right: false),
  ];

  @override
  Widget build(BuildContext context) {
    final step = useState(0);
    final showNavOverlay = useState(false);

    final screenWidth = MediaQuery.of(context).size.width;
    final s = screenWidth / 402.0;
    final safeTop = MediaQuery.of(context).padding.top;
    final lockoutCenterFromBottom = FeedLayout.lockoutBottomDistance * s;
    final btnW = 86 * s;
    final btnH = 102 * s;

    // Feed content (always behind overlays)
    final feedBody = Stack(
      children: [
        // Post list (reversed to match feed)
        ListView.separated(
          reverse: true,
          padding: EdgeInsets.only(
            top: safeTop + 60,
            bottom: FeedLayout.feedBottomPadding * s,
          ),
          itemCount: _posts.length,
          separatorBuilder: (_, __) =>
              SizedBox(height: FeedLayout.authorToNextPostGap * s),
          itemBuilder: (context, index) {
            final post = _posts[index];
            return TutorialPostCard(
              assetPath: post.asset,
              username: post.user,
              isRight: post.right,
            );
          },
        ),

        // Date overlay — "today"
        Positioned(
          top: safeTop + 8 * s,
          left: 0,
          right: 0,
          child: Center(
            child: AppGlassContainer(
              config: GlassConfig(
                variant: GlassVariant.clear,
                cornerRadius: FeedLayout.dateOverlayCornerRadius * s,
                tint: MainColors.accent,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: FeedLayout.dateOverlayHPadding * s,
                  vertical: FeedLayout.dateOverlayVPadding * s,
                ),
                child: Builder(
                  builder: (context) => Text(
                    'today',
                    style: TextStyle(
                      fontFamily: MainFontFamilies.quicksand,
                      fontWeight: FontWeight.w500,
                      fontSize: FeedLayout.dateFontSize * s,
                      color: Theme.of(context).colorScheme.onSurface,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Lockout button — same position as real feed
        Builder(
          builder: (context) {
            final bottomOffset = lockoutCenterFromBottom - btnH / 2;
            final leftOffset =
                screenWidth / 2 +
                FeedLayout.lockoutCenterOffsetX * s -
                btnW / 2;
            return Positioned(
              bottom: bottomOffset,
              left: leftOffset,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: step.value == 2 ? onStartLockout : null,
                child: IgnorePointer(
                  child: SizedBox(
                    width: btnW,
                    height: btnH,
                    child: const FeedLockoutButton(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );

    return Stack(
      children: [
        // Blurred content when overlay is shown
        if (showNavOverlay.value)
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: feedBody,
          )
        else
          feedBody,

        // Step 1: full-screen long-press target (sits above feed, below tooltip)
        // This ensures long-pressing *anywhere* — including over the tooltip —
        // triggers the nav overlay.
        if (step.value == 1 && !showNavOverlay.value)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onLongPressStart: (_) => showNavOverlay.value = true,
              child: const SizedBox.expand(),
            ),
          ),

        // Nav overlay
        if (showNavOverlay.value)
          Positioned.fill(
            child: TutorialNavOverlay(
              onDismiss: () {
                showNavOverlay.value = false;
                step.value = 2;
              },
            ),
          ),

        // Tooltips
        if (step.value == 0)
          TutorialTooltip(
            message: 'This is your feed.\nPosts from friends appear here.',
            onTap: () => step.value = 1,
            bottomOffset: 220,
          ),
        if (step.value == 1 && !showNavOverlay.value)
          TutorialTooltip(
            message: 'Press and hold anywhere to navigate.',
            bottomOffset: 220,
          ),
        if (step.value == 2)
          TutorialTooltip(
            message: 'Tap the triangle to lock out.',
            bottomOffset: 220,
          ),
      ],
    );
  }
}
