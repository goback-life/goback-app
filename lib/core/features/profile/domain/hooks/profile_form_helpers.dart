import 'dart:io';

import 'package:cloudless/core/features/profile/data/exceptions/profile_username_not_available_exception.dart';
import 'package:cloudless/core/features/profile/domain/enums/profile_form_item.dart';
import 'package:cloudless/core/features/profile/domain/providers/check_username_availability_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/create_or_update_profile_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/upload_avatar_provider.dart';
import 'package:cloudless/core/features/supabase/data/handlers/common_supabase_exception_ui_handler.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_form/dedecube_form.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

const int profileMinUsernameLength = 3;
final RegExp profileUsernameRegex = RegExp(r'^[a-z0-9_\.]+$');

/// Builds the shared form controls for create/edit profile forms.
Map<String, FormerControl<dynamic>> buildProfileFormControls() {
  return {
    ProfileFormItem.username.value: FormerControl<String>(
      validators: [
        FormerValidators.required(),
        FormerValidators.minLength(profileMinUsernameLength),
        (control) {
          final value = control.value;
          if (value == null || value.isEmpty) return null;
          if (!profileUsernameRegex.hasMatch(value.toLowerCase())) {
            return {'pattern': true};
          }
          return null;
        },
      ],
    ),
    ProfileFormItem.biography.value: FormerControl<String>(validators: []),
    ProfileFormItem.avatar.value: FormerControl<File?>(validators: []),
  };
}

/// Shared submit logic: checks username availability (if [checkUsername] is
/// true), uploads avatar, then creates/updates the profile.
Future<Result<bool>> profileFormSubmit(
  WidgetRef ref, {
  required Map<String, dynamic> values,
  required bool checkUsername,
}) async {
  final username = values[ProfileFormItem.username.value] as String;
  final biography = values[ProfileFormItem.biography.value] as String?;
  final avatarFile = values[ProfileFormItem.avatar.value] as File?;

  if (checkUsername) {
    final availabilityResult = await ref.read(
      checkUsernameAvailabilityProvider(username).future,
    );

    final availabilityCheck = availabilityResult.fold<Result<bool>>((
      isAvailable,
    ) {
      if (!isAvailable) {
        return Result.failure(ProfileUsernameNotAvailableException(username));
      }
      return Result.success(true);
    }, (error) => Result.failure(error));

    if (availabilityCheck.fold((success) => false, (error) => true)) {
      return availabilityCheck;
    }
  }

  if (avatarFile != null) {
    final uploadResult = await ref.read(
      uploadAvatarProvider(avatarFile).future,
    );

    final uploadError = uploadResult.fold<Exception?>(
      (url) => null,
      (error) => error,
    );

    if (uploadError != null) {
      return Result.failure(uploadError);
    }
  }

  final profileResult = await ref.read(
    createOrUpdateProfileProvider(
      username,
      DateTime.now(),
      DateTime.now(),
      biography: biography?.isNotEmpty == true ? biography : null,
    ).future,
  );

  return profileResult.fold<Result<bool>>(
    (profile) => Result.success(true),
    (error) => Result.failure(error),
  );
}

/// Shared failure handler for profile forms.
Future<void> profileFormOnFailure(
  WidgetRef ref,
  FormerGroup form,
  Exception error,
) async {
  logger.error('Profile form failed', exception: error);

  final handled = CommonSupabaseExceptionUIHandler()
      .handleSupabaseException(context: ref.context, exception: error);

  if (!handled) {
    switch (error) {
      case ProfileUsernameNotAvailableException():
        MainAlert.showSimple(
          context: ref.context,
          title: translator.translate(
            'components.alert.username_not_available.title',
          ),
          content: translator.translate(
            'components.alert.username_not_available.content',
          ),
        );
        break;
      default:
        await MainAlert.showGenericError(context: ref.context);
    }
  }
}
