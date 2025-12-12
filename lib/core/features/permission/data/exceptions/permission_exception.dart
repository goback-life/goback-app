import 'package:cloudless/core/exceptions/main_exception.dart';

abstract class PermissionException extends MainException {
  const PermissionException(super.message, {super.code});
}
