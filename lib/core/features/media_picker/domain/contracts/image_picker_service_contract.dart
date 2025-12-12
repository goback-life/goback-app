import 'dart:io';

import 'package:dedecube_core/dedecube_core.dart';

abstract interface class ImagePickerServiceContract {
  /// Picks an image using the device camera.
  /// Returns a [File] if the user takes a photo, or null if cancelled.
  FutureResult<File?> pickFromCamera();

  /// Picks an image from the device gallery.
  /// Returns a [File] if the user selects an image, or null if cancelled.
  FutureResult<File?> pickFromGallery();
}
