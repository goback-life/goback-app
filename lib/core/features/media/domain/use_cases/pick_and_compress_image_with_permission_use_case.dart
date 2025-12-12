import 'dart:io';

import 'package:cloudless/core/features/media/domain/enums/pick_image_type.dart';
import 'package:cloudless/core/features/media_picker/data/providers/image_compress_service_provider.dart';
import 'package:cloudless/core/features/media_picker/data/providers/image_picker_repository_provider.dart';
import 'package:cloudless/core/features/media_picker/domain/use_cases/pick_image_from_camera_use_case.dart';
import 'package:cloudless/core/features/media_picker/domain/use_cases/pick_image_from_gallery_use_case.dart';
import 'package:cloudless/core/features/permission/data/exceptions/camera_permission_denied_exception.dart';
import 'package:cloudless/core/features/permission/data/exceptions/gallery_permission_denied_exception.dart';
import 'package:cloudless/core/features/permission/domain/enums/permission_status.dart';
import 'package:cloudless/core/features/permission/domain/enums/permission_type.dart';
import 'package:cloudless/core/features/permission/domain/providers/check_permission_status_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';

class PickAndCompressImageWithPermissionUseCase
    implements UseCaseContract<FutureResult<File>> {
  const PickAndCompressImageWithPermissionUseCase({
    required this.pickImageType,
  });

  final PickImageType pickImageType;

  @override
  FutureResult<File> execute() async {
    final permissionType = pickImageType == PickImageType.camera
        ? PermissionType.camera
        : PermissionType.gallery;

    final permissionResult = await riverpodContainer().read(
      checkPermissionStatusProvider(type: permissionType).future,
    );

    return permissionResult.asyncFold((success) async {
      if (success.status != PermissionStatus.granted) {
        if (pickImageType == PickImageType.camera) {
          if (success.status == PermissionStatus.permanentlyDenied) {
            return Failure(
              CameraPermissionDeniedException(
                message: 'Camera permission permanently denied.',
                isPermanentlyDenied: true,
              ),
            );
          }
          return Failure(CameraPermissionDeniedException());
        } else {
          if (success.status == PermissionStatus.permanentlyDenied) {
            return Failure(
              GalleryPermissionDeniedException(
                message: 'Gallery permission permanently denied.',
                isPermanentlyDenied: true,
              ),
            );
          }
          return Failure(GalleryPermissionDeniedException());
        }
      }
      final repository = riverpodContainer().read(
        imagePickerRepositoryProvider,
      );
      final compressService = riverpodContainer().read(
        imageCompressServiceProvider,
      );
      Result<File> pickResult;
      switch (pickImageType) {
        case PickImageType.camera:
          final useCase = PickImageFromCameraUseCase(repository: repository);
          pickResult = await useCase.execute();
          break;
        case PickImageType.gallery:
          final useCase = PickImageFromGalleryUseCase(repository: repository);
          pickResult = await useCase.execute();
          break;
      }
      return pickResult.asyncFold((file) async {
        final compressed = await compressService.compressImage(file);
        return compressed != null
            ? Success(compressed)
            : Failure(Exception('Compression failed'));
      }, (failure) async => Failure(failure));
    }, (failure) async => Failure(Exception('Permesso non concesso')));
  }
}
