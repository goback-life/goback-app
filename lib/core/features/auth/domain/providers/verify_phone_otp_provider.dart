import 'package:cloudless/core/features/auth/data/providers/auth_repository_provider.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/verify_phone_otp_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'verify_phone_otp_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<bool>> verifyPhoneOtp(
  Ref ref,
  String phoneNumber,
  String otp,
) async {
  final useCase = VerifyPhoneOtpUseCase(
    phoneNumber: phoneNumber,
    otp: otp,
    repository: ref.watch(authRepositoryProvider),
  );

  return useCase.execute();
}
