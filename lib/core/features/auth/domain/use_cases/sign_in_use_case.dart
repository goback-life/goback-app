import 'package:cloudless/core/features/auth/domain/contracts/auth_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class SignInUseCase implements UseCaseContract<Result<void>> {
  const SignInUseCase({required this.phoneNumber, required this.repository});

  final String phoneNumber;
  final AuthRepositoryContract repository;

  @override
  Future<Result<void>> execute() async {
    return await repository.signIn(phoneNumber: phoneNumber);
  }
}
