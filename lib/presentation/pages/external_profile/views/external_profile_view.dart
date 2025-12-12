import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/presentation/components/profile_description.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image.dart';
import 'package:cloudless/presentation/components/username_field.dart';
import 'package:cloudless/presentation/pages/external_profile/external_profile_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class ExternalProfileView extends HookConsumerWidget
    with MainLayout, ExternalProfileLayout {
  const ExternalProfileView({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(getProfileProvider(userId));

    return profileAsync.when(
      data: (profileResult) {
        return profileResult.fold((profile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProfileImage(
                showFromProfile: false,
                isEditable: false,
                showFullScreen: true,
                imageUrl: profile!.avatarUrl,
                username: profile.username,
              ),
              SizedBox(height: verticalSpacing),
              UsernameField(username: profile.username),
              SizedBox(height: verticalSpacing),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalSpacing + 5,
                ),
                child: ProfileDescription(
                  showFullDescription: true,
                  biography: profile.biography,
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
