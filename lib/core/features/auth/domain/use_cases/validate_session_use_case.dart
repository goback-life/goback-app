import 'package:cloudless/core/features/auth/domain/contracts/auth_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

/// Use case for validating the current authentication session.
///
/// This is useful to detect if a user was deleted externally or if the
/// session has been invalidated.
class ValidateSessionUseCase implements UseCaseContract<FutureResult<bool>> {
  const ValidateSessionUseCase({required this.repository});

  final AuthRepositoryContract repository;

  @override
  FutureResult<bool> execute() {
    return repository.validateSession();
  }
}
