import 'package:cloudless/presentation/pages/external_profile/views/external_profile_view.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// Non-friend profile page: only shows avatar, username, and bio.
/// No calendar, no hamburger menu, no profile options.
class ExternalProfilePage extends HookConsumerWidget with MainLayout {
  const ExternalProfilePage({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: MainColors.dark,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Back button (top-left)
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.translucent,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: MainColors.white,
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
