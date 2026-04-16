import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/circle_hub/circle_hub_routable.dart';
import 'package:cloudless/presentation/pages/feed/feed_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Plain glass circle button that opens [CircleHubRoutable].
///
/// Tints red when [hasUnread] is true (unread notifications or
/// pending friend requests).
class FeedCircleHubButton extends StatelessWidget {
  const FeedCircleHubButton({super.key, this.hasUnread = false});

  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final s = screenWidth / 402.0;
    final size = FeedLayout.circleHubButtonSize * s;

    // 44px minimum tap target, glass circle visually centered inside.
    const minTap = 44.0;
    final tapSize = minTap * s;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => router.push(const CircleHubRoutable()),
      child: SizedBox(
        width: tapSize,
        height: tapSize,
        child: Center(
          child: SizedBox(
            width: size,
            height: size,
            child: AppGlassContainer(
              config: GlassConfig(
                variant: GlassVariant.clear,
                cornerRadius: size / 2,
                tint: hasUnread
                    ? MainColors.red500.withValues(alpha: 0.35)
                    : MainColors.accent,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}
