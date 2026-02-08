import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/presentation/components/main_data_loader.dart';
import 'package:cloudless/presentation/components/profile_description.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image.dart';
import 'package:cloudless/presentation/components/username_field.dart';
import 'package:cloudless/presentation/pages/circle_profile/circle_profile_layout.dart';
import 'package:cloudless/presentation/pages/profile/components/calendar_section/profile_calendar.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/material.dart';

class CircleProfileView extends HookConsumerWidget
    with MainLayout, CircleProfileLayout {
  const CircleProfileView({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(getProfileProvider(userId));
    final circleMembersAsync = ref.watch(getCircleMembersProvider);

    return Expanded(
      child: MainDataLoader(
        provider: profileAsync,
        useScaffold: false,
        onRetry: () {
          ref.invalidate(getProfileProvider(userId));
        },
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

          return BottomedListView(
            useSafeArea: false,
            bottom: ProfileCalendar(userId: userId),
            children: [
              Center(
                child: ProfileImage(
                  imageUrl: profileToUse!.avatarUrl,
                  username: profileToUse.username,
                  isEditable: false,
                  showFromProfile: false,
                  showFullScreen: true,
                ),
              ),
              SizedBox(height: verticalSpacing),
              UsernameField(profileId: userId),
              SizedBox(height: verticalSpacing),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalSpacing + 5,
                ),
                child: ProfileDescription(profileId: userId),
              ),
              SizedBox(height: buttonToCalendar),
            ],
          );
        },
      ),
    );
  }
}
