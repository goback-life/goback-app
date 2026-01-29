import 'package:cloudless/presentation/pages/home/components/home_navigation_bar.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/pages/home/views/home_view.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class HomePage extends HookConsumerWidget with MainLayout, HomeLayout {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: topMargin),
          const HomeNavigationBar(),
          SizedBox(height: titleToImage),
          const Expanded(child: HomeView()),
        ],
      ),
    );
  }
}
