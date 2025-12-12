import 'dart:io';

import 'package:cloudless/core/features/profile/data/exceptions/profile_username_not_available_exception.dart';
import 'package:cloudless/core/features/profile/data/storables/profile_completed_storable.dart';
import 'package:cloudless/core/features/profile/domain/enums/profile_form_item.dart';
import 'package:cloudless/core/features/profile/domain/providers/check_username_availability_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/create_or_update_profile_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/upload_avatar_provider.dart';
import 'package:cloudless/core/features/supabase/data/handlers/common_supabase_exception_ui_handler.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/hooks/use_debounced_username_check.dart';
import 'package:cloudless/presentation/pages/home/home_routable.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_form/dedecube_form.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/foundation.dart';

typedef CreateProfileFormResult = ({
  FormerGroup form,
  AsyncCallback submit,
  ValueNotifier<bool> isSubmitting,
  DebouncedUsernameResult usernameCheckResult,
  bool canSubmit,
  void Function(File?) setAvatarFile,
});

CreateProfileFormResult useCreateProfileForm(WidgetRef ref) {
  const int minUsernameLength = 3;
  final RegExp usernameRegex = RegExp(r'^[a-z0-9_\.]+$');

  final currentUsername = useState<String>('');
  final canSubmit = useState<bool>(false);
  final selectedAvatar = useState<File?>(null);

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
      logger.info('Profile created successfully');

      // Set local flag that profile has been completed
      final profileCompletedStorable = ProfileCompletedStorable();
      await profileCompletedStorable.set(true);

      router.go(const HomeRoutable());
    },
    onFailure: (form, error) async {
      logger.error('Profile creation failed', exception: error);

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

  final usernameCheckResult = useDebouncedUsernameCheck(
    ref,
    currentUsername.value,
    debounce: const Duration(milliseconds: 600),
    minLength: minUsernameLength,
  );

  useEffect(
    () {
      final form = formResult.form;
      final isFormValid = form.valid;
      final isUsernameAvailable = usernameCheckResult.isAvailable == true;
      final isNotProcessing =
          !usernameCheckResult.isDebouncing && !usernameCheckResult.isLoading;

      canSubmit.value = isFormValid && isUsernameAvailable && isNotProcessing;
      return null;
    },
    [
      formResult.form.valid,
      usernameCheckResult.isAvailable,
      usernameCheckResult.isDebouncing,
      usernameCheckResult.isLoading,
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
  );
}
