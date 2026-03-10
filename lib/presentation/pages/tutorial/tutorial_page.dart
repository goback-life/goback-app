import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/pages/tutorial/views/tutorial_view.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class TutorialPage extends HookConsumerWidget {
  const TutorialPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppGlassLayer(
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: MainColors.dark,
          body: const TutorialView(),
        ),
      ),
    );
  }
}
