import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/edit_profile/edit_profile_routable.dart';
import 'package:cloudless/presentation/pages/profile/components/profile_hamburger_menu.dart';
import 'package:cloudless/presentation/pages/profile/profile_layout.dart';
import 'package:cloudless/presentation/pages/profile/views/profile_view.dart';
import 'package:cloudless/presentation/pages/settings/settings_routable.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class ProfilePage extends HookConsumerWidget with MainLayout, ProfileLayout {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final s = screenWidth / designWidth;
    final isMenuVisible = useState(false);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          ProfileView(scale: s),

          // Hamburger menu button
          Positioned(
            top: MediaQuery.of(context).padding.top + hamburgerTopOffset * s,
            right: hamburgerRightOffset * s,
            child: ProfileHamburgerMenu(
              scale: s,
              onTap: () => isMenuVisible.value = !isMenuVisible.value,
            ),
          ),

          // Dismiss scrim
          if (isMenuVisible.value)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => isMenuVisible.value = false,
                child: Container(color: Colors.transparent),
              ),
            ),

          // Dropdown menu
          if (isMenuVisible.value)
            Positioned(
              top:
                  MediaQuery.of(context).padding.top +
                  hamburgerTopOffset * s +
                  40,
              right: hamburgerRightOffset * s,
              child: _ProfileDropdownMenu(
                scale: s,
                onEditProfile: () {
                  isMenuVisible.value = false;
                  router.push(const EditProfileRoutable());
                },
                onSettings: () {
                  isMenuVisible.value = false;
                  router.push(const SettingsRoutable());
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileDropdownMenu extends StatelessWidget {
  const _ProfileDropdownMenu({
    required this.scale,
    required this.onEditProfile,
    required this.onSettings,
  });

  final double scale;
  final VoidCallback onEditProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final itemStyle = TextStyle(
      fontFamily: MainFontFamilies.quicksand,
      fontWeight: FontWeight.w500,
      fontSize: 16 * scale,
      color: Theme.of(context).colorScheme.onSurface,
    );
    final padH = 20.0 * scale;
    final padV = 12.0 * scale;
    final radius = 16.0 * scale;

    return Material(
      color: Colors.transparent,
      child: AppGlassContainer(
        config: GlassConfig(
          variant: GlassVariant.clear,
          tint: MainColors.accent,
          cornerRadius: radius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onEditProfile,
              child: Padding(
                padding: EdgeInsets.fromLTRB(padH, padV, padH * 2, padV / 2),
                child: Text('Edit Profile', style: itemStyle),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSettings,
              child: Padding(
                padding: EdgeInsets.fromLTRB(padH, padV / 2, padH * 2, padV),
                child: Text('Settings', style: itemStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
