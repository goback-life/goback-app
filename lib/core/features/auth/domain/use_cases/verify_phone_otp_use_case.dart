import 'package:cloudless/core/features/auth/domain/contracts/auth_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class VerifyPhoneOtpUseCase implements UseCaseContract<Result<bool>> {
  const VerifyPhoneOtpUseCase({
    required this.phoneNumber,
    required this.otp,
    required this.repository,
  });

  final String phoneNumber;
  final String otp;
  final AuthRepositoryContract repository;

  @override
  Future<Result<bool>> execute() async {
    return await repository.verifyPhoneOtp(phoneNumber: phoneNumber, otp: otp);
  }
}
