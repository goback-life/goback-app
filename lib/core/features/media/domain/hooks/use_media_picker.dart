import 'dart:io';

import 'package:cloudless/core/features/media/domain/enums/media_type.dart';
import 'package:cloudless/presentation/components/alerts/main_snackbar.dart';
import 'package:video_player/video_player.dart';
import 'package:cloudless/core/features/media/domain/enums/pick_image_type.dart';
import 'package:cloudless/core/features/media/domain/hooks/use_image_cropper.dart';
import 'package:cloudless/core/features/media/domain/hooks/use_pick_and_compress_image_with_permission.dart';
import 'package:cloudless/core/features/post/domain/models/parent_post_reference_model.dart';
import 'package:cloudless/presentation/components/sheets/content_type_picker_sheet.dart';
import 'package:cloudless/presentation/components/sheets/media_source_picker_sheet.dart';
import 'package:cloudless/presentation/components/sheets/media_type_picker_sheet.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Hook that manages the complete logic for selecting media (photo/video) or text.
///
/// First shows a sheet to select content type (media/text),
/// then if media is selected, shows a sheet to select the media type (photo/video),
/// then a second sheet to select the source (camera/library).
///
/// Returns a function that can be called to open the picker
/// and calls the [onMediaSelected] callback when a media is selected.
/// For text posts, calls [onMediaSelected] with null to indicate text mode.
///
/// For photos, applies cropping if [enableCropping] is true.
/// For videos, cropping is ignored.
///
/// If [forceMediaType] is specified, skips the content type and media type selection
/// and uses the specified one directly (useful in post edit mode).
///
/// If [skipContentTypePicker] is true, skips the content type picker (Media/Text)
/// and goes directly to the media type picker (Photo/Video).
///
/// If [parentPost] is provided, it will be displayed in the picker sheets
/// to show the context of the reply being created.
///
/// [loadingNotifier] is set to true immediately when the user selects a source
/// (camera/library), before the media picker is opened, and set to false after
/// the media is processed and navigation is complete.
Future<void> Function() useMediaPicker({
  required WidgetRef ref,
  required Future<void> Function(File?) onMediaSelected,
  ValueNotifier<bool>? loadingNotifier,
  bool enableCropping = true,
  CropType cropType = CropType.circle,
  MediaType? forceMediaType,
  bool skipContentTypePicker = false,
  ParentPostReferenceModel? parentPost,
}) {
  final pickAndCompressImage = usePickAndCompressImageWithPermission();
  final cropImage = useImageCropper();

  return () async {
    try {
      // Show content type picker (Media vs Text) unless skipped
      if (!skipContentTypePicker) {
        if (!ref.context.mounted) {
          return;
        }
        final contentTypeSelection = await ContentTypePickerSheet.show(
          ref.context,
          parentPost: parentPost,
        );
        if (contentTypeSelection == null) {
          return;
        }

        // If text is selected, trigger text mode
        if (contentTypeSelection == ContentTypeSelection.text) {
          await onMediaSelected(null);
          return;
        }
      }

      // Continue with media selection flow (Photo/Video)
      final MediaType? mediaType;
      if (forceMediaType != null) {
        mediaType = forceMediaType;
      } else {
        if (!ref.context.mounted) {
          return;
        }
        mediaType = await MediaTypePickerSheet.show(
          ref.context,
          parentPost: parentPost,
        );
        if (mediaType == null) {
          return;
        }
      }

      if (!ref.context.mounted) {
        return;
      }
      final imageSource = await MediaSourcePickerSheet.show(
        ref.context,
        mediaType: mediaType,
        parentPost: parentPost,
      );

      if (imageSource == null) {
        return;
      }

      loadingNotifier?.value = true;

      try {
        if (mediaType == MediaType.photo) {
          await _handlePhotoSelection(
            ref: ref,
            imageSource: imageSource,
            pickAndCompressImage: pickAndCompressImage,
            cropImage: cropImage,
            enableCropping: enableCropping,
            cropType: cropType,
            onMediaSelected: onMediaSelected,
          );
        } else {
          await _handleVideoSelection(
            ref: ref,
            imageSource: imageSource,
            onMediaSelected: onMediaSelected,
          );
        }
      } finally {
        loadingNotifier?.value = false;
      }
    } catch (e) {
      // Handle error silently or show a toast
      loadingNotifier?.value = false;
    }
  };
}

/// Handles photo selection with proper permission handling
Future<void> _handlePhotoSelection({
  required WidgetRef ref,
  required ImageSource imageSource,
  required FutureResult<File> Function({
    required WidgetRef ref,
    required PickImageType pickImageType,
  })
  pickAndCompressImage,
  required Future<File?> Function({
    required String imagePath,
    required CropType cropType,
  })
  cropImage,
  required bool enableCropping,
  required CropType cropType,
  required Future<void> Function(File?) onMediaSelected,
}) async {
  try {
    final result = await pickAndCompressImage(
      ref: ref,
      pickImageType: PickImageType.values.firstWhere(
        (type) => type.name == imageSource.name,
      ),
    );

    result.fold(
      (file) async {
        if (enableCropping) {
          try {
            final croppedFile = await cropImage(
              imagePath: file.path,
              cropType: cropType,
            );

            if (croppedFile != null) {
              await onMediaSelected(croppedFile);
            }
          } catch (e) {
            await onMediaSelected(file);
          }
        } else {
          await onMediaSelected(file);
        }
      },
      (error) {
        // Permission denied or other error - handled by pickAndCompressImage
      },
    );
  } catch (e) {
    // Handle any unexpected errors silently
  }
}

/// Maximum allowed video duration in seconds (60 seconds = 1 minute)
const _maxVideoDurationSeconds = 60;

/// Handles video selection with duration validation
Future<void> _handleVideoSelection({
  required WidgetRef ref,
  required ImageSource imageSource,
  required Future<void> Function(File?) onMediaSelected,
}) async {
  try {
    final picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: imageSource);

    if (video == null) return;

    final file = File(video.path);

    // Validate video duration before accepting
    final duration = await _getVideoDuration(file);
    if (duration != null && duration.inSeconds > _maxVideoDurationSeconds) {
      // Show error to user - video too long
      if (ref.context.mounted) {
        MainSnackbar.showError(
          ref.context,
          'Videos must be 60 seconds or less',
        );
      }
      return;
    }

    await onMediaSelected(file);
  } catch (e) {
    // Handle permission denied or other errors silently
  }
}

/// Gets the duration of a video file.
/// Returns null if duration cannot be determined.
Future<Duration?> _getVideoDuration(File videoFile) async {
  VideoPlayerController? controller;
  try {
    controller = VideoPlayerController.file(videoFile);
    await controller.initialize();
    return controller.value.duration;
  } catch (e) {
    // Return null if we can't determine duration (allow the video)
    return null;
  } finally {
    await controller?.dispose();
  }
}
