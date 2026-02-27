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

    // Resolve biography from the appropriate source. Provider watches are
    // registered unconditionally for each code-path so Riverpod tracks them.
    String? resolvedBio;
    bool isLoading = false;
    bool isError = false;

    if (biography != null) {
      resolvedBio = biography;
    } else if (profileId != null) {
      final profileAsync = ref.watch(getProfileProvider(profileId!));
      profileAsync.when(
        data: (result) => result.fold(
          (profile) => resolvedBio = profile?.biography,
          (error) {
            logger.error('Profile error', exception: error);
            isError = true;
          },
        ),
        loading: () => isLoading = true,
        error: (error, stack) {
          logger.error('Profile async error', exception: error);
          isError = true;
        },
      );
    } else {
      final currentUserAsync = ref.watch(getCurrentUserProvider);
      currentUserAsync.when(
        data: (userResult) => userResult.fold(
          (user) {
            final profileAsync = ref.watch(getProfileProvider(user.id));
            profileAsync.when(
              data: (result) => result.fold(
                (profile) => resolvedBio = profile?.biography,
                (error) {
                  logger.error('Profile error', exception: error);
                  isError = true;
                },
              ),
              loading: () => isLoading = true,
              error: (error, stack) {
                logger.error('Profile async error', exception: error);
                isError = true;
              },
            );
          },
          (error) {
            logger.error('User error', exception: error);
            isError = true;
          },
        ),
        loading: () => isLoading = true,
        error: (error, stack) {
          logger.error('User async error', exception: error);
          isError = true;
        },
      );
    }

    // Hook called unconditionally on every build (fixes hook ordering
    // violation that caused crashes when async state changed).
    final trimmedBio = resolvedBio?.trim();
    final exceedsMaxLines = useMemoized(() {
      if (trimmedBio == null || trimmedBio.isEmpty) return false;
      final painter = TextPainter(
        text: TextSpan(
          text: trimmedBio,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        ),
        maxLines: 2,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: MediaQuery.of(context).size.width - 32);
      return painter.didExceedMaxLines;
    }, [trimmedBio, textTheme.bodyMedium]);

    if (isLoading) return const SizedBox(height: 18);

    if (isError) {
      return Text(
        translator.translate('pages.profile.description.error'),
        textAlign: TextAlign.center,
        style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
      );
    }

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
                trimmedBio ?? '',
                textAlign: TextAlign.center,
                maxLines: showFullDescription || isExpanded.value ? null : 2,
                overflow: showFullDescription || isExpanded.value
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
            ),
            if (!showFullDescription && exceedsMaxLines)
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
