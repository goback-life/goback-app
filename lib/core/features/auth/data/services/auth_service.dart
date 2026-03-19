import 'package:cloudless/core/features/auth/data/exceptions/auth_user_not_found_exception.dart';
import 'package:cloudless/core/features/auth/domain/contracts/auth_service_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService implements AuthServiceContract {
  const AuthService({required SupabaseClient supabaseClient})
    : _supabaseClient = supabaseClient;

  final SupabaseClient _supabaseClient;

  @override
  bool get isAuthenticated {
    return _supabaseClient.auth.currentUser != null;
  }

  @override
  Stream<bool> get isAuthenticatedStream {
    return _supabaseClient.auth.onAuthStateChange.map((authState) {
      // Session is valid only if it exists and has a valid user
      return authState.session != null && authState.session?.user != null;
    });
  }

  @override
  FutureResult<void> signIn({required String phoneNumber}) async {
    try {
      await _supabaseClient.auth.signInWithOtp(phone: phoneNumber);

      return Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  FutureResult<AuthResponse> verifyPhoneOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final response = await _supabaseClient.auth.verifyOTP(
        type: OtpType.sms,
        phone: phoneNumber,
        token: otp,
      );

      return Result.success(response);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  FutureResult<void> resendPhoneOtp({required String phoneNumber}) async {
    try {
      await _supabaseClient.auth.resend(type: OtpType.sms, phone: phoneNumber);

      return Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  FutureResult<void> signInWithEmail({required String email}) async {
    try {
      await _supabaseClient.auth.signInWithOtp(email: email);

      return Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  FutureResult<AuthResponse> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _supabaseClient.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: otp,
      );

      return Result.success(response);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  FutureResult<void> resendEmailOtp({required String email}) async {
    try {
      await _supabaseClient.auth.resend(type: OtpType.email, email: email);

      return Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  FutureResult<User> getCurrentUser() async {
    try {
      final user = _supabaseClient.auth.currentUser;

      if (user != null) {
        return Result.success(user);
      } else {
        return Result.failure(const AuthUserNotFoundException());
      }
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  FutureResult<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();

      return Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  FutureResult<AuthResponse> validateSession() async {
    try {
      final currentSession = _supabaseClient.auth.currentSession;

      if (currentSession == null) {
        throw const AuthException('session_not_found');
      }

      return Result.success(
        AuthResponse(session: currentSession, user: currentSession.user),
      );
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  FutureResult<void> deleteAccount() async {
    try {
      await _supabaseClient.rpc('delete_current_user');

      return Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }
}
