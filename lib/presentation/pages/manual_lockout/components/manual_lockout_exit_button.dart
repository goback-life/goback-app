import 'dart:io';

import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/pages/manual_lockout/manual_lockout_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ManualLockoutExitButton extends StatelessWidget
    with MainLayout, ManualLockoutLayout {
  const ManualLockoutExitButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final button = CallToAction.primary.filled(
      action: Platform.isIOS
          ? null
          : () async {
              await SystemNavigator.pop();
            },
      label: Text(
        translator.translate('pages.manual_lockout.button'),
        style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary),
      ),
    );

    return Platform.isIOS ? Opacity(opacity: 0, child: button) : button;
  }
}

