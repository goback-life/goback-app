import 'package:cloudless/core/features/permission/data/exceptions/permission_exception.dart';

class GalleryPermissionDeniedException extends PermissionException {
  GalleryPermissionDeniedException({
    String message = 'Gallery permission denied.',
    this.isPermanentlyDenied = false,
  }) : super(message);

  final bool isPermanentlyDenied;
}
