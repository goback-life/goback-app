import 'package:cloudless/core/features/permission/data/exceptions/permission_check_status_exception.dart';
import 'package:cloudless/core/features/permission/data/exceptions/permission_open_settings_exception.dart';
import 'package:cloudless/core/features/permission/data/exceptions/permission_rationale_exception.dart';
import 'package:cloudless/core/features/permission/data/exceptions/permission_request_exception.dart';
import 'package:cloudless/core/features/permission/domain/contracts/permission_repository_contract.dart';
import 'package:cloudless/core/features/permission/domain/contracts/permission_service_contract.dart';
import 'package:cloudless/core/features/permission/domain/enums/permission_type.dart';
import 'package:cloudless/core/features/permission/domain/models/permission_result_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

class PermissionRepository implements PermissionRepositoryContract {
  const PermissionRepository({required this.service});

  final PermissionServiceContract service;

  @override
  FutureResult<PermissionResultModel> checkPermissionStatus({
    required PermissionType type,
  }) async {
    final response = await service.checkPermissionStatus(type);

    return response.asyncFold(
      (status) async =>
          Success(PermissionResultModel(type: type, status: status)),
      (_) async => Failure(PermissionCheckStatusException()),
    );
  }

  @override
  FutureResult<PermissionResultModel> requestPermission({
    required PermissionType type,
  }) async {
    final response = await service.requestPermission(type);

    return response.asyncFold(
      (status) async =>
          Success(PermissionResultModel(type: type, status: status)),
      (_) async => Failure(PermissionRequestException()),
    );
  }

  @override
  FutureResult<void> openAppSettings() async {
    final response = await service.openAppSettings();

    return response.asyncFold(
      (result) async => Success(result),
      (_) async => Failure(PermissionOpenSettingsException()),
    );
  }

  @override
  FutureResult<bool> shouldShowRationale({required PermissionType type}) async {
    final response = await service.shouldShowRationale(type);

    return response.asyncFold(
      (result) async => Success(result),
      (_) async => Failure(PermissionRationaleException()),
    );
  }
}
