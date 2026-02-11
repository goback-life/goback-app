import 'dart:ui' as ui;

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
/// Displays a blurred glass backdrop with Lilita One navigation labels
/// for the five main destinations: Feed, Circle, Notifications,
/// Lockouts (friends), and Profile.
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
    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          color: MainColors.dark.withValues(alpha: 0.5),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final item in _items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: GestureDetector(
                        onTap: () => _onItemTap(item),
                        child: ShaderMask(
                          shaderCallback: (bounds) => ui.Gradient.linear(
                            bounds.topLeft,
                            bounds.bottomRight,
                            [
                              MainColors.white,
                              MainColors.accent,
                              MainColors.white,
                            ],
                            [0.0, 0.5, 1.0],
                          ),
                          child: Text(
                            item.label,
                            style: const TextStyle(
                              fontFamily: MainFontFamilies.lilitaOne,
                              fontSize: 40,
                              color: MainColors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
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
