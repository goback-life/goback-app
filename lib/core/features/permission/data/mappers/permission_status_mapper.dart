import 'package:cloudless/core/features/permission/domain/enums/permission_status.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

class PermissionStatusMapper {
  static PermissionStatus fromPermissionHandlerStatus(
    handler.PermissionStatus status,
  ) {
    switch (status) {
      case handler.PermissionStatus.granted:
        return PermissionStatus.granted;
      case handler.PermissionStatus.denied:
        return PermissionStatus.denied;
      case handler.PermissionStatus.permanentlyDenied:
        return PermissionStatus.permanentlyDenied;
      case handler.PermissionStatus.restricted:
        return PermissionStatus.restricted;
      case handler.PermissionStatus.limited:
        return PermissionStatus.limited;
      case handler.PermissionStatus.provisional:
        return PermissionStatus.limited;
    }
  }
}
