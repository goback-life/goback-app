import 'package:cloudless/presentation/components/squircle_clipper.dart';
import 'package:cloudless/presentation/pages/feed/feed_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:flutter/material.dart';

/// Simplified post card for the tutorial feed.
///
/// Same squircle + avatar row layout as [FeedPostCard] but uses
/// [Image.asset] and has no-op taps.
class TutorialPostCard extends StatelessWidget {
  const TutorialPostCard({
    super.key,
    required this.assetPath,
    required this.username,
    required this.isRight,
  });

  final String assetPath;
  final String username;
  final bool isRight;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final s = screenWidth / 402.0;

    final squircleSize = FeedLayout.squircleSize * s;
    final avatarSize = FeedLayout.avatarSize * s;
    final avatarInset = FeedLayout.avatarInsetFromSquircle * s;
    final avatarToName = FeedLayout.avatarToNameGap * s;
    final squircleToAuthor = FeedLayout.squircleToAuthorGap * s;
    final fontSize = FeedLayout.usernameFontSize * s;
    final letterSpacing = FeedLayout.usernameLetterSpacing * s;
    final nameMaxW = FeedLayout.nameMaxWidth(screenWidth);

    final leftInset = FeedLayout.leftPostInset * s;
    final rightInset = FeedLayout.rightPostInsetFromRight * s;

    return Padding(
      padding: EdgeInsets.only(
        left: isRight ? 0 : leftInset,
        right: isRight ? rightInset : 0,
      ),
      child: Align(
        alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
        child: SizedBox(
          width: squircleSize,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Squircle image
              SizedBox(
                width: squircleSize,
                height: squircleSize,
                child: ClipSquircle(
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    width: squircleSize,
                    height: squircleSize,
                  ),
                ),
              ),
              SizedBox(height: squircleToAuthor),
              // Author row
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 6 * s,
                  horizontal: avatarInset,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar placeholder
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: avatarToName),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: nameMaxW),
                      child: Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: MainFontFamilies.quicksand,
                          fontWeight: FontWeight.w400,
                          fontSize: fontSize,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: letterSpacing,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
