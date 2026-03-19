import 'package:cloudless/core/features/auth/data/providers/auth_repository_provider.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/verify_email_otp_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'verify_email_otp_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<bool>> verifyEmailOtp(
  Ref ref,
  String email,
  String otp,
) async {
  final useCase = VerifyEmailOtpUseCase(
    email: email,
    otp: otp,
    repository: ref.watch(authRepositoryProvider),
  );

  return useCase.execute();
}
