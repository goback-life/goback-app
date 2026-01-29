import 'package:cloudless/presentation/pages/lockout_complete/lockout_complete_layout.dart';
import 'package:cloudless/presentation/pages/lockout_complete/views/lockout_complete_view.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class LockoutCompletePage extends HookConsumerWidget
    with MainLayout, LockoutCompleteLayout {
  const LockoutCompletePage({required this.lockoutSessionId, super.key});

  final String lockoutSessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: LockoutCompleteView(lockoutSessionId: lockoutSessionId),
      ),
    );
  }
}
