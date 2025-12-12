import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/media/domain/hooks/use_image_picker.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/full_screen_image.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/material.dart';

class ProfileImage extends HookConsumerWidget
    with MainLayout, ProfileImageLayout {
  const ProfileImage({
    super.key,
    this.imageFile,
    this.imageUrl,
    this.username,
    this.onImageSelected,
    this.isEditable = false,
    this.showFromProfile = false,
    this.showFullScreen = false,
    this.showLoading = true,
    this.size,
  });

  final File? imageFile;
  final String? imageUrl;
  final String? username;
  final ValueChanged<File?>? onImageSelected;
  final bool isEditable;
  final bool showFromProfile;
  final bool showFullScreen;
  final bool showLoading;
  final double? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (showFromProfile) {
      return _buildProfileImageFromUser(context, ref, colorScheme);
    }

    return _buildEditableImage(context, colorScheme, ref);
  }

  Widget _buildProfileImageFromUser(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    final currentUserAsync = ref.watch(getCurrentUserProvider);

    return currentUserAsync.when(
      data: (userResult) {
        return userResult.fold((user) {
          final profileAsync = ref.watch(getProfileProvider(user.id));

          return profileAsync.when(
            data: (profileResult) {
              return profileResult.fold(
                (profile) {
                  return _buildImageStack(
                    context,
                    colorScheme,
                    avatarUrl: profile?.avatarUrl,
                    username: profile?.username,
                    isLoading: false,
                  );
                },
                (error) {
                  return _buildImageStack(
                    context,
                    colorScheme,
                    isLoading: false,
                  );
                },
              );
            },
            loading: () =>
                _buildImageStack(context, colorScheme, isLoading: showLoading),
            error: (error, __) {
              return _buildImageStack(context, colorScheme, isLoading: false);
            },
          );
        }, (error) => _buildImageStack(context, colorScheme, isLoading: false));
      },
      loading: () =>
          _buildImageStack(context, colorScheme, isLoading: showLoading),
      error: (error, __) {
        return _buildImageStack(context, colorScheme, isLoading: false);
      },
    );
  }

  Widget _buildEditableImage(
    BuildContext context,
    ColorScheme colorScheme,
    WidgetRef ref,
  ) {
    return _buildImageStack(
      context,
      colorScheme,
      imageFile: imageFile,
      imageUrl: imageUrl,
      username: username,
      isLoading: false,
      ref: ref,
    );
  }

  Widget _buildImageStack(
    BuildContext context,
    ColorScheme colorScheme, {
    File? imageFile,
    String? avatarUrl,
    String? username,
    String? imageUrl,
    bool isLoading = false,
    WidgetRef? ref,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final actualSize = size ?? imageSize;

    Widget topWidget;
    ImageProvider? imageProvider;

    if (imageFile != null) {
      imageProvider = FileImage(imageFile);
      topWidget = ClipOval(
        child: Image.file(
          imageFile,
          width: actualSize,
          height: actualSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      );
    } else if (avatarUrl != null && avatarUrl.isNotEmpty) {
      imageProvider = CachedNetworkImageProvider(avatarUrl);
      topWidget = ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: actualSize,
          height: actualSize,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 100),
          memCacheWidth: (actualSize * 2).toInt(),
          memCacheHeight: (actualSize * 2).toInt(),
          placeholder: (context, url) => Container(
            width: actualSize,
            height: actualSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primaryContainer.withValues(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: actualSize,
            height: actualSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primaryContainer.withValues(),
            ),
          ),
        ),
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      imageProvider = CachedNetworkImageProvider(imageUrl);
      topWidget = ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: actualSize,
          height: actualSize,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 100),
          memCacheWidth: (actualSize * 2).toInt(),
          memCacheHeight: (actualSize * 2).toInt(),
          placeholder: (context, url) => Container(
            width: actualSize,
            height: actualSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primaryContainer.withValues(
                alpha: loadingOpacity,
              ),
            ),
          ),
          errorWidget: (context, url, error) => const SizedBox.shrink(),
        ),
      );
    } else if (username != null && username.isNotEmpty) {
      topWidget = Container(
        width: actualSize,
        height: actualSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.primaryContainer,
          border: Border.all(color: colorScheme.primary, width: borderWidth),
        ),
        child: Center(
          child: Text(
            username[0].toUpperCase(),
            style: _getFallbackTextStyle(textTheme, colorScheme, actualSize),
          ),
        ),
      );
    } else {
      topWidget = Container(
        width: actualSize,
        height: actualSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.primaryContainer.withValues(alpha: loadingOpacity),
          border: Border.all(color: colorScheme.primary, width: borderWidth),
        ),
        child: Center(
          child: Assets.svg.camera.render(
            colorFilter: colorScheme.primaryContainer
                .withValues(alpha: loadingOpacity)
                .asSrcIn,
            width: actualSize * iconSizeRatio,
            height: actualSize * iconSizeRatio,
          ),
        ),
      );
    }

    if (!isLoading) {
      return _wrapWithGestureDetector(
        context,
        SizedBox(width: actualSize, height: actualSize, child: topWidget),
        imageProvider,
        ref: ref,
      );
    }

    final stackWidget = SizedBox(
      width: actualSize,
      height: actualSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: actualSize,
            height: actualSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primaryContainer.withValues(
                alpha: loadingOpacity,
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: colorScheme.primaryContainer,
                strokeWidth: loadingStrokeWidth,
              ),
            ),
          ),
          topWidget,
        ],
      ),
    );

    return _wrapWithGestureDetector(
      context,
      stackWidget,
      imageProvider,
      ref: ref,
    );
  }

  TextStyle _getFallbackTextStyle(
    TextTheme textTheme,
    ColorScheme colorScheme,
    double actualSize,
  ) {
    double fontSize;
    if (actualSize <= smallImageThreshold) {
      fontSize = actualSize * fallbackFontSizeRatio;
    } else {
      fontSize =
          textTheme.displayMedium?.fontSize ??
          actualSize * fallbackFontSizeRatioLarge;
    }

    return TextStyle(
      color: colorScheme.primary,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    );
  }

  Widget _wrapWithGestureDetector(
    BuildContext context,
    Widget child,
    ImageProvider? imageProvider, {
    WidgetRef? ref,
  }) {
    if (isEditable && ref != null && onImageSelected != null) {
      final showImagePicker = useImagePicker(
        ref: ref,
        onImageSelected: onImageSelected!,
      );
      return GestureDetector(onTap: showImagePicker, child: child);
    } else if (showFullScreen && imageProvider != null) {
      return GestureDetector(
        onTap: () => _openFullScreenImage(context, imageProvider),
        child: child,
      );
    }
    return child;
  }

  void _openFullScreenImage(BuildContext context, ImageProvider imageProvider) {
    FullScreenImage.show(context: context, image: imageProvider);
  }
}
