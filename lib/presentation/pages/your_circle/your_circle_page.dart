import 'package:cloudless/presentation/pages/your_circle/views/your_circle_view.dart';
import 'package:flutter/material.dart';

class YourCirclePage extends StatelessWidget {
  const YourCirclePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: true,
      body: const YourCircleView(),
    );
  }
}
