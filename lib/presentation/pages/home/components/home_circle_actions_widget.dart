import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/pages/your_circle/components/your_circle_invite_button.dart';
import 'package:cloudless/presentation/pages/your_circle/components/your_circle_join_button.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class HomeCircleActionsWidget extends HookConsumerWidget
    with MainLayout, HomeLayout, HomeLayout {
  const HomeCircleActionsWidget({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(getProfileProvider(userId));

    return profileAsync.when(
      data: (profileResult) {
        return profileResult.fold(
          (profile) {
            final username = profile?.username ?? '';
            final displayName = username.isNotEmpty ? username : '';

            return _buildEmptyCircleWidget(context, displayName);
          },
          (error) {
            return const SizedBox.shrink();
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyCircleWidget(BuildContext context, String username) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: actionsContainerVerticalPadding,
          horizontal: actionsContainerHorizontalPadding,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(actionsContainerBorderRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              translator.translate(
                'pages.home.no_circle_box.title',
                arguments: {'username': username},
              ),
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: actionsTitleToDescription),
            Text(
              translator.translate('pages.home.no_circle_box.description'),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: actionsDescriptionToButtons),
            Column(
              children: [
                const YourCircleInviteButton(),
                SizedBox(height: actionsBetweenButtons),
                const YourCircleJoinButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
