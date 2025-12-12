import 'package:cloudless/core/features/permission/data/exceptions/permission_exception.dart';

class PermissionCheckStatusException extends PermissionException {
  PermissionCheckStatusException()
    : super('Failed to check permission status.');
}
