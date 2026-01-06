import 'dart:io';

import 'package:cloudless/core/features/media/domain/hooks/use_image_cropper.dart';
import 'package:cloudless/core/features/media/domain/hooks/use_media_picker.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/features/post/domain/models/parent_post_reference_model.dart';
import 'package:cloudless/core/features/post/domain/providers/post_creation_notifier_provider.dart';
import 'package:cloudless/core/utilities/video_thumbnail_helper.dart';
import 'package:cloudless/presentation/components/alerts/main_snackbar.dart';
import 'package:cloudless/presentation/pages/content_editor/content_editor_routable.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

typedef PostCreationInitializationResult = ({
  bool isInitialized,
  VoidCallback selectMainImage,
  VoidCallback resetCreation,
});

PostCreationInitializationResult usePostCreationInitialization(
  WidgetRef ref, {
  ParentPostReferenceModel? parentPost,
  VoidCallback? onNavigateToEditor,
  ValueNotifier<bool>? loadingNotifier,
}) {
  final postCreationState = ref.watch(postCreationNotifierProvider);
  final postCreationNotifier = ref.read(postCreationNotifierProvider.notifier);

  final selectMedia = useMediaPicker(
    ref: ref,
    parentPost: parentPost,
    loadingNotifier: loadingNotifier,
    onMediaSelected: (File? file) async {
      // If file is null, it means text was selected
      if (file == null) {
        // Initialize text post mode
        postCreationNotifier.updateContentType(ContentType.text);
        onNavigateToEditor?.call();

        if (ref.context.mounted) {
          await router.push(const ContentEditorRoutable());
        }
        return;
      }

      // Handle media selection (photo/video)
      final isVideo =
          file.path.toLowerCase().endsWith('.mp4') ||
          file.path.toLowerCase().endsWith('.mov');

      if (isVideo) {
        postCreationNotifier.updateImage(file);

        final firstFrame = await VideoThumbnailHelper.extractThumbnail(file);

        postCreationNotifier.updateFirstFrame(firstFrame);
      } else {
        postCreationNotifier.updateImage(file);
      }

      onNavigateToEditor?.call();

      if (ref.context.mounted) {
        await router.push(const ContentEditorRoutable());
      }
    },
    enableCropping: true,
    cropType: CropType.content,
  );

  void resetCreation() {
    postCreationNotifier.reset();
  }

  void selectMainImage() async {
    try {
      await selectMedia();
    } catch (e) {
      if (ref.context.mounted) {
        MainSnackbar.showError(
          ref.context,
          translator.translate('components.alert.image_selection_error'),
        );
      }
    }
  }

  // For text posts, initialization is complete when description is set
  // For media posts, initialization is complete when main image is set
  final isInitialized = postCreationState.contentType == ContentType.text
      ? postCreationState.description.isNotEmpty
      : postCreationState.hasMainImage;

  return (
    isInitialized: isInitialized,
    selectMainImage: selectMainImage,
    resetCreation: resetCreation,
  );
}
