import 'package:cloudless/presentation/pages/notifications/notifications_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class NotificationHeader extends HookConsumerWidget
    with MainLayout, NotificationsLayout {
  const NotificationHeader({super.key, required this.onMarkAllAsRead});

  final VoidCallback onMarkAllAsRead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: notificationItemPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onMarkAllAsRead,
            child: Text(
              translator.translate(
                'pages.notifications.markAllAsRead',
                context: context,
              ),
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
