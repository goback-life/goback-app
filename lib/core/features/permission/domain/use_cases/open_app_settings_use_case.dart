import 'package:cloudless/core/features/permission/domain/contracts/permission_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class OpenAppSettingsUseCase implements UseCaseContract<FutureResult<void>> {
  const OpenAppSettingsUseCase({required this.repository});

  final PermissionRepositoryContract repository;

  @override
  FutureResult<void> execute() {
    return repository.openAppSettings();
  }
}
