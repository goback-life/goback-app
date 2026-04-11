import 'package:cloudless/core/features/auth/domain/contracts/auth_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class SignInWithEmailUseCase implements UseCaseContract<Result<void>> {
  const SignInWithEmailUseCase({required this.email, required this.repository});

  final String email;
  final AuthRepositoryContract repository;

  @override
  Future<Result<void>> execute() async {
    return await repository.signInWithEmail(email: email);
  }
}
