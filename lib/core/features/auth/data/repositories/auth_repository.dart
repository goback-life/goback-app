import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/auth/data/mappers/auth_response_to_model_mapper.dart';
import 'package:cloudless/core/features/auth/data/mappers/delete_account_exceptions_mapper.dart';
import 'package:cloudless/core/features/auth/data/mappers/get_current_user_exceptions_mapper.dart';
import 'package:cloudless/core/features/auth/data/mappers/resend_otp_exceptions_mapper.dart';
import 'package:cloudless/core/features/auth/data/mappers/sign_in_exceptions_mapper.dart';
import 'package:cloudless/core/features/auth/data/mappers/sign_out_exceptions_mapper.dart';
import 'package:cloudless/core/features/auth/data/mappers/validate_session_exceptions_mapper.dart';
import 'package:cloudless/core/features/auth/data/mappers/verify_phone_otp_exceptions_mapper.dart';
import 'package:cloudless/core/features/auth/data/storables/objective_completed_storable.dart';
import 'package:cloudless/core/features/auth/domain/contracts/auth_repository_contract.dart';
import 'package:cloudless/core/features/auth/domain/contracts/auth_service_contract.dart';
import 'package:cloudless/core/features/supabase/data/mixins/supabase_result_processor.dart';
import 'package:cloudless/core/models/user_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository
    with SupabaseResultProcessor
    implements AuthRepositoryContract {
  const AuthRepository({required this.authService});

  final AuthServiceContract authService;
  @override
  bool get isAuthenticated {
    return authService.isAuthenticated;
  }

  @override
  Stream<bool> get isAuthenticatedStream {
    return authService.isAuthenticatedStream;
  }

  @override
  FutureResult<void> signIn({required String phoneNumber}) async {
    return processSupabaseResult<void, void>(
      request: () => authService.signIn(phoneNumber: phoneNumber),
      responseMapper: (dto) async {
        return;
      },
      exceptionMapper: SignInExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  Future<Result<bool>> verifyPhoneOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    return processSupabaseResult<AuthResponse, bool>(
      request: () =>
          authService.verifyPhoneOtp(phoneNumber: phoneNumber, otp: otp),
      responseMapper: (dto) async {
        if (dto.user == null) {
          return false;
        }

        return true;
      },
      exceptionMapper: VerifyOtpExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<void> resendPhoneOtp({required String phoneNumber}) async {
    return processSupabaseResult<void, void>(
      request: () => authService.resendPhoneOtp(phoneNumber: phoneNumber),
      responseMapper: (dto) async {
        return;
      },
      exceptionMapper: ResendOtpExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<UserModel> getCurrentUser() async {
    return processSupabaseResult<User?, UserModel>(
      request: () => authService.getCurrentUser(),
      responseMapper: (user) async {
        return AuthResponseToModelMapper().mapDto(
          AuthResponse(user: user, session: null),
        );
      },
      exceptionMapper: GetCurrentUserExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<void> markObjectiveAsCompleted() async {
    try {
      final storable = ObjectiveCompletedStorable();
      await storable.set(true);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        UnhandledException('Failed to mark objective as completed', cause: e),
      );
    }
  }

  @override
  FutureResult<bool> hasCompletedObjective() async {
    try {
      final storable = ObjectiveCompletedStorable();
      final hasCompleted = await storable.get(defaultValue: false);
      return Result.success(hasCompleted);
    } catch (e) {
      return Result.failure(
        UnhandledException(
          'Failed to read objective completion state',
          cause: e,
        ),
      );
    }
  }

  @override
  FutureResult<void> signOut() async {
    return processSupabaseResult<void, void>(
      request: () => authService.signOut(),
      responseMapper: (dto) async {
        return;
      },
      exceptionMapper: SignOutExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<bool> validateSession() async {
    return processSupabaseResult<AuthResponse, bool>(
      request: () => authService.validateSession(),
      responseMapper: (dto) async {
        return true;
      },
      exceptionMapper: ValidateSessionExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<void> deleteAccount() async {
    return processSupabaseResult<void, void>(
      request: () => authService.deleteAccount(),
      responseMapper: (dto) async {
        return;
      },
      exceptionMapper: DeleteAccountExceptionsMapper.fromSupabaseException,
    );
  }
}
