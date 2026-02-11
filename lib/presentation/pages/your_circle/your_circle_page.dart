import 'package:cloudless/presentation/pages/your_circle/views/your_circle_view.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:flutter/material.dart';

class YourCirclePage extends StatelessWidget {
  const YourCirclePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: MainColors.dark,
      resizeToAvoidBottomInset: true,
      body: YourCircleView(),
    );
  }
}
