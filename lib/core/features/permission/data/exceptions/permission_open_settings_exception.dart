import 'package:cloudless/core/features/permission/data/exceptions/permission_exception.dart';

class PermissionOpenSettingsException extends PermissionException {
  PermissionOpenSettingsException() : super('Failed to open settings.');
}
