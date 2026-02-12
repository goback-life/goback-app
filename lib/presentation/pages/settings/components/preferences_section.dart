import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/pages/objective/objective_routable.dart';
// import 'package:cloudless/presentation/pages/settings/components/notifications_switch.dart';
import 'package:cloudless/presentation/pages/settings/components/settings_menu_item.dart';
import 'package:cloudless/presentation/pages/settings/settings_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/material.dart';

class PreferencesSection extends HookConsumerWidget
    with MainLayout, SettingsLayout {
  const PreferencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // final notificationsEnabled = useState(true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translator.translate('pages.settings.preferences'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: titleSectionToElement),

        SettingsMenuItem(
          icon: Assets.svg.objective.render(colorFilter: colorScheme.onSurface.asSrcIn),
          title: translator.translate('pages.settings.objective'),
          onTap: () {
            router.push(
              const ObjectiveRoutable(
                showBackButton: true,
                showBottomButton: false,
              ),
            );
          },
        ),

        // SizedBox(height: verticalSpacing),

        // _buildNotificationMenuItem(context, notificationsEnabled),
      ],
    );
  }

  // Widget _buildNotificationMenuItem(
  //   BuildContext context,
  //   ValueNotifier<bool> notificationsEnabled,
  // ) {
  //   final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;

  //   return GestureDetector(
  //     onTap: () {
  //       notificationsEnabled.value = !notificationsEnabled.value;
  //     },
  //     child: Row(
  //       children: [
  //         Assets.svg.notifications.render(),
  //         SizedBox(width: circleToText),
  //         Expanded(
  //           child: Text(
  //             translator.translate('pages.settings.notifications'),
  //             style: theme.textTheme.bodyLarge?.copyWith(
  //               color: colorScheme.onSurface,
  //             ),
  //           ),
  //         ),
  //         NotificationSwitch(
  //           value: notificationsEnabled.value,
  //           onChanged: null,
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
