import 'package:cloudless/core/features/auth/domain/contracts/auth_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class HasCompletedObjectiveUseCase
    implements UseCaseContract<FutureResult<bool>> {
  const HasCompletedObjectiveUseCase({required this.repository});

  final AuthRepositoryContract repository;

  @override
  FutureResult<bool> execute() async {
    return repository.hasCompletedObjective();
  }
}
