import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/notification/domain/hooks/use_unread_notification_count.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/goback_logo.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image.dart';
import 'package:cloudless/presentation/pages/home/components/home_time_limit_toggle.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/pages/friends_locked_out/friends_locked_out_routable.dart';
import 'package:cloudless/presentation/pages/notifications/notifications_routable.dart';
import 'package:cloudless/presentation/pages/objective/objective_routable.dart';
import 'package:cloudless/presentation/pages/profile/profile_routable.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_routable.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/material.dart';

class HomeNavigationBar extends HookConsumerWidget
    with MainLayout, HomeLayout {
  const HomeNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currentUserAsync = ref.watch(getCurrentUserProvider);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          const HomeTimeLimitToggle(),
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
              // Friends offline icon
              GestureDetector(
                onTap: () => router.push(const FriendsLockedOutRoutable()),
                child: SizedBox(
                  width: navCircleButtonSize,
                  height: navCircleButtonSize,
                  child: const Center(
                    child: Icon(Icons.people_outline, size: 24),
                  ),
                ),
              ),
              SizedBox(width: navButtonSpacing),
              // Notification icon with badge
              currentUserAsync.when(
                data: (userResult) {
                  return userResult.fold(
                    (user) {
                      final unreadCountAsync = useUnreadNotificationCount(
                        ref,
                        userId: user.id,
                      );

                      return unreadCountAsync.when(
                        data: (countResult) {
                          final unreadCount = countResult.fold(
                            (count) => count,
                            (_) => 0,
                          );

                          return GestureDetector(
                            onTap: () => router.push(
                              const NotificationsRoutable(),
                            ),
                            child: SizedBox(
                              width: navCircleButtonSize,
                              height: navCircleButtonSize,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Center(
                                    child: Assets.svg.notifications.render(colorFilter: colorScheme.onSurface.asSrcIn),
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: -2,
                                      top: -2,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: MainColors.accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                        loading: () => GestureDetector(
                          onTap: () => router.push(const NotificationsRoutable()),
                          child: SizedBox(
                            width: navCircleButtonSize,
                            height: navCircleButtonSize,
                            child: Center(
                              child: Assets.svg.notifications.render(colorFilter: colorScheme.onSurface.asSrcIn),
                            ),
                          ),
                        ),
                        error: (_, __) => GestureDetector(
                          onTap: () => router.push(const NotificationsRoutable()),
                          child: SizedBox(
                            width: navCircleButtonSize,
                            height: navCircleButtonSize,
                            child: Center(
                              child: Assets.svg.notifications.render(colorFilter: colorScheme.onSurface.asSrcIn),
                            ),
                          ),
                        ),
                      );
                    },
                    (_) => const SizedBox.shrink(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              SizedBox(width: navButtonSpacing),
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
