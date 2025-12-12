import 'dart:io';

import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/profile/data/exceptions/profile_username_not_available_exception.dart';
import 'package:cloudless/core/features/profile/domain/enums/profile_form_item.dart';
import 'package:cloudless/core/features/profile/domain/providers/check_username_availability_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/create_or_update_profile_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/upload_avatar_provider.dart';
import 'package:cloudless/core/features/supabase/data/handlers/common_supabase_exception_ui_handler.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/hooks/use_debounced_username_check.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_form/dedecube_form.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef EditProfileFormResult = ({
  FormerGroup form,
  AsyncCallback submit,
  ValueNotifier<bool> isSubmitting,
  DebouncedUsernameResult usernameCheckResult,
  bool canSubmit,
  void Function(File?) setAvatarFile,
  AsyncValue<Result<ProfileModel?>> profileData,
  bool isInitialized,
});

EditProfileFormResult useEditProfileForm(WidgetRef ref) {
  const int minUsernameLength = 3;
  final RegExp usernameRegex = RegExp(r'^[a-z0-9_\.]+$');

  final currentUsername = useState<String>('');
  final canSubmit = useState<bool>(false);
  final selectedAvatar = useState<File?>(null);
  final originalUsername = useState<String>('');
  final isInitialized = useState<bool>(false);

  final currentUserAsync = ref.watch(getCurrentUserProvider);
  final profileAsync = currentUserAsync.when<AsyncValue<Result<ProfileModel?>>>(
    data: (userResult) => userResult.fold((user) {
      return ref.watch(getProfileProvider(user.id));
    }, (error) => AsyncValue.error(error, StackTrace.current)),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );

  final formResult = useForm<bool>(
    controls: {
      ProfileFormItem.username.value: FormerControl<String>(
        validators: [
          FormerValidators.required(),
          FormerValidators.minLength(minUsernameLength),
          (control) {
            final value = control.value;
            if (value == null || value.isEmpty) {
              return null;
            }

            if (!usernameRegex.hasMatch(value.toLowerCase())) {
              return {'pattern': true};
            }
            return null;
          },
        ],
      ),
      ProfileFormItem.biography.value: FormerControl<String>(validators: []),
      ProfileFormItem.avatar.value: FormerControl<File?>(validators: []),
    },
    onSubmit: (values) async {
      final username = values[ProfileFormItem.username.value] as String;
      final biography = values[ProfileFormItem.biography.value] as String?;
      final avatarFile = values[ProfileFormItem.avatar.value] as File?;

      if (username != originalUsername.value) {
        final availabilityResult = await ref.read(
          checkUsernameAvailabilityProvider(username).future,
        );

        final availabilityCheck = availabilityResult.fold<Result<bool>>((
          isAvailable,
        ) {
          if (!isAvailable) {
            return Result.failure(
              ProfileUsernameNotAvailableException(username),
            );
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
    },
    onSuccess: (success) async {
      logger.info('Profile updated successfully');

      ref.invalidate(getProfileProvider);

      Navigator.of(ref.context).pop();
    },
    onFailure: (form, error) async {
      logger.error('Profile update failed', exception: error);

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
    },
  );

  useEffect(() {
    profileAsync.whenData((Result<ProfileModel?> result) {
      result.fold(
        (ProfileModel? profile) {
          if (profile != null && !isInitialized.value) {
            formResult.form.control(ProfileFormItem.username.value).value =
                profile.username;
            formResult.form.control(ProfileFormItem.biography.value).value =
                profile.biography?.trim() ?? '';

            originalUsername.value = profile.username;
            currentUsername.value = profile.username;

            isInitialized.value = true;
          }
        },
        (Exception error) {
          logger.error('Failed to load profile', exception: error);
        },
      );
    });
    return null;
  }, [profileAsync]);

  useEffect(() {
    formResult.form.control(ProfileFormItem.avatar.value).value =
        selectedAvatar.value;
    return null;
  }, [selectedAvatar.value]);

  useEffect(() {
    final usernameControl = formResult.form.control(
      ProfileFormItem.username.value,
    );
    final subscription = usernameControl.valueChanges.listen((value) {
      currentUsername.value = value ?? '';
    });

    return subscription.cancel;
  }, const []);

  final shouldCheckUsername = currentUsername.value != originalUsername.value;
  final usernameCheckResult = useDebouncedUsernameCheck(
    ref,
    shouldCheckUsername ? currentUsername.value : '',
    debounce: const Duration(milliseconds: 600),
    minLength: minUsernameLength,
  );

  useEffect(
    () {
      final form = formResult.form;
      final isFormValid = form.valid;
      final usernameChanged = currentUsername.value != originalUsername.value;
      final isUsernameAvailable =
          !usernameChanged || (usernameCheckResult.isAvailable == true);
      final isNotProcessing =
          !usernameCheckResult.isDebouncing && !usernameCheckResult.isLoading;

      canSubmit.value =
          isFormValid &&
          isUsernameAvailable &&
          isNotProcessing &&
          isInitialized.value;
      return null;
    },
    [
      formResult.form.valid,
      usernameCheckResult.isAvailable,
      usernameCheckResult.isDebouncing,
      usernameCheckResult.isLoading,
      currentUsername.value,
      originalUsername.value,
      isInitialized.value,
    ],
  );

  void setAvatarFile(File? file) {
    selectedAvatar.value = file;
  }

  return (
    form: formResult.form,
    submit: formResult.submit,
    isSubmitting: formResult.isSubmitting,
    usernameCheckResult: usernameCheckResult,
    canSubmit: canSubmit.value,
    setAvatarFile: setAvatarFile,
    profileData: profileAsync,
    isInitialized: isInitialized.value,
  );
}
