import 'package:cloudless/presentation/components/profile_description.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image.dart';
import 'package:cloudless/presentation/components/username_field.dart';
import 'package:cloudless/presentation/pages/profile/components/calendar_section/profile_calendar.dart';
import 'package:cloudless/presentation/pages/profile/components/edit_profile_button.dart';
import 'package:cloudless/presentation/pages/profile/components/profile_weekly_stats.dart';
import 'package:cloudless/presentation/pages/profile/profile_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/material.dart';

class ProfileView extends HookConsumerWidget with MainLayout, ProfileLayout {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: BottomedListView(
        useSafeArea: false,
        bottom: const ProfileCalendar(),
        children: [
          const Center(
            child: ProfileImage(
              showFromProfile: true,
              isEditable: false,
              showFullScreen: true,
            ),
          ),
          SizedBox(height: verticalSpacing),
          const UsernameField(),
          SizedBox(height: verticalSpacing),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalSpacing + 5),
            child: const ProfileDescription(),
          ),
          SizedBox(height: verticalSpacing),
          const EditProfileButton(),
          SizedBox(height: verticalSpacing),
          const ProfileWeeklyStats(),
          SizedBox(height: buttonToCalendar),
        ],
      ),
    );
  }
}
