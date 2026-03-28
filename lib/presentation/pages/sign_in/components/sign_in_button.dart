import 'package:cloudless/presentation/components/buttons/form_submit_button.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class SignInButton extends StatelessWidget {
  const SignInButton({
    required this.onSubmit,
    required this.isEnabled,
    super.key,
  });

  final VoidCallback onSubmit;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return FormSubmitButton(
      onSubmit: onSubmit,
      isEnabled: isEnabled,
      labelText: translator.translate('pages.sign_in.button'),
    );
  }
}
