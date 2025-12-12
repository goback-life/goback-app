import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_post_creation_initialization.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/presentation/pages/home/components/home_content_editor_button.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class HomeFeedEmptyState extends HookConsumerWidget
    with MainLayout, HomeLayout {
  const HomeFeedEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final postCreationInitialization = usePostCreationInitialization(ref);
    final currentUserAsync = ref.watch(getCurrentUserProvider);

    return Container(
      height: 215,
      padding: EdgeInsets.symmetric(
        vertical: actionsContainerVerticalPadding,
        horizontal: actionsContainerHorizontalPadding,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(actionsContainerBorderRadius),
      ),
      child: Column(
        children: [
          currentUserAsync.when(
            data: (userResult) {
              return userResult.fold(
                (user) {
                  final profileAsync = ref.watch(getProfileProvider(user.id));

                  return profileAsync.when(
                    data: (profileResult) {
                      return profileResult.fold(
                        (profile) {
                          final username = profile?.username ?? '';
                          final displayName = username.isNotEmpty
                              ? username
                              : '';

                          return Text(
                            translator.translate(
                              'pages.home.feed_empty_box.title',
                              arguments: {'username': displayName},
                            ),
                            style: textTheme.titleLarge?.copyWith(
                              color: colorScheme.secondary,
                            ),
                            textAlign: TextAlign.center,
                          );
                        },
                        (error) {
                          return const SizedBox.shrink();
                        },
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (error, _) => const SizedBox.shrink(),
                  );
                },
                (error) {
                  return const SizedBox.shrink();
                },
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, _) => const SizedBox.shrink(),
          ),
          SizedBox(height: actionsTitleToDescription),
          Text(
            translator.translate('pages.home.feed_empty_box.description'),
            style: textTheme.bodyMedium?.copyWith(),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: actionsDescriptionToButtons),
          HomeContentEditorButton(
            onTap: postCreationInitialization.selectMainImage,
          ),
        ],
      ),
    );
  }
}
