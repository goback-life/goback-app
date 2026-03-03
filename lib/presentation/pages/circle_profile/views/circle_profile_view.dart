import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/presentation/components/main_data_loader.dart';
import 'package:cloudless/presentation/components/profile_description.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image.dart';
import 'package:cloudless/presentation/components/username_field.dart';
import 'package:cloudless/presentation/pages/profile/components/calendar_section/profile_calendar.dart';
import 'package:cloudless/presentation/pages/profile/components/profile_weekly_stats.dart';
import 'package:cloudless/presentation/pages/profile/profile_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// Friend profile view: V1 design with avatar, username, bio, stats, and
/// read-only calendar (friend can view posts but not comment/react on them).
class CircleProfileView extends HookConsumerWidget
    with MainLayout, ProfileLayout {
  const CircleProfileView({
    required this.userId,
    required this.scale,
    super.key,
  });

  final String userId;
  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(getProfileProvider(userId));
    final circleMembersAsync = ref.watch(getCircleMembersProvider);
    final topPad = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    final s = scale;
    final scaledAvatarSize = avatarSize * s;

    // Pre-compute vertical positions (same as ProfileView).
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

    return MainDataLoader(
      provider: profileAsync,
      useScaffold: false,
      onRetry: () => ref.invalidate(getProfileProvider(userId)),
      builder: (context, fetchedProfile) {
        final cachedProfile = circleMembersAsync.whenOrNull(
          data: (result) => result.fold((members) {
            try {
              final member = members.firstWhere(
                (member) => member.profile.id == userId,
              );
              return member.profile;
            } catch (e) {
              return null;
            }
          }, (_) => null),
        );

        final profileToUse =
            fetchedProfile != null &&
                    fetchedProfile.phoneNumber?.isNotEmpty == true
                ? fetchedProfile
                : cachedProfile ?? fetchedProfile;

        return SizedBox.expand(
          child: Stack(
            children: [
              // Avatar
              Positioned(
                top: avatarTop,
                left: 0,
                right: 0,
                child: Center(
                  child: ProfileImage(
                    imageUrl: profileToUse?.avatarUrl,
                    username: profileToUse?.username,
                    showFromProfile: false,
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
                  child: UsernameField(profileId: userId),
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
                      child: ProfileDescription(profileId: userId),
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

              // Calendar (read-only: friends can view but not add
              // new comments/reactions on posts)
              Positioned(
                top: calTop,
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).padding.bottom + 8 * s,
                child: ProfileCalendar(userId: userId, scale: s),
              ),
            ],
          ),
        );
      },
    );
  }
}
