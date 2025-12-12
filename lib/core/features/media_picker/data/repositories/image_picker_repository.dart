import 'dart:io';

import 'package:cloudless/core/features/media_picker/data/exceptions/image_picker_camera_exception.dart';
import 'package:cloudless/core/features/media_picker/data/exceptions/image_picker_gallery_exception.dart';
import 'package:cloudless/core/features/media_picker/data/exceptions/unsupported_image_format_exception.dart';
import 'package:cloudless/core/features/media_picker/domain/contracts/image_picker_repository_contract.dart';
import 'package:cloudless/core/features/media_picker/domain/contracts/image_picker_service_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class ImagePickerRepository implements ImagePickerRepositoryContract {
  const ImagePickerRepository({required this.service});
  final ImagePickerServiceContract service;

  @override
  FutureResult<File> pickFromCamera() async {
    final response = await service.pickFromCamera();
    return response.asyncFold(
      (file) async =>
          file != null ? Success(file) : Failure(ImagePickerCameraException()),
      (error) async {
        if (error is UnsupportedImageFormatException) {
          return Failure(error);
        }

        return Failure(ImagePickerCameraException());
      },
    );
  }

  @override
  FutureResult<File> pickFromGallery() async {
    final response = await service.pickFromGallery();
    return response.asyncFold(
      (file) async =>
          file != null ? Success(file) : Failure(ImagePickerGalleryException()),
      (error) async {
        if (error is UnsupportedImageFormatException) {
          return Failure(error);
        }

        return Failure(ImagePickerGalleryException());
      },
    );
  }
}
