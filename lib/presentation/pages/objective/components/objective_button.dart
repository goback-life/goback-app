import 'package:cloudless/core/features/auth/domain/hooks/auth_navigation_flow.dart';
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/pages/objective/objective_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class ObjectiveButton extends HookConsumerWidget
    with MainLayout, ObjectiveLayout {
  const ObjectiveButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final objectiveResult = useAuthNavigationFlow(ref);

    return CallToAction.primary.filled(
      action: () {
        objectiveResult.markAsCompleted();
      },
      label: Text(
        translator.translate('pages.objective.button'),
        style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
      ),
    );
  }
}
