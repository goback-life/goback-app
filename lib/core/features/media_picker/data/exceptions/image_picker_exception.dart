import 'package:cloudless/core/exceptions/main_exception.dart';

/// Base exception for image picker errors
abstract class ImagePickerException extends MainException {
  const ImagePickerException(super.message, {super.code});
}
