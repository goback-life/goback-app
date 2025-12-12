import 'package:cloudless/core/features/permission/domain/enums/permission_type.dart';
import 'package:cloudless/core/features/permission/domain/models/permission_result_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

abstract class PermissionRepositoryContract {
  FutureResult<PermissionResultModel> checkPermissionStatus({
    required PermissionType type,
  });

  FutureResult<PermissionResultModel> requestPermission({
    required PermissionType type,
  });

  FutureResult<void> openAppSettings();

  FutureResult<bool> shouldShowRationale({required PermissionType type});
}
