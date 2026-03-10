import 'dart:io' show Platform;

import 'package:cloudless/core/features/permission/domain/enums/permission_type.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

class PermissionTypeMapper {
  // Synchronous fallback method (maintains compatibility)
  static handler.Permission toHandler(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return handler.Permission.camera;
      case PermissionType.gallery:
        if (Platform.isAndroid) {
          // On Android, use storage for compatibility
          // For optimal version, use toHandlerAsync
          return handler.Permission.storage;
        } else {
          return handler.Permission.photos;
        }
      case PermissionType.storage:
        return handler.Permission.storage;
      case PermissionType.contact:
        return handler.Permission.contacts;
      case PermissionType.notification:
        return handler.Permission.notification;
    }
  }
}
