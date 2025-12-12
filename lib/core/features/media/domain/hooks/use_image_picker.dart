import 'dart:io';

import 'package:cloudless/core/features/media/domain/enums/pick_image_type.dart';
import 'package:cloudless/core/features/media/domain/hooks/use_image_cropper.dart';
import 'package:cloudless/core/features/media/domain/hooks/use_pick_and_compress_image_with_permission.dart';
import 'package:cloudless/presentation/components/sheets/image_picker_sheet.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Hook that handles the complete logic for showing the image picker,
/// cropping the selected image, and managing compression.
///
/// Returns a function that can be called to open the image picker
/// and calls the [onImageSelected] callback when an image is selected and cropped.
///
/// [loadingNotifier] is set to true immediately when the user selects a source
/// (camera/gallery), before the image picker is opened, and set to false after
/// the image is processed.
Future<void> Function() useImagePicker({
  required WidgetRef ref,
  required ValueChanged<File?> onImageSelected,
  ValueNotifier<bool>? loadingNotifier,
  bool enableCropping = true,
  CropType cropType = CropType.circle,
}) {
  final pickAndCompressImage = usePickAndCompressImageWithPermission();
  final cropImage = useImageCropper();

  return () async {
    try {
      final imageSource = await showModalBottomSheet<ImageSource>(
        context: ref.context,
        builder: (context) =>
            const ImagePickerSheet(allowCamera: true, allowGallery: true),
      );

      if (imageSource == null) {
        return;
      }

      loadingNotifier?.value = true;

      try {
        final result = await pickAndCompressImage(
          ref: ref,
          pickImageType: PickImageType.values.firstWhere(
            (type) => type.name == imageSource.name,
          ),
        );

        result.fold((file) async {
          if (enableCropping) {
            try {
              final croppedFile = await cropImage(
                imagePath: file.path,
                cropType: cropType,
              );

              if (croppedFile != null) {
                onImageSelected(croppedFile);
              }
            } catch (e) {
              onImageSelected(file);
            }
          } else {
            onImageSelected(file);
          }
        }, (error) {});
      } finally {
        loadingNotifier?.value = false;
      }
    } catch (e) {
      // Handle error silently or show a toast
      loadingNotifier?.value = false;
    }
  };
}
