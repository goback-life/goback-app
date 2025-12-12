import 'package:cloudless/core/features/media_picker/data/exceptions/image_picker_exception.dart';

class UnsupportedImageFormatException extends ImagePickerException {
  UnsupportedImageFormatException([
    super.message = 'Unsupported image format.',
  ]);
}
