import 'package:cloudless/core/features/permission/domain/contracts/permission_repository_contract.dart';
import 'package:cloudless/core/features/permission/domain/enums/permission_type.dart';
import 'package:dedecube_core/dedecube_core.dart';

class ShouldShowRationaleUseCase
    implements UseCaseContract<FutureResult<bool>> {
  const ShouldShowRationaleUseCase({
    required this.repository,
    required this.type,
  });

  final PermissionRepositoryContract repository;
  final PermissionType type;

  @override
  FutureResult<bool> execute() {
    return repository.shouldShowRationale(type: type);
  }
}
