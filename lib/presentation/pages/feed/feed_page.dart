import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/pages/feed/views/feed_view.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// V1 feed page — chat-style staggered layout with glass overlays.
///
/// Wraps [FeedView] in an [AppGlassLayer] for shader compositing
/// and sets the dark (#1A1A1A) background.
class FeedPage extends HookConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppGlassLayer(
      child: Scaffold(
        backgroundColor: MainColors.dark,
        body: const FeedView(),
      ),
    );
  }
}
