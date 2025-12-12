import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class ProfileDescription extends HookConsumerWidget {
  const ProfileDescription({
    super.key,
    this.showFullDescription = false,
    this.biography,
    this.profileId,
  });

  final bool showFullDescription;
  final String? biography;
  final String? profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isExpanded = useState(false);

    if (biography != null) {
      return _buildDescriptionDisplay(
        context,
        textTheme,
        colorScheme,
        biography,
        isExpanded,
      );
    }

    if (profileId != null) {
      final profileAsync = ref.watch(getProfileProvider(profileId!));

      return profileAsync.when(
        data: (profileResult) {
          return profileResult.fold(
            (profile) {
              return _buildDescriptionDisplay(
                context,
                textTheme,
                colorScheme,
                profile?.biography,
                isExpanded,
              );
            },
            (error) {
              logger.error('Profile error', exception: error);
              return Text(
                translator.translate('pages.profile.description.error'),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
              );
            },
          );
        },
        loading: () => const SizedBox(height: 18),
        error: (error, stack) {
          logger.error('Profile async error', exception: error);
          return Text(
            translator.translate('pages.profile.description.error'),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
          );
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
                    return _buildDescriptionDisplay(
                      context,
                      textTheme,
                      colorScheme,
                      profile?.biography,
                      isExpanded,
                    );
                  },
                  (error) {
                    logger.error('Profile error', exception: error);
                    return Text(
                      translator.translate('pages.profile.description.error'),
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                    );
                  },
                );
              },
              loading: () => const SizedBox(height: 18),
              error: (error, stack) {
                logger.error('Profile async error', exception: error);
                return Text(
                  translator.translate('pages.profile.description.error'),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                );
              },
            );
          },
          (error) {
            logger.error('User error', exception: error);
            return Text(
              translator.translate('pages.profile.description.error'),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
            );
          },
        );
      },
      loading: () => const SizedBox(height: 18),
      error: (error, stack) {
        logger.error('User async error', exception: error);
        return Text(
          translator.translate('pages.profile.description.error'),
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
        );
      },
    );
  }

  Widget _buildDescriptionDisplay(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
    String? displayBiography,
    ValueNotifier<bool> isExpanded,
  ) {
    final biography = displayBiography?.trim();

    final textPainter = useMemoized(() {
      final painter = TextPainter(
        text: TextSpan(
          text: biography,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        ),
        maxLines: 2,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: MediaQuery.of(context).size.width - 32);
      return painter.didExceedMaxLines;
    }, [biography, textTheme.bodyMedium]);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: showFullDescription
            ? null
            : () {
                isExpanded.value = !isExpanded.value;
              },
        child: Column(
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              style:
                  textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ) ??
                  const TextStyle(),
              child: Text(
                biography ?? '',
                textAlign: TextAlign.center,
                maxLines: showFullDescription || isExpanded.value ? null : 2,
                overflow: showFullDescription || isExpanded.value
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
            ),
            if (!showFullDescription && textPainter)
              Center(
                child: Icon(
                  isExpanded.value
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
