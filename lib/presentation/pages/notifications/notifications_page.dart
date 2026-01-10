import 'package:cloudless/presentation/components/main_app_bar/main_app_bar.dart';
import 'package:cloudless/presentation/pages/notifications/notifications_layout.dart';
import 'package:cloudless/presentation/pages/notifications/views/notifications_view.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends HookConsumerWidget
    with MainLayout, NotificationsLayout {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: topMargin),
          MainAppBar(
            title: translator.translate('pages.notifications.title'),
          ),
          SizedBox(height: titleToImage),
          const Expanded(child: NotificationsView()),
        ],
      ),
    );
  }
}

