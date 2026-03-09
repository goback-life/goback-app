import 'package:cloudless/presentation/pages/feed/components/feed_lockout_button.dart';
import 'package:cloudless/presentation/pages/feed/feed_layout.dart';
import 'package:cloudless/presentation/pages/friends_locked_out/friends_locked_out_routable.dart';
import 'package:cloudless/presentation/pages/home/home_routable.dart';
import 'package:cloudless/presentation/pages/notifications/notifications_routable.dart';
import 'package:cloudless/presentation/pages/profile/profile_routable.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_routable.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Full-screen navigation overlay shown on long-press.
///
/// Blurred backdrop with wide-spaced solid white Lilita One labels
/// and a goback button at the bottom.
class NavOverlay extends StatelessWidget {
  const NavOverlay({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  static const _items = <_NavItem>[
    _NavItem(label: 'Feed', route: HomeRoutable()),
    _NavItem(label: 'Circle', route: YourCircleRoutable()),
    _NavItem(label: 'Notifs', route: NotificationsRoutable()),
    _NavItem(label: 'Lockouts', route: FriendsLockedOutRoutable()),
    _NavItem(label: 'Profile', route: ProfileRoutable()),
  ];

  void _onItemTap(_NavItem item) {
    onDismiss();
    router.go(item.route);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final sw = size.width / 402.0;
    final sh = size.height / 874.0;

    // Lockout triangle geometry.
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
            // Nav labels: last item equidistant from screen top
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
                    for (final item in _items)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 14 * sh),
                        child: GestureDetector(
                          onTap: () => _onItemTap(item),
                          child: Text(
                            item.label.toUpperCase(),
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
            // Lockout button — same position as feed.
            Positioned(
              bottom: lockoutBottom,
              left: size.width / 2 +
                  FeedLayout.lockoutCenterOffsetX * sw -
                  btnW / 2,
              child: const FeedLockoutButton(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.route});

  final String label;
  final BaseRoutable route;
}
