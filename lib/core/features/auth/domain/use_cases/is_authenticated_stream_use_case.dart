import 'package:cloudless/core/features/auth/domain/contracts/auth_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class IsAuthenticatedStreamUseCase implements UseCaseContract<Stream<bool>> {
  const IsAuthenticatedStreamUseCase({required this.repository});

  final AuthRepositoryContract repository;

  @override
  Stream<bool> execute() {
    return repository.isAuthenticatedStream;
  }
}
