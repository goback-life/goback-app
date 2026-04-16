import 'package:cloudless/presentation/components/goback_logo.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/pages/friends_locked_out/friends_locked_out_routable.dart';
import 'package:cloudless/presentation/pages/objective/objective_routable.dart';
import 'package:cloudless/presentation/pages/profile/profile_routable.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class HomeNavigationBar extends HookConsumerWidget with MainLayout, HomeLayout {
  const HomeNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          const Spacer(),
          GestureDetector(
            onTap: () => router.push(
              const ObjectiveRoutable(
                showBackButton: true,
                showBottomButton: false,
              ),
            ),
            child: const GobackLogo(fontSize: 20),
          ),
          const Spacer(),
          Row(
            children: [
              // Profile
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => router.push(const ProfileRoutable()),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: ProfileImage(
                      showFromProfile: true,
                      size: navProfileImageSize,
                    ),
                  ),
                ),
              ),
              // Lockouts
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => router.push(const FriendsLockedOutRoutable()),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(child: Icon(Icons.people_outline, size: 24)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
