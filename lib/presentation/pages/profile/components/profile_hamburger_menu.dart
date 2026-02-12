import 'package:cloudless/presentation/pages/profile/profile_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class ProfileHamburgerMenu extends StatelessWidget
    with MainLayout, ProfileLayout {
  const ProfileHamburgerMenu({
    required this.scale,
    required this.onTap,
    super.key,
  });

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final barW = hamburgerBarWidth * scale;
    final barH = hamburgerBarHeight * scale;
    final radius = hamburgerBarRadius * scale;
    final spacing = hamburgerBarSpacing * scale;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: i < 2 ? spacing : 0),
              child: Container(
                width: barW,
                height: barH,
                decoration: BoxDecoration(
                  color: MainColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40191919),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
