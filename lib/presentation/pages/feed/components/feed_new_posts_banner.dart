import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/feed/feed_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/material.dart';

/// Pill banner above the lockout button.
///
/// Two modes:
/// - `newPostsCount > 0`: shows down arrow + "new" text.
/// - `newPostsCount == 0` (but visible = user scrolled away): just the arrow.
///
/// Tapping scrolls to bottom and loads new posts.
class FeedNewPostsBanner extends StatelessWidget {
  const FeedNewPostsBanner({
    required this.newPostsCount,
    required this.onTap,
    super.key,
  });

  final int newPostsCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final s = screenWidth / 402.0;

    final hasNew = newPostsCount > 0;
    final iconSize = 14.0 * s;
    final fontSize = 13.0 * s;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AppGlassContainer(
        config: GlassConfig(
          variant: GlassVariant.clear,
          cornerRadius: FeedLayout.bannerCornerRadius * s,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: hasNew ? 10 * s : 8 * s,
            vertical: 5 * s,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/svgs/feed_arrow_down.svg',
                width: iconSize,
                height: iconSize,
                colorFilter: MainColors.white.asSrcIn,
              ),
              if (hasNew) ...[
                SizedBox(width: 4 * s),
                Text(
                  'new',
                  style: TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontWeight: FontWeight.w400,
                    fontSize: fontSize,
                    color: MainColors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
