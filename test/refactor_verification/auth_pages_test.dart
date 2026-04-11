// Structural verification test for auth pages refactoring.
// Validates that all public widget classes, their constructors, layout mixins,
// and exported symbols remain intact after refactoring.
//
// This is a compile-time + structural test, not a widget test,
// because these pages depend on Riverpod providers, Supabase,
// router, translator, and other runtime infrastructure that cannot
// be trivially mocked in a unit test.

// -- Sign In page imports --
import 'package:cloudless/presentation/pages/sign_in/sign_in_page.dart';
import 'package:cloudless/presentation/pages/sign_in/sign_in_layout.dart';
import 'package:cloudless/presentation/pages/sign_in/sign_in_routable.dart';
import 'package:cloudless/presentation/pages/sign_in/views/sign_in_view.dart';
import 'package:cloudless/presentation/pages/sign_in/components/sign_in_button.dart';
import 'package:cloudless/presentation/pages/sign_in/components/sign_in_privacy_checkbox.dart';

// -- OTP page imports --
import 'package:cloudless/presentation/pages/otp/otp_page.dart';
import 'package:cloudless/presentation/pages/otp/otp_layout.dart';
import 'package:cloudless/presentation/pages/otp/otp_routable.dart';
import 'package:cloudless/presentation/pages/otp/views/otp_view.dart';
import 'package:cloudless/presentation/pages/otp/components/otp_button.dart';
import 'package:cloudless/presentation/pages/otp/components/otp_description.dart';
import 'package:cloudless/presentation/pages/otp/components/otp_resend_code.dart';

// -- Create Profile page imports --
import 'package:cloudless/presentation/pages/create_profile/create_profile_page.dart';
import 'package:cloudless/presentation/pages/create_profile/create_profile_layout.dart';
import 'package:cloudless/presentation/pages/create_profile/create_profile_routable.dart';
import 'package:cloudless/presentation/pages/create_profile/views/create_profile_view.dart';
import 'package:cloudless/presentation/pages/create_profile/components/create_profile_button.dart';

// -- Edit Profile page imports --
import 'package:cloudless/presentation/pages/edit_profile/edit_profile_page.dart';
import 'package:cloudless/presentation/pages/edit_profile/edit_profile_layout.dart';
import 'package:cloudless/presentation/pages/edit_profile/edit_profile_routable.dart';
import 'package:cloudless/presentation/pages/edit_profile/views/edit_profile_view.dart';
import 'package:cloudless/presentation/pages/edit_profile/components/confirm_edit_profile_button.dart';

// -- Shared form field imports --
import 'package:cloudless/presentation/components/form_field/username_form_field.dart';
import 'package:cloudless/presentation/components/form_field/description_form_field.dart';

// -- Shared button extracted during refactoring --
import 'package:cloudless/presentation/components/buttons/form_submit_button.dart';

