import 'package:cloudless/core/features/auth/domain/contracts/auth_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class IsAuthenticatedUseCase implements UseCaseContract<bool> {
  const IsAuthenticatedUseCase({required this.repository});

  final AuthRepositoryContract repository;

  @override
  bool execute() {
    return repository.isAuthenticated;
  }
}
