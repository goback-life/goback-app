import 'package:cloudless/core/features/auth/domain/contracts/auth_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';

class ResendPhoneOtpUseCase implements UseCaseContract<Result<void>> {
  const ResendPhoneOtpUseCase({
    required this.phoneNumber,
    required this.repository,
  });

  final String phoneNumber;
  final AuthRepositoryContract repository;

  @override
  Future<Result<void>> execute() async {
    return await repository.resendPhoneOtp(phoneNumber: phoneNumber);
  }
}