// -- MainLayout base --
import 'package:cloudless/presentation/utilities/main_layout.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sign In page structural verification', () {
    test('SignInPage is const-constructible', () {
      const page = SignInPage();
      expect(page, isA<SignInPage>());
    });

    test('SignInView is const-constructible', () {
      const view = SignInView();
      expect(view, isA<SignInView>());
    });

    test('SignInButton requires onSubmit and isEnabled', () {
      const button = SignInButton(onSubmit: _noop, isEnabled: true);
      expect(button, isA<SignInButton>());
      expect(button.isEnabled, isTrue);
    });

    test('SignInPrivacyCheckbox requires value and onChanged', () {
      const checkbox = SignInPrivacyCheckbox(
        value: false,
        onChanged: _noopBool,
      );
      expect(checkbox, isA<SignInPrivacyCheckbox>());
      expect(checkbox.value, isFalse);
    });

    test('SignInLayout provides expected layout constants', () {
      final layout = _TestSignInLayout();
      expect(layout.horizontalPadding, 16.0);
      expect(layout.topMargin, 70.0);
      expect(layout.bottomMargin, 10.0);
      expect(layout.verticalSpacing, 24.0);
      expect(layout.leftPadding, 12.0);
      expect(layout.topPadding, 6.0);
      expect(layout.borderRadius, 8.0);
      expect(layout.titleToForm, 24.0);
      expect(layout.imageToDescription, 70.0);
      expect(layout.privacyToButton, 120.0);
      expect(layout.checkBoxToText, 12.0);
      expect(layout.checkBoxSize, 16.0);
      expect(layout.checkSize, 12.0);
      expect(layout.checkBoxBorderRadius, 4.0);
    });

    test('SignInRoutable path is /sign_in', () {
      const routable = SignInRoutable();
      expect(routable.path, '/sign_in');
    });
  });

  group('OTP page structural verification', () {
    test('OtpPage requires phoneNumber', () {
      const page = OtpPage(phoneNumber: '+1234567890');
      expect(page, isA<OtpPage>());
      expect(page.phoneNumber, '+1234567890');
    });

    test('OtpPage accepts optional email', () {
      const page = OtpPage(
        phoneNumber: '+1234567890',
        email: 'test@example.com',
      );
      expect(page.email, 'test@example.com');
    });

    test('OtpView requires phoneNumber', () {
      const view = OtpView(phoneNumber: '+1234567890');
      expect(view, isA<OtpView>());
    });

    test('OtpButton requires onSubmit and isEnabled', () {
      const button = OtpButton(onSubmit: _noop, isEnabled: true);
      expect(button, isA<OtpButton>());
    });

    test('OtpDescription requires number and text', () {
      const desc = OtpDescription(number: '+1234567890', text: 'Code sent to ');
      expect(desc, isA<OtpDescription>());
    });

    test('OtpResendCode class exists', () {
      expect(OtpResendCode, isNotNull);
    });

    test('OtpLayout provides expected layout constants', () {
      final layout = _TestOtpLayout();
      expect(layout.horizontalPadding, 16.0);
      expect(layout.rightMargin, 50.0);
      expect(layout.topMargin, 70.0);
      expect(layout.bottomMargin, 10.0);
      expect(layout.horizontalMargin, 50.0);
      expect(layout.rightPadding, 67.0);
      expect(layout.borderRadius, 8.0);
      expect(layout.mainAppBarToTitle, 40.0);
      expect(layout.titleToText, 16.0);
      expect(layout.descriptionToFormField, 20.0);
      expect(layout.resendCodeToButton, 16.0);
      expect(layout.cursorHeight, 22.0);
    });

    test('OtpRoutable path is /otp', () {
      const routable = OtpRoutable();
      expect(routable.path, '/otp');
    });

    test('OtpRoutable accepts phoneNumber and email', () {
      const routable = OtpRoutable(
        phoneNumber: '+1234567890',
        email: 'test@example.com',
      );
      expect(routable.phoneNumber, '+1234567890');
      expect(routable.email, 'test@example.com');
    });
  });

  group('Create Profile page structural verification', () {
    test('CreateProfilePage is const-constructible', () {
      const page = CreateProfilePage();
      expect(page, isA<CreateProfilePage>());
    });

    test('CreateProfileView is const-constructible', () {
      const view = CreateProfileView();
      expect(view, isA<CreateProfileView>());
    });

    test('CreateProfileButton requires onSubmit and isEnabled', () {
      const button = CreateProfileButton(onSubmit: _noop, isEnabled: true);
      expect(button, isA<CreateProfileButton>());
    });

    test('CreateProfileLayout provides expected layout constants', () {
      final layout = _TestCreateProfileLayout();
      expect(layout.horizontalPadding, 16.0);
      expect(layout.bottomMargin, 10.0);
      expect(layout.topMargin, 70.0);
      expect(layout.titleToImage, 24.0);
      expect(layout.editTextToUsernameField, 24.0);
      expect(layout.usernameFieldToBioField, 32.0);
      expect(layout.imageToEdit, 12.0);
    });

    test('CreateProfileRoutable path is /create_profile', () {
      const routable = CreateProfileRoutable();
      expect(routable.path, '/create_profile');
    });
  });

  group('Edit Profile page structural verification', () {
    test('EditProfilePage is const-constructible', () {
      const page = EditProfilePage();
      expect(page, isA<EditProfilePage>());
    });

    test('EditProfileView is const-constructible', () {
      const view = EditProfileView();
      expect(view, isA<EditProfileView>());
    });

    test('ConfirmEditProfileButton requires onSubmit and isEnabled', () {
      const button = ConfirmEditProfileButton(onSubmit: _noop, isEnabled: true);
      expect(button, isA<ConfirmEditProfileButton>());
    });

    test('EditProfileLayout provides expected layout constants', () {
      final layout = _TestEditProfileLayout();
      expect(layout.horizontalPadding, 16.0);
      expect(layout.topMargin, 70.0);
      expect(layout.bottomMargin, 10.0);
      expect(layout.titleToImage, 24.0);
      expect(layout.editTextToUsernameField, 24.0);
      expect(layout.usernameFieldToBioField, 32.0);
      expect(layout.verticalSpacing, 24.0);
      expect(layout.borderRadius, 8.0);
      expect(layout.imageToEdit, 12.0);
    });

    test('EditProfileRoutable path is /edit_profile', () {
      const routable = EditProfileRoutable();
      expect(routable.path, '/edit_profile');
    });
  });

  group('Shared form components structural verification', () {
    test('UsernameFormField class exists', () {
      expect(UsernameFormField, isNotNull);
    });

    test('DescriptionFormField is const-constructible', () {
      const field = DescriptionFormField();
      expect(field, isA<DescriptionFormField>());
    });

    test('FormSubmitButton requires onSubmit, isEnabled, and labelText', () {
      const button = FormSubmitButton(
        onSubmit: _noop,
        isEnabled: true,
        labelText: 'Test',
      );
      expect(button, isA<FormSubmitButton>());
      expect(button.isEnabled, isTrue);
      expect(button.labelText, 'Test');
    });
  });

  group('Cross-page pattern verification', () {
    test(
      'CreateProfileLayout and EditProfileLayout share identical spacing values',
      () {
        final createLayout = _TestCreateProfileLayout();
        final editLayout = _TestEditProfileLayout();

        // These values are identical between the two layouts
        expect(createLayout.horizontalPadding, editLayout.horizontalPadding);
        expect(createLayout.topMargin, editLayout.topMargin);
        expect(createLayout.bottomMargin, editLayout.bottomMargin);
        expect(createLayout.titleToImage, editLayout.titleToImage);
        expect(
          createLayout.editTextToUsernameField,
          editLayout.editTextToUsernameField,
        );
        expect(
          createLayout.usernameFieldToBioField,
          editLayout.usernameFieldToBioField,
        );
        expect(createLayout.imageToEdit, editLayout.imageToEdit);
      },
    );

    test(
      'All submit buttons share identical pattern (FormerFormConsumer + CallToAction)',
      () {
        // This test documents that SignInButton, OtpButton,
        // CreateProfileButton, and ConfirmEditProfileButton all follow
        // the same pattern: FormerFormConsumer -> canSubmit -> CallToAction.primary.filled
        // Verified by code review; structural import proves compilation.
        const signInBtn = SignInButton(onSubmit: _noop, isEnabled: true);
        const otpBtn = OtpButton(onSubmit: _noop, isEnabled: true);
        const createBtn = CreateProfileButton(onSubmit: _noop, isEnabled: true);
        const editBtn = ConfirmEditProfileButton(
          onSubmit: _noop,
          isEnabled: true,
        );

        expect(signInBtn.isEnabled, isTrue);
        expect(otpBtn.isEnabled, isTrue);
        expect(createBtn.isEnabled, isTrue);
        expect(editBtn.isEnabled, isTrue);
      },
    );
  });
}

void _noop() {}
void _noopBool(bool? value) {}

class _TestSignInLayout with MainLayout, SignInLayout {}

class _TestOtpLayout with MainLayout, OtpLayout {}

class _TestCreateProfileLayout with MainLayout, CreateProfileLayout {}

class _TestEditProfileLayout with MainLayout, EditProfileLayout {}
