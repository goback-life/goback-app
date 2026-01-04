import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image.dart';
import 'package:cloudless/presentation/pages/home/components/home_go_back_button.dart';
import 'package:cloudless/presentation/pages/home/components/home_time_limit_toggle.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/pages/objective/objective_routable.dart';
import 'package:cloudless/presentation/pages/profile/profile_routable.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_routable.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class HomeNavigationBar extends StatelessWidget with MainLayout, HomeLayout {
  const HomeNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          const HomeTimeLimitToggle(),
          SizedBox(width: navButtonSpacing),
          const HomeGoBackButton(),
          const Spacer(),
          GestureDetector(
            onTap: () => router.push(
              const ObjectiveRoutable(
                showBackButton: true,
                showBottomButton: false,
              ),
            ),
            child: Assets.svg.logoApp.render(),
          ),
          const Spacer(),
          Row(
            children: [
              GestureDetector(
                onTap: () => router.push(const ProfileRoutable()),
                child: ProfileImage(
                  showFromProfile: true,
                  size: navProfileImageSize,
                ),
              ),
              SizedBox(width: navButtonSpacing),
              GestureDetector(
                onTap: () => router.push(const YourCircleRoutable()),
                child: SizedBox(
                  width: navCircleButtonSize,
                  height: navCircleButtonSize,
                  child: Assets.svg.yourCircle.render(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
