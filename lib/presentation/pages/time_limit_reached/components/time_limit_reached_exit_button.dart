import 'dart:io';

import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/pages/time_limit_reached/time_limit_reached_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TimeLimitReachedExitButton extends StatelessWidget
    with MainLayout, TimeLimitReachedLayout {
  const TimeLimitReachedExitButton({super.key});

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
        translator.translate('pages.time_limit_reached.button'),
        style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
      ),
    );

    return Platform.isIOS ? Opacity(opacity: 0, child: button) : button;
  }
}
