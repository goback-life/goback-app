import 'package:cloudless/core/features/auth/data/providers/auth_repository_provider.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/resend_email_otp_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'resend_email_otp_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<void>> resendEmailOtp(Ref ref, String email) async {
  final useCase = ResendEmailOtpUseCase(
    repository: ref.watch(authRepositoryProvider),
    email: email,
  );

  return useCase.execute();
}
