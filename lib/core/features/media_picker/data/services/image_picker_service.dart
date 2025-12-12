import 'dart:io';

import 'package:cloudless/core/features/media_picker/data/exceptions/image_picker_camera_exception.dart';
import 'package:cloudless/core/features/media_picker/data/exceptions/image_picker_gallery_exception.dart';
import 'package:cloudless/core/features/media_picker/data/exceptions/unsupported_image_format_exception.dart';
import 'package:cloudless/core/features/media_picker/data/utils/image_format_validator.dart';
import 'package:cloudless/core/features/media_picker/domain/contracts/image_picker_service_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerService implements ImagePickerServiceContract {
  final ImagePicker _picker = ImagePicker();

  @override
  FutureResult<File?> pickFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.camera);

      if (file == null) {
        return Result.success(null);
      }

      final pickedFile = File(file.path);

      if (!ImageFormatValidator.isValidFormat(pickedFile)) {
        return Result.failure(UnsupportedImageFormatException());
      }

      return Result.success(pickedFile);
    } catch (e) {
      return Result.failure(ImagePickerCameraException(e.toString()));
    }
  }

  @override
  FutureResult<File?> pickFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);

      if (file == null) {
        return Result.success(null);
      }

      final pickedFile = File(file.path);

      if (!ImageFormatValidator.isValidFormat(pickedFile)) {
        return Result.failure(UnsupportedImageFormatException());
      }

      return Result.success(pickedFile);
    } catch (e) {
      return Result.failure(ImagePickerGalleryException(e.toString()));
    }
  }
}
