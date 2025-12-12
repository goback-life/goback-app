import 'package:cloudless/core/features/permission/data/exceptions/permission_exception.dart';

class PermissionRequestException extends PermissionException {
  PermissionRequestException() : super('Failed to request permission.');
}
