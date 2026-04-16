import 'package:cloudless/presentation/pages/friends_locked_out/views/friends_locked_out_view.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class FriendsLockedOutPage extends HookConsumerWidget with MainLayout {
  const FriendsLockedOutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: const SafeArea(child: FriendsLockedOutView()),
    );
  }
}
