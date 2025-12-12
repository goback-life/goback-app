import 'package:cloudless/core/features/auth/data/providers/auth_repository_provider.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/resend_phone_otp_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'resend_phone_otp_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<void>> resendPhoneOtp(Ref ref, String phoneNumber) async {
  final useCase = ResendPhoneOtpUseCase(
    repository: ref.watch(authRepositoryProvider),
    phoneNumber: phoneNumber,
  );

  return useCase.execute();
}
