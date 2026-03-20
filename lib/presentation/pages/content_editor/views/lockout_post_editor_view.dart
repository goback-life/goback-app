import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/lockout/domain/providers/pending_lockout_post_provider.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_post_creation.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/core/features/share/domain/providers/pending_share_provider.dart';
import 'package:cloudless/presentation/components/squircle_clipper.dart';
import 'package:cloudless/presentation/pages/home/home_routable.dart';
import 'package:cloudless/presentation/pages/visibility_selection/visibility_selection_routable.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/hooks/use_loading_overlay.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Post creation view for lockout flow: glass card with squircle preview,
/// avatar + username, optional description, and direct Share button.
///
/// Matches Figma node 157:113. Publishes directly to full circle
/// (no member selection screen).
class LockoutPostEditorView extends HookConsumerWidget {
  const LockoutPostEditorView({
    required this.contentCreation,
    super.key,
  });

  final PostCreationResult contentCreation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final s = screenWidth / 402.0;

    final isProcessing = useState<bool>(false);
    useLoadingOverlay(isProcessing, context: context);

    // Get current user profile for avatar + username
    final currentUser = ref.watch(getCurrentUserProvider);
    final userId = currentUser.whenOrNull(
      data: (r) => r.fold((u) => u.id, (_) => null),
    );
    final profileAsync =
        userId != null ? ref.watch(getProfileProvider(userId)) : null;

    final username = profileAsync?.whenOrNull(
          data: (r) => r.fold((p) => p?.username, (_) => null),
        ) ??
        '';
    final avatarUrl = profileAsync?.whenOrNull(
          data: (r) => r.fold((p) => p?.avatarUrl, (_) => null),
        );

    // Watch circle members for total count (used by restrict visibility)
    final circleMembersAsync = ref.watch(getCircleMembersProvider);
    final totalMemberCount = circleMembersAsync.whenOrNull(
          data: (r) => r.fold((members) => members.length, (_) => 0),
        ) ??
        0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Semi-transparent overlay background
          Container(
            color: const Color(0x33D9D9D9), // rgba(217,217,217,0.2)
          ),

          // Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 18 * s,
                vertical: 24 * s,
              ),
              child: Column(
                children: [
                  SizedBox(height: 80 * s),

                  // Glass card
                  AppGlassContainer(
                    config: const GlassConfig(cornerRadius: 47),
                    child: Container(
                      width: 371 * s,
                      padding: EdgeInsets.symmetric(
                        horizontal: 38 * s,
                        vertical: 37 * s,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Squircle photo preview
                          Center(
                            child: SizedBox(
                              width: 296 * s,
                              height: 296 * s,
                              child: ClipSquircle(
                                child: _buildMediaPreview(),
                              ),
                            ),
                          ),

                          SizedBox(height: 17 * s),

                          // Avatar + username row
                          _AvatarRow(
                            username: username,
                            avatarUrl: avatarUrl,
                            scale: s,
                          ),

                          SizedBox(height: 8 * s),

                          // Description input
                          _DescriptionInput(
                            initialText: contentCreation.data.description,
                            onChanged: contentCreation.updateDescription,
                            scale: s,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 32 * s),

                  // Share button (glass with accent tint)
                  _ShareButton(
                    canPublish:
                        contentCreation.canPublish && !isProcessing.value,
                    scale: s,
                    onTap: () => _handlePublish(
                      context,
                      ref,
                      contentCreation,
                      isProcessing,
                    ),
                  ),

                  SizedBox(height: 14 * s),

                  // Restrict visibility link
                  _RestrictVisibilityLink(
                    visibleCount: totalMemberCount -
                        contentCreation.data.excludedUserIds.length,
                    hasExclusions:
                        contentCreation.data.excludedUserIds.isNotEmpty,
                    scale: s,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    final isVideo = contentCreation.data.isVideo;

    if (isVideo && contentCreation.data.firstFrame != null) {
      return Image.file(contentCreation.data.firstFrame!, fit: BoxFit.cover);
    }

    if (contentCreation.mainImage != null) {
      return Image.file(contentCreation.mainImage!, fit: BoxFit.cover);
    }

    if (contentCreation.data.existingImageUrl != null) {
      return CachedNetworkImage(
        imageUrl: contentCreation.data.existingImageUrl!,
        fit: BoxFit.cover,
      );
    }

    return Container(color: MainColors.dark);
  }

  Future<void> _handlePublish(
    BuildContext context,
    WidgetRef ref,
    PostCreationResult contentCreation,
    ValueNotifier<bool> isProcessing,
  ) async {
    if (isProcessing.value) return;
    isProcessing.value = true;

    // Capture EVERYTHING before publish — lockout cleanup inside the hook
    // disposes this widget (and its ref) before the call returns.
    final shareNotifier = ref.read(pendingShareProvider.notifier);
    final lockoutId = ref.read(pendingLockoutPostProvider);
    final userId = ref.read(getCurrentUserProvider).whenOrNull(
      data: (r) => r.fold((u) => u.id, (_) => null),
    );
    final imagePath = contentCreation.data.firstFrame?.path ??
        contentCreation.mainImage?.path;
    final description = contentCreation.data.description;

    final result = await contentCreation.publishPostWithExclusions(
      contentCreation.data.excludedUserIds,
    );

    if (context.mounted) isProcessing.value = false;

    if (result != null) {
      final succeeded = result.fold((_) => true, (_) => false);
      if (succeeded && lockoutId != null && userId != null) {
        shareNotifier.state = (
          lockoutId: lockoutId,
          authorId: userId,
          imagePath: imagePath,
          description: description,
        );
      }
      result.fold(
        (_) => router.go(const HomeRoutable()),
        (error) {
          if (!context.mounted) return;
          MainAlert.showError(
            context: context,
            title: translator.translate(
              'components.alert.post_error.title',
            ),
            content: translator.translate(
              'components.alert.post_error.error_message',
            ),
          );
        },
      );
    }
  }
}

/// Avatar circle + username text.
class _AvatarRow extends StatelessWidget {
  const _AvatarRow({
    required this.username,
    required this.avatarUrl,
    required this.scale,
  });

  final String username;
  final String? avatarUrl;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final avatarSize = 39 * scale;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: avatarSize,
          height: avatarSize,
          child: ClipOval(
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: avatarUrl!,
                    fit: BoxFit.cover,
                    width: avatarSize,
                    height: avatarSize,
                    placeholder: (_, __) =>
                        Container(color: MainColors.dark),
                    errorWidget: (_, __, ___) =>
                        Container(color: MainColors.dark),
                  )
                : Container(color: MainColors.dark),
          ),
        ),
        SizedBox(width: 10 * scale),
        Text(
          username,
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w500,
            fontSize: 24 * scale,
            color: MainColors.dark,
            letterSpacing: -1.44 * scale,
          ),
        ),
      ],
    );
  }
}

