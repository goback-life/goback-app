import 'package:cloudless/presentation/components/main_app_bar/main_app_bar.dart';
import 'package:cloudless/presentation/pages/objective/objective_layout.dart';
import 'package:cloudless/presentation/pages/objective/views/objective_view.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class ObjectivePage extends HookConsumerWidget
    with MainLayout, ObjectiveLayout {
  const ObjectivePage({
    super.key,
    this.showBackButton = false,
    this.showBottomButton = true,
  });

  final bool showBackButton;
  final bool showBottomButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topMargin),
          MainAppBar(title: translator.translate('pages.objective.title')),
          Expanded(child: ObjectiveView(showBottomButton: showBottomButton)),
        ],
      ),
    );
  }
}
