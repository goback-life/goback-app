import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/presentation/components/profile_description.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image.dart';
import 'package:cloudless/presentation/components/username_field.dart';
import 'package:cloudless/presentation/pages/profile/profile_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// Non-friend profile view: avatar, username, and bio only.
/// Matches V1 design system styling (dark bg, white text, Quicksand).
class ExternalProfileView extends HookConsumerWidget
    with MainLayout, ProfileLayout {
  const ExternalProfileView({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(getProfileProvider(userId));
    final screenWidth = MediaQuery.of(context).size.width;
    final s = screenWidth / designWidth;

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

    final theme = Theme.of(context);

    return profileAsync.when(
      data: (profileResult) {
        return profileResult.fold((profile) {
          if (profile == null) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProfileImage(
                showFromProfile: false,
                isEditable: false,
                showFullScreen: true,
                imageUrl: profile.avatarUrl,
                username: profile.username,
                size: avatarSize * s,
              ),
              SizedBox(height: usernameTopGap * s),
              Theme(
                data: theme.copyWith(
                  textTheme: theme.textTheme.copyWith(
                    titleLarge: usernameStyle,
                  ),
                ),
                child: UsernameField(username: profile.username),
              ),
              SizedBox(height: bioTopGap * s),
              SizedBox(
                width: bioMaxWidth * s,
                child: Theme(
                  data: theme.copyWith(
                    textTheme: theme.textTheme.copyWith(bodyMedium: bioStyle),
                  ),
                  child: ProfileDescription(
                    showFullDescription: true,
                    biography: profile.biography,
                  ),
                ),
              ),
            ],
          );
        }, (error) => const SizedBox.shrink());
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
