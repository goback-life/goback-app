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
    final iconSize = FeedLayout.bannerIconSize * s;
    final fontSize = FeedLayout.usernameFontSize * s;
    final letterSpacing = FeedLayout.usernameLetterSpacing * s;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: hasNew ? 12 * s : 8 * s,
          vertical: 4 * s,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE6E6E6).withValues(alpha: 0.2),
          borderRadius:
              BorderRadius.circular(FeedLayout.bannerCornerRadius * s),
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
                  fontWeight: FontWeight.w500,
                  fontSize: fontSize,
                  color: MainColors.white,
                  letterSpacing: letterSpacing,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
