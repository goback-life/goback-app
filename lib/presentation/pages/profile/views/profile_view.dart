import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/presentation/components/profile_description.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image.dart';
import 'package:cloudless/presentation/components/username_field.dart';
import 'package:cloudless/presentation/pages/profile/components/calendar_section/profile_calendar.dart';
import 'package:cloudless/presentation/pages/profile/components/profile_tab_toggle.dart';
import 'package:cloudless/presentation/pages/profile/components/stats_section/profile_stats_view.dart';
import 'package:cloudless/presentation/pages/profile/profile_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class ProfileView extends HookConsumerWidget with MainLayout, ProfileLayout {
  const ProfileView({required this.scale, super.key});

  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    final s = scale;
    final scaledAvatarSize = avatarSize * s;
    final tabIndex = useState<int>(0);

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

    // Resolve current user and profile once.
    final currentUserAsync = ref.watch(getCurrentUserProvider);
    String? avatarUrl;
    String? username;
    String? biography;
    String? currentUserId;
    bool profileResolved = false;

    currentUserAsync.whenData((userResult) {
      userResult.fold((user) {
        currentUserId = user.id;
        final profileAsync = ref.watch(getProfileProvider(user.id));
        profileAsync.whenData((profileResult) {
          profileResult.fold((profile) {
            avatarUrl = profile?.avatarUrl;
            username = profile?.username;
            biography = profile?.biography;
            profileResolved = true;
          }, (_) {});
        });
      }, (_) {});
    });

    return SizedBox.expand(
      child: Stack(
        children: [
          // Avatar (read-only display)
          Positioned(
            top: avatarTop,
            left: 0,
            right: 0,
            child: Center(
              child: profileResolved
                  ? ProfileImage(
                      imageUrl: avatarUrl,
                      username: username,
                      isEditable: false,
                      showFullScreen: true,
                      size: scaledAvatarSize,
                    )
                  : ProfileImage(
                      showFromProfile: true,
                      isEditable: false,
                      showFullScreen: true,
                      showLoading: true,
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
              child: profileResolved
                  ? UsernameField(username: username ?? '')
                  : UsernameField(
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
                  child: profileResolved
                      ? ProfileDescription(
                          showFullDescription: true,
                          biography: biography,
                        )
                      : const ProfileDescription(
                          showFullDescription: true,
                        ),
                ),
              ),
            ),
          ),

          // Tab toggle (replaces standalone weekly stats position)
          Positioned(
            top: statsTop,
            left: 0,
            right: 0,
            child: Center(
              child: ProfileTabToggle(
                selectedIndex: tabIndex.value,
                onChanged: (i) => tabIndex.value = i,
                scale: s,
              ),
            ),
          ),

          // Tab content area
          Positioned(
            top: calTop,
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 8 * s,
            child: IndexedStack(
              index: tabIndex.value,
              children: [
                // Calendar tab
                ProfileCalendar(scale: s),
                // Stats tab — pad top so it clears the tab toggle
                Padding(
                  padding: EdgeInsets.only(
                    top: (statsTop + 56 * s) - calTop,
                  ),
                  child: currentUserId != null
                      ? ProfileStatsView(userId: currentUserId!, scale: s)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
