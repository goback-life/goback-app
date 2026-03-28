import 'package:dedecube_core/dedecube_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Phone/email OTP authentication service contract (Supabase-backed).
abstract class AuthServiceContract {
  bool get isAuthenticated;
  Stream<bool> get isAuthenticatedStream;
  FutureResult<User> getCurrentUser();
  FutureResult<void> signIn({required String phoneNumber});
  FutureResult<AuthResponse> verifyPhoneOtp({
    required String phoneNumber,
    required String otp,
  });
  FutureResult<void> resendPhoneOtp({required String phoneNumber});
  FutureResult<void> signInWithEmail({required String email});
  FutureResult<AuthResponse> verifyEmailOtp({
    required String email,
    required String otp,
  });
  FutureResult<void> resendEmailOtp({required String email});
  FutureResult<void> signOut();
  FutureResult<AuthResponse> validateSession();
  FutureResult<void> deleteAccount();
}
