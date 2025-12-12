import 'package:cloudless/presentation/pages/objective/components/objective_button.dart';
import 'package:cloudless/presentation/pages/objective/components/objective_description.dart';
import 'package:cloudless/presentation/pages/objective/objective_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/widgets/layout/bottomed_list_view.dart';
import 'package:flutter/material.dart';

class ObjectiveView extends HookConsumerWidget
    with MainLayout, ObjectiveLayout {
  const ObjectiveView({super.key, this.showBottomButton = true});

  final bool showBottomButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (showBottomButton) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: BottomedListView(
          useSafeArea: true,
          bottom: Padding(
            padding: EdgeInsets.only(bottom: bottomMargin),
            child: const ObjectiveButton(),
          ),
          children: [
            SizedBox(height: verticalSpacing),
            const ObjectiveDescription(),
            SizedBox(height: verticalSpacing * 2),
          ],
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              SizedBox(height: verticalSpacing),
              const ObjectiveDescription(),
              SizedBox(height: verticalSpacing * 2),
            ],
          ),
        ),
      );
    }
  }
}
