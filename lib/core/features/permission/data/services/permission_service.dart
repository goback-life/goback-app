import 'package:cloudless/core/features/permission/data/exceptions/permission_check_status_exception.dart';
import 'package:cloudless/core/features/permission/data/exceptions/permission_open_settings_exception.dart';
import 'package:cloudless/core/features/permission/data/exceptions/permission_rationale_exception.dart';
import 'package:cloudless/core/features/permission/data/exceptions/permission_request_exception.dart';
import 'package:cloudless/core/features/permission/data/mappers/permission_status_mapper.dart';
import 'package:cloudless/core/features/permission/data/mappers/permission_type_mapper.dart';
import 'package:cloudless/core/features/permission/domain/contracts/permission_service_contract.dart';
import 'package:cloudless/core/features/permission/domain/enums/permission_status.dart';
import 'package:cloudless/core/features/permission/domain/enums/permission_type.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

class PermissionService implements PermissionServiceContract {
  @override
  FutureResult<PermissionStatus> checkPermissionStatus(
    PermissionType type,
  ) async {
    try {
      final permission = PermissionTypeMapper.toHandler(type);
      final status = await permission.status;
      return Result.success(
        PermissionStatusMapper.fromPermissionHandlerStatus(status),
      );
    } catch (e) {
      return Result.failure(PermissionCheckStatusException());
    }
  }

  @override
  FutureResult<PermissionStatus> requestPermission(PermissionType type) async {
    try {
      final permission = PermissionTypeMapper.toHandler(type);
      final status = await permission.request();
      return Result.success(
        PermissionStatusMapper.fromPermissionHandlerStatus(status),
      );
    } catch (e) {
      return Result.failure(PermissionRequestException());
    }
  }

  @override
  FutureResult<void> openAppSettings() async {
    try {
      await handler.openAppSettings();
      return Result.success(null);
    } catch (e) {
      return Result.failure(PermissionOpenSettingsException());
    }
  }

  @override
  FutureResult<bool> shouldShowRationale(PermissionType type) async {
    try {
      final permission = PermissionTypeMapper.toHandler(type);
      final shouldShow = await permission.shouldShowRequestRationale;
      return Result.success(shouldShow);
    } catch (e) {
      return Result.failure(PermissionRationaleException());
    }
  }
}
