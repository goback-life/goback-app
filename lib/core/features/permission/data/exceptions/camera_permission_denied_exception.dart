import 'package:cloudless/core/features/permission/data/exceptions/permission_exception.dart';

class CameraPermissionDeniedException extends PermissionException {
  CameraPermissionDeniedException({
    String message = 'Camera permission denied.',
    this.isPermanentlyDenied = false,
  }) : super(message);

  final bool isPermanentlyDenied;
}
