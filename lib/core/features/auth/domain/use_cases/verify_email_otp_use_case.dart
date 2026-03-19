import 'package:cloudless/core/features/auth/domain/contracts/auth_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class VerifyEmailOtpUseCase implements UseCaseContract<Result<bool>> {
  const VerifyEmailOtpUseCase({
    required this.email,
    required this.otp,
    required this.repository,
  });

  final String email;
  final String otp;
  final AuthRepositoryContract repository;

  @override
  Future<Result<bool>> execute() async {
    return await repository.verifyEmailOtp(email: email, otp: otp);
  }
}
