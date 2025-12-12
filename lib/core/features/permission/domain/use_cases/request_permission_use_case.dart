import 'package:cloudless/core/features/permission/domain/contracts/permission_repository_contract.dart';
import 'package:cloudless/core/features/permission/domain/enums/permission_type.dart';
import 'package:cloudless/core/features/permission/domain/models/permission_result_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

class RequestPermissionUseCase
    implements UseCaseContract<FutureResult<PermissionResultModel>> {
  const RequestPermissionUseCase({
    required this.repository,
    required this.type,
  });

  final PermissionRepositoryContract repository;
  final PermissionType type;

  @override
  FutureResult<PermissionResultModel> execute() {
    return repository.requestPermission(type: type);
  }
}
