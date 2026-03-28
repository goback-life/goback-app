import 'dart:io';

import 'package:cloudless/core/features/onboarding/data/storables/onboarding_completed_storable.dart';
import 'package:cloudless/core/features/onboarding/data/storables/tutorial_completed_storable.dart';
import 'package:cloudless/core/features/profile/data/storables/profile_completed_storable.dart';
import 'package:cloudless/core/features/profile/domain/enums/profile_form_item.dart';
import 'package:cloudless/core/features/profile/domain/hooks/profile_form_helpers.dart';
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
  final currentUsername = useState<String>('');
  final canSubmit = useState<bool>(false);
  final selectedAvatar = useState<File?>(null);

  final formResult = useForm<bool>(
    controls: buildProfileFormControls(),
    onSubmit: (values) => profileFormSubmit(ref, values: values, checkUsername: true),
    onSuccess: (success) async {
      logger.info('Profile created successfully');

      await ProfileCompletedStorable().set(true);
      await OnboardingCompletedStorable().set(false);
      await TutorialCompletedStorable().set(false);

      router.go(const HomeRoutable());
    },
    onFailure: (form, error) => profileFormOnFailure(ref, form, error),
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
    minLength: profileMinUsernameLength,
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
