import 'package:cloudless/presentation/components/main_app_bar/main_app_bar.dart';
import 'package:cloudless/presentation/pages/otp/otp_layout.dart';
import 'package:cloudless/presentation/pages/otp/views/otp_view.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class OtpPage extends HookConsumerWidget with MainLayout, OtpLayout {
  const OtpPage({
    required this.phoneNumber,
    this.email = '',
    super.key,
  });

  final String phoneNumber;
  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: topMargin),
              MainAppBar(title: translator.translate('pages.sign_in.title')),
              SizedBox(height: mainAppBarToTitle),
              Expanded(
                child: OtpView(phoneNumber: phoneNumber, email: email),
              ),
            ],
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
    );
  }
}
