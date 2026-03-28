import 'dart:io';

import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/profile/domain/enums/profile_form_item.dart';
import 'package:cloudless/core/features/profile/domain/hooks/profile_form_helpers.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/core/models/profile_model.dart';
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
    controls: buildProfileFormControls(),
    onSubmit: (values) {
      final username = values[ProfileFormItem.username.value] as String;
      final needsCheck = username != originalUsername.value;
      return profileFormSubmit(ref, values: values, checkUsername: needsCheck);
    },
    onSuccess: (success) async {
      logger.info('Profile updated successfully');
      ref.invalidate(getProfileProvider);
      Navigator.of(ref.context).pop();
    },
    onFailure: (form, error) => profileFormOnFailure(ref, form, error),
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
    minLength: profileMinUsernameLength,
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
