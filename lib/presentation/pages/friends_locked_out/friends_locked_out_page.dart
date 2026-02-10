import 'package:cloudless/presentation/components/main_app_bar/main_app_bar.dart';
import 'package:cloudless/presentation/pages/friends_locked_out/friends_locked_out_layout.dart';
import 'package:cloudless/presentation/pages/friends_locked_out/views/friends_locked_out_view.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class FriendsLockedOutPage extends HookConsumerWidget
    with MainLayout, FriendsLockedOutLayout {
  const FriendsLockedOutPage({super.key});

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
            title: translator.translate('pages.friends_locked_out.title'),
          ),
          const SizedBox(height: 16),
          const Expanded(child: FriendsLockedOutView()),
        ],
      ),
    );
  }
}
