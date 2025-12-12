import 'package:cloudless/core/features/media_picker/data/exceptions/image_picker_exception.dart';

class ImagePickerCameraException extends ImagePickerException {
  ImagePickerCameraException([super.message = 'Camera pick failed.']);
}
