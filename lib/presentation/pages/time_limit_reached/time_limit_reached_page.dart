import 'package:cloudless/presentation/pages/time_limit_reached/time_limit_reached_layout.dart';
import 'package:cloudless/presentation/pages/time_limit_reached/views/time_limit_reached_view.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class TimeLimitReachedPage extends HookConsumerWidget
    with MainLayout, TimeLimitReachedLayout {
  const TimeLimitReachedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: const TimeLimitReachedView(),
      ),
    );
  }
}