/// Minimal description text field matching Figma 157:142.
class _DescriptionInput extends HookWidget {
  const _DescriptionInput({
    required this.initialText,
    required this.onChanged,
    required this.scale,
  });

  final String initialText;
  final ValueChanged<String> onChanged;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: initialText);
    final currentChars = useState(initialText.length);
    const maxLength = 200;

    useEffect(() {
      void listener() {
        currentChars.value = controller.text.length;
        onChanged(controller.text);
      }
      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 5,
          minLines: 1,
          maxLength: maxLength,
          onTapOutside: (event) => FocusScope.of(context).unfocus(),
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w400,
            fontSize: 15 * scale,
            color: MainColors.dark,
            letterSpacing: -0.9 * scale,
          ),
          decoration: InputDecoration(
            hintText: translator.translate(
              'pages.content_editor.hint_text',
            ),
            hintStyle: TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontWeight: FontWeight.w400,
              fontSize: 15 * scale,
              color: MainColors.dark.withValues(alpha: 0.4),
              letterSpacing: -0.9 * scale,
            ),
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
        ),
        if (currentChars.value >= (maxLength * 0.75).round())
          Text(
            '${currentChars.value}/$maxLength',
            style: TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontSize: 12 * scale,
              color: MainColors.dark.withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }
}

/// Glass Share button with accent tint.
class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.canPublish,
    required this.scale,
    required this.onTap,
  });

  final bool canPublish;
  final double scale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canPublish ? onTap : null,
      child: Opacity(
        opacity: canPublish ? 1.0 : 0.5,
        child: AppGlassContainer(
          config: const GlassConfig(
            cornerRadius: 47,
            interactive: true,
            tint: MainColors.accent,
          ),
          child: Container(
            width: 231 * scale,
            height: 51 * scale,
            alignment: Alignment.center,
            child: Text(
              'Share',
              style: TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontWeight: FontWeight.w500,
                fontSize: 24 * scale,
                color: MainColors.dark,
                letterSpacing: -1.44 * scale,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tappable text below Share that opens the visibility selection page.
class _RestrictVisibilityLink extends StatelessWidget {
  const _RestrictVisibilityLink({
    required this.visibleCount,
    required this.hasExclusions,
    required this.scale,
  });

  final int visibleCount;
  final bool hasExclusions;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final text = hasExclusions
        ? translator.translate(
            'pages.content_editor.restrict_visibility.restricted_count',
            arguments: {'count': visibleCount.toString()},
          )
        : translator.translate(
            'pages.content_editor.restrict_visibility.label',
          );

    return GestureDetector(
      onTap: () => router.push(const VisibilitySelectionRoutable()),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4 * scale),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w400,
            fontSize: 14 * scale,
            color: MainColors.dark.withValues(
              alpha: hasExclusions ? 0.8 : 0.6,
            ),
            letterSpacing: -0.84 * scale,
          ),
        ),
      ),
    );
  }
}
