import 'package:cloudless/core/features/auth/domain/contracts/auth_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class MarkObjectiveCompletedUseCase
    implements UseCaseContract<FutureResult<void>> {
  const MarkObjectiveCompletedUseCase({required this.repository});

  final AuthRepositoryContract repository;

  @override
  FutureResult<void> execute() async {
    return repository.markObjectiveAsCompleted();
  }
}
