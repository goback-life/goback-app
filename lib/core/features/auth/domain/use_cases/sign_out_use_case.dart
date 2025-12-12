import 'package:cloudless/core/features/auth/domain/contracts/auth_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class SignOutUseCase implements UseCaseContract<Result<void>> {
  const SignOutUseCase({required this.repository});

  final AuthRepositoryContract repository;

  @override
  Future<Result<void>> execute() async {
    return await repository.signOut();
  }
}
