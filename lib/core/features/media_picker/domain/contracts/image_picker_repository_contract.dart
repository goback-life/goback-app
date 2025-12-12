import 'dart:io';

import 'package:dedecube_core/dedecube_core.dart';

abstract interface class ImagePickerRepositoryContract {
  FutureResult<File> pickFromCamera();
  FutureResult<File> pickFromGallery();
}
