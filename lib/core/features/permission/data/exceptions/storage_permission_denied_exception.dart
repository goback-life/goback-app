import 'package:cloudless/core/features/permission/data/exceptions/permission_exception.dart';

class StoragePermissionDeniedException extends PermissionException {
  StoragePermissionDeniedException([
    super.message = 'Storage permission denied.',
  ]);
}
