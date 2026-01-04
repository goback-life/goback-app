import 'package:cloudless/presentation/pages/manual_lockout/manual_lockout_layout.dart';
import 'package:cloudless/presentation/pages/manual_lockout/views/manual_lockout_view.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class ManualLockoutPage extends HookConsumerWidget
    with MainLayout, ManualLockoutLayout {
  const ManualLockoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: const ManualLockoutView(),
      ),
    );
  }
}

