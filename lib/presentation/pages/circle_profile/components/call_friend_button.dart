import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/pages/circle_profile/circle_profile_layout.dart';
import 'package:cloudless/presentation/pages/circle_profile/hooks/use_call_launch.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class CallFriendButton extends HookConsumerWidget
    with MainLayout, CircleProfileLayout {
  const CallFriendButton({this.phoneNumber, super.key});

  final String? phoneNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final openCall = useCallLaunch('tel:$phoneNumber');

    return CallToAction.primary.filled(
      action: openCall,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Assets.svg.phone.render(),
          SizedBox(width: phoneToText),
          Text(
            translator.translate('pages.circle_profile.button'),
            style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
          ),
        ],
      ),
      horizontalMargin: horizontalMargin,
    );
  }
}
