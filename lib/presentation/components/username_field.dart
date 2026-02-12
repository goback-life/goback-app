import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/presentation/pages/profile/profile_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class UsernameField extends HookConsumerWidget with MainLayout, ProfileLayout {
  const UsernameField({
    super.key,
    this.loadingText,
    this.loadingTextStyle,
    this.username,
    this.profileId,
  });

  final String? loadingText;
  final TextStyle? loadingTextStyle;
  final String? username;
  final String? profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (username != null) {
      return _buildUsernameText(
        context,
        username!.isNotEmpty ? '@$username' : '',
        isPlaceholder: username!.isEmpty,
      );
    }

    if (profileId != null) {
      final profileAsync = ref.watch(getProfileProvider(profileId!));

      return profileAsync.when(
        data: (profileResult) {
          return profileResult.fold(
            (profile) {
              final profileUsername = profile?.username;
              return _buildUsernameText(
                context,
                profileUsername?.isNotEmpty == true ? '@$profileUsername' : '',
                isPlaceholder: profileUsername?.isNotEmpty != true,
              );
            },
            (error) {
              logger.error('Profile error', exception: error);
              return _buildErrorText(context);
            },
          );
        },
        loading: () => _buildLoadingText(context),
        error: (error, stack) {
          logger.error('Profile async error', exception: error);
          return _buildErrorText(context);
        },
      );
    }

    final currentUserAsync = ref.watch(getCurrentUserProvider);

    return currentUserAsync.when(
      data: (userResult) {
        return userResult.fold(
          (user) {
            final profileAsync = ref.watch(getProfileProvider(user.id));

            return profileAsync.when(
              data: (profileResult) {
                return profileResult.fold(
                  (profile) {
                    final profileUsername = profile?.username;

                    return _buildUsernameText(
                      context,
                      profileUsername?.isNotEmpty == true
                          ? '@$profileUsername'
                          : '',
                      isPlaceholder: profileUsername?.isNotEmpty != true,
                    );
                  },
                  (error) {
                    logger.error('Profile error', exception: error);
                    return _buildErrorText(context);
                  },
                );
              },
              loading: () => _buildLoadingText(context),
              error: (error, stack) {
                logger.error('Profile async error', exception: error);
                return _buildErrorText(context);
              },
            );
          },
          (error) {
            logger.error('User error', exception: error);
            return _buildErrorText(context);
          },
        );
      },
      loading: () => _buildLoadingText(context),
      error: (error, stack) {
        logger.error('User async error', exception: error);
        return _buildErrorText(context);
      },
    );
  }

  Widget _buildUsernameText(
    BuildContext context,
    String text, {
    bool isPlaceholder = false,
    bool isError = false,
    bool isLoading = false,
    TextStyle? customStyle,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    Color textColor;
    if (isError) {
      textColor = colorScheme.error;
    } else if (isPlaceholder || isLoading) {
      textColor = colorScheme.onSurface.withValues(alpha: 0.6);
    } else {
      textColor = colorScheme.onSurface;
    }

    final TextStyle defaultStyle =
        textTheme.titleLarge?.copyWith(color: textColor) ?? const TextStyle();

    return Text(
      text,
      textAlign: TextAlign.center,
      style: customStyle ?? defaultStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildErrorText(BuildContext context) {
    return _buildUsernameText(
      context,
      translator.translate('pages.profile.username.error'),
      isError: true,
    );
  }

  Widget _buildLoadingText(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final displayText =
        loadingText ?? translator.translate('pages.profile.username.loading');

    final defaultLoadingStyle = textTheme.titleLarge?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.5),
    );

    return _buildUsernameText(
      context,
      displayText,
      isLoading: true,
      customStyle: loadingTextStyle ?? defaultLoadingStyle,
    );
  }
}
