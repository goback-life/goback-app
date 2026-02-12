import 'package:cloudless/presentation/components/profile_description.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image.dart';
import 'package:cloudless/presentation/components/username_field.dart';
import 'package:cloudless/presentation/pages/profile/components/calendar_section/profile_calendar.dart';
import 'package:cloudless/presentation/pages/profile/components/profile_weekly_stats.dart';
import 'package:cloudless/presentation/pages/profile/profile_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget with MainLayout, ProfileLayout {
  const ProfileView({required this.scale, super.key});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    final s = scale;
    final scaledAvatarSize = avatarSize * s;

    // Pre-compute vertical positions.
    final avatarTop = topPad + avatarTopOffset * s;
    final usernameTop = avatarTop + scaledAvatarSize + usernameTopGap * s;
    final usernameLineHeight = usernameFontSize * 1.2 * s;
    final bioTop = usernameTop + usernameLineHeight + bioTopGap * s;
    final bioEstHeight = bioFontSize * 2.5 * s;
    final calTop = topPad + calendarGridTop * s;
    final statsTop = (bioTop + bioEstHeight + calTop) / 2 - 9 * s;

    final usernameStyle = TextStyle(
      fontFamily: MainFontFamilies.quicksand,
      fontWeight: FontWeight.w500,
      fontSize: usernameFontSize * s,
      letterSpacing: usernameTracking * s,
      color: MainColors.white,
    );

    final bioStyle = TextStyle(
      fontFamily: MainFontFamilies.quicksand,
      fontWeight: FontWeight.w500,
      fontSize: bioFontSize * s,
      letterSpacing: bioTracking * s,
      color: MainColors.white,
    );

    return SizedBox.expand(
      child: Stack(
        children: [
          // Avatar (read-only display)
          Positioned(
            top: avatarTop,
            left: 0,
            right: 0,
            child: Center(
              child: ProfileImage(
                showFromProfile: true,
                isEditable: false,
                showFullScreen: true,
                size: scaledAvatarSize,
              ),
            ),
          ),

          // Username
          Positioned(
            top: usernameTop,
            left: 0,
            right: 0,
            child: Theme(
              data: theme.copyWith(
                textTheme:
                    theme.textTheme.copyWith(titleLarge: usernameStyle),
              ),
              child: UsernameField(
                loadingTextStyle: usernameStyle.copyWith(
                  color: MainColors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),

          // Bio
          Positioned(
            top: bioTop,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: bioMaxWidth * s,
                child: Theme(
                  data: theme.copyWith(
                    textTheme:
                        theme.textTheme.copyWith(bodyMedium: bioStyle),
                  ),
                  child: const ProfileDescription(
                    showFullDescription: true,
                  ),
                ),
              ),
            ),
          ),

          // Weekly lockout stats
          Positioned(
            top: statsTop,
            left: 0,
            right: 0,
            child: const Center(child: ProfileWeeklyStats()),
          ),

          // Calendar grid + month navigation
          Positioned(
            top: calTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: ProfileCalendar(scale: s),
          ),
        ],
      ),
    );
  }
}
