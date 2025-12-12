import 'dart:io';

import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

enum CropType { circle, content }

/// Hook that handles image cropping logic using image_cropper
///
/// Returns a function that can be called to open the cropper
/// and returns the cropped image or null if the operation is cancelled.
Future<File?> Function({required String imagePath, CropType cropType})
useImageCropper() {
  return ({
    required String imagePath,
    CropType cropType = CropType.circle,
  }) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      return null;
    }

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,

        // fix to square for circle avatar crop, but for content we will provide a couple
        // presets and let the user freely crop as well. when this is not null, the ratio is always locked
        aspectRatio: switch (cropType) {
          CropType.circle => const CropAspectRatio(ratioX: 1, ratioY: 1),
          CropType.content => null,
        },

        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: translator.translate(
              'components.image_cropper.title',
            ),
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: const Color(0xffffcc00),
            showCropGrid: true,
            hideBottomControls: false,
            cropStyle: switch (cropType) {
              CropType.circle => CropStyle.circle,
              CropType.content => CropStyle.rectangle,
            },

            // if the overall [[aspectRatio]] provided before is not null,
            // this will always be equivalent to true anyway
            lockAspectRatio: switch (cropType) {
              CropType.circle => true,
              CropType.content => false,
            },
            initAspectRatio: switch (cropType) {
              CropType.circle => CropAspectRatioPreset.square,
              CropType.content => CropAspectRatioPreset.original,
            },
            aspectRatioPresets: switch (cropType) {
              CropType.circle => [CropAspectRatioPreset.square],
              CropType.content => [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.original,
              ],
            },
          ),
          IOSUiSettings(
            title: translator.translate('components.image_cropper.title'),
            doneButtonTitle: translator.translate(
              'components.image_cropper.done',
            ),
            cancelButtonTitle: translator.translate(
              'components.image_cropper.cancel',
            ),
            cropStyle: switch (cropType) {
              CropType.circle => CropStyle.circle,
              CropType.content => CropStyle.rectangle,
            },

            // if the overall [[aspectRatio]] provided before is not null,
            // this will always be equivalent to true anyway
            aspectRatioLockEnabled: switch (cropType) {
              CropType.circle => true,
              CropType.content => false,
            },
            hidesNavigationBar: true,
            embedInNavigationController: false,
            resetAspectRatioEnabled: true,
            aspectRatioLockDimensionSwapEnabled: false,
            aspectRatioPickerButtonHidden: false,
            minimumAspectRatio: null,
            aspectRatioPresets: switch (cropType) {
              CropType.circle => [CropAspectRatioPreset.square],
              CropType.content => [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.original,
              ],
            },
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  };
}
