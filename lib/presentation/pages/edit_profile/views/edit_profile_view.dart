import 'dart:io';

import 'package:cloudless/core/features/media/domain/hooks/use_image_picker.dart';
import 'package:cloudless/core/features/profile/domain/hooks/use_edit_profile_form.dart';
import 'package:cloudless/presentation/components/form_field/description_form_field.dart';
import 'package:cloudless/presentation/components/form_field/username_form_field.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image.dart';
import 'package:cloudless/presentation/pages/edit_profile/components/confirm_edit_profile_button.dart';
import 'package:cloudless/presentation/pages/edit_profile/edit_profile_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_form/dedecube_form.dart';
import 'package:dedecube_presentation/hooks/use_loading_overlay.dart';
import 'package:dedecube_presentation/widgets/layout/bottomed_list_view.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class EditProfileView extends HookConsumerWidget
    with MainLayout, EditProfileLayout {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formResult = useEditProfileForm(ref);
    final selectedImage = useState<File?>(null);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    useLoadingOverlay(formResult.isSubmitting);

    final initialAvatarUrl = useState<String?>(null);

    formResult.profileData.whenData((result) {
      result.fold((profile) {
        if (profile?.avatarUrl != null) {
          initialAvatarUrl.value = profile!.avatarUrl;
        }
      }, (error) {});
    });

    final showImagePicker = useImagePicker(
      ref: ref,
      onImageSelected: (file) {
        if (ref.context.mounted) {
          selectedImage.value = file;
          formResult.setAvatarFile(file);
        }
      },
    );

    return FormerForm(
      form: formResult.form,
      child: Expanded(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: BottomedListView(
            useSafeArea: true,
            bottom: Padding(
              padding: EdgeInsets.only(bottom: bottomMargin),
              child: ValueListenableBuilder<bool>(
                valueListenable: formResult.isSubmitting,
                builder: (context, isSubmitting, child) {
                  return ConfirmEditProfileButton(
                    onSubmit: formResult.submit,
                    isEnabled: !isSubmitting,
                  );
                },
              ),
            ),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ProfileImage(
                    imageFile: selectedImage.value,
                    imageUrl: initialAvatarUrl.value,
                    onImageSelected: (file) {
                      selectedImage.value = file;
                      formResult.setAvatarFile(file);
                    },
                    isEditable: true,
                  ),
                  SizedBox(height: imageToEdit),
                  GestureDetector(
                    onTap: showImagePicker,
                    child: Text(
                      translator.translate('pages.edit_profile.edit_image'),
                      style: textTheme.bodyMedium?.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: editTextToUsernameField),
              UsernameFormField(
                usernameCheckResult: formResult.usernameCheckResult,
              ),
              SizedBox(height: usernameFieldToBioField),
              const DescriptionFormField(),
              SizedBox(height: bottomMargin),
            ],
          ),
        ),
      ),
    );
  }
}
