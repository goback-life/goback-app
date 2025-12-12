import 'dart:io';

import 'package:cloudless/core/features/media/domain/enums/pick_image_type.dart';
import 'package:cloudless/core/features/media/domain/use_cases/pick_and_compress_image_with_permission_use_case.dart';
import 'package:cloudless/core/features/media_picker/data/exceptions/unsupported_image_format_exception.dart';
import 'package:cloudless/core/features/permission/data/exceptions/camera_permission_denied_exception.dart';
import 'package:cloudless/core/features/permission/data/exceptions/gallery_permission_denied_exception.dart';
import 'package:cloudless/core/features/permission/domain/enums/permission_type.dart';
import 'package:cloudless/core/features/permission/domain/providers/request_permission_provider.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

FutureResult<File> Function({
  required WidgetRef ref,
  required PickImageType pickImageType,
})
usePickAndCompressImageWithPermission() {
  return useCallback(({
    required WidgetRef ref,
    required PickImageType pickImageType,
  }) async {
    final instance = PickAndCompressImageWithPermissionUseCase(
      pickImageType: pickImageType,
    );
    final result = await instance.execute();
    return result.fold((file) => Result.success(file), (failure) async {
      // Handle unsupported image format
      if (failure is UnsupportedImageFormatException) {
        await MainAlert.showFull(
          context: ref.context,
          title: translator.translate(
            'components.unsupported_image_format.title',
          ),
          content: Text(
            translator.translate('components.unsupported_image_format.content'),
          ),
          primaryButtonText: translator.translate(
            'components.alert.confirm_button',
          ),
          onPrimaryPressed: () => Navigator.of(ref.context).pop(),
        );
        return Result.failure(failure);
      }

      if (failure is CameraPermissionDeniedException &&
              failure.isPermanentlyDenied ||
          failure is GalleryPermissionDeniedException &&
              failure.isPermanentlyDenied) {
        final confirmed =
            await MainAlert.showFull<bool>(
              context: ref.context,
              title: translator.translate(
                'permission.permanently_denied.title',
              ),
              content: Text(
                translator.translate('permission.permanently_denied.message'),
              ),
              primaryButtonText: translator.translate(
                'permission.permanently_denied.open_settings',
              ),
              onPrimaryPressed: () => Navigator.of(ref.context).pop(true),
              secondaryButtonText: translator.translate(
                'components.alert.cancel',
              ),
              onSecondaryPressed: () => Navigator.of(ref.context).pop(false),
            ) ??
            false;
        if (confirmed) {
          openAppSettings();
        }
        return Result.failure(failure);
      } else if (failure is GalleryPermissionDeniedException &&
          !failure.isPermanentlyDenied) {
        await ref.read(
          requestPermissionProvider(type: PermissionType.gallery).future,
        );
        // Retry the operation after requesting permission
        final retryResult = await instance.execute();
        return retryResult;
      } else if (failure is CameraPermissionDeniedException &&
          !failure.isPermanentlyDenied) {
        await ref.read(
          requestPermissionProvider(type: PermissionType.camera).future,
        );
        // Retry the operation after requesting permission
        final retryResult = await instance.execute();
        return retryResult;
      }
      return Result.failure(failure);
    });
  }, []);
}
