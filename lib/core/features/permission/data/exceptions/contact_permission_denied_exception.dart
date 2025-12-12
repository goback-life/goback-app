import 'package:cloudless/core/features/permission/data/exceptions/permission_exception.dart';

class ContactPermissionDeniedException extends PermissionException {
  ContactPermissionDeniedException({
    String message = 'Contacts permission denied.',
    this.isPermanentlyDenied = false,
  }) : super(message);

  final bool isPermanentlyDenied;
}
