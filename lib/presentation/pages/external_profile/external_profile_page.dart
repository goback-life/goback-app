import 'package:cloudless/presentation/pages/external_profile/views/external_profile_view.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Non-friend profile page: only shows avatar, username, and bio.
/// No calendar, no hamburger menu, no profile options.
class ExternalProfilePage extends HookConsumerWidget with MainLayout {
  const ExternalProfilePage({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Back button (top-left)
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => router.pop(),
                behavior: HitTestBehavior.translucent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ExternalProfileView(userId: userId),
          ],
        ),
      ),
    );
  }
}
