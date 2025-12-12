import 'package:cloudless/core/features/permission/data/exceptions/permission_exception.dart';

class PermissionRationaleException extends PermissionException {
  PermissionRationaleException() : super('Failed to check rationale.');
}
