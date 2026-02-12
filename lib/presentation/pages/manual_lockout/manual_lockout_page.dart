import 'package:cloudless/presentation/pages/manual_lockout/views/manual_lockout_view.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class ManualLockoutPage extends HookConsumerWidget {
  const ManualLockoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: const ManualLockoutView(),
      ),
    );
  }
}

