import 'dart:io';

import 'package:cloudless/core/features/media/domain/hooks/use_image_cropper.dart';
import 'package:cloudless/core/features/media_picker/data/providers/image_compress_service_provider.dart';
import 'package:cloudless/presentation/components/frame_picker/frame_picker.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Hook that handles the complete logic for showing the video frame picker,
/// cropping the selected image, and managing compression.
///
/// Returns a function that can be called to open the thumbnail picker
/// and calls the [onImageSelected] callback when an image is selected and cropped.
Future<void> Function() useThumbnailPicker({
  required WidgetRef ref,
  required String videoUrl,
  required ValueChanged<PickedFrame?> onImageSelected,
  required Duration initialPosition,
  bool enableCropping = true,
  CropType cropType = CropType.circle,
}) {
  final cropImage = useImageCropper();

  return () async {
    try {
      final PickedFramePath? pick = await FramePicker.show(
        context: ref.context,
        videoUrl: videoUrl,
        initialPosition: initialPosition,
      );

      if (pick == null) {
        throw Exception('Thumbnail generation failed');
      }

      final File? compressed = await ref
          .read(imageCompressServiceProvider)
          .compressImage(File(pick.path));

      if (compressed == null) {
        throw Exception('Compression failed');
      }

      // at this point we have the compressed image, we shouldn't throw errors anymore

      if (!enableCropping) {
        onImageSelected((file: compressed, position: pick.position));
        return;
      }

      try {
        final File? croppedFile = await cropImage(
          imagePath: compressed.path,
          cropType: cropType,
        );

        if (croppedFile != null) {
          onImageSelected((file: croppedFile, position: pick.position));
        } else {
          onImageSelected((file: compressed, position: pick.position));
        }
      } catch (e) {
        // if crop is canceled, just select the original uncropped compressed image
        onImageSelected((file: compressed, position: pick.position));
      }
    } catch (e) {
      logger.error('Error picking thumbnail', exception: e);
      onImageSelected(null);
    }
  };
}
