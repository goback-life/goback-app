import 'package:cloudless/presentation/pages/feed/components/feed_lockout_button.dart';
import 'package:cloudless/presentation/pages/feed/feed_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:flutter/material.dart';

/// Visual clone of [NavOverlay] for the tutorial.
///
/// Same dark backdrop, Lilita One labels with `.toUpperCase()`,
/// and a lockout button at the bottom — matching the real overlay exactly.
/// Tapping any label or background calls [onDismiss] instead of navigating.
class TutorialNavOverlay extends StatelessWidget {
  const TutorialNavOverlay({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  static const _labels = ['Feed', 'Circle', 'Notifs', 'Lockouts', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final sw = size.width / 402.0;
    final sh = size.height / 874.0;

    // Lockout triangle geometry — matches NavOverlay exactly.
    final btnW = 86 * sw;
    final btnH = 102 * sw;
    final lockoutBottom = FeedLayout.lockoutBottomDistance * sw - btnH / 2;
    final triangleTopFromBottom = lockoutBottom + btnH;

    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: MainColors.dark.withValues(alpha: 0.88),
        child: Stack(
          children: [
            // Nav labels — last item equidistant from screen top
            // and triangle top.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: triangleTopFromBottom,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final label in _labels)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 14 * sh),
                        child: GestureDetector(
                          onTap: onDismiss,
                          child: Text(
                            label.toUpperCase(),
                            style: TextStyle(
                              fontFamily: MainFontFamilies.lilitaOne,
                              fontSize: 44 * sw,
                              color: MainColors.white,
                              letterSpacing: 1,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Lockout button — same position as feed / real overlay.
            Positioned(
              bottom: lockoutBottom,
              left: size.width / 2 +
                  FeedLayout.lockoutCenterOffsetX * sw -
                  btnW / 2,
              child: IgnorePointer(
                child: FeedLockoutButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
