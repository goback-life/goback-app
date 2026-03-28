import 'package:cloudless/core/models/user_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

/// Auth repository contract -- translates service results to domain models
/// and handles local persistence (e.g. onboarding objective state).
abstract class AuthRepositoryContract {
  bool get isAuthenticated;
  Stream<bool> get isAuthenticatedStream;
  FutureResult<UserModel> getCurrentUser();
  FutureResult<void> signIn({required String phoneNumber});
  Future<Result<bool>> verifyPhoneOtp({
    required String phoneNumber,
    required String otp,
  });
  FutureResult<void> resendPhoneOtp({required String phoneNumber});
  FutureResult<void> signInWithEmail({required String email});
  Future<Result<bool>> verifyEmailOtp({
    required String email,
    required String otp,
  });
  FutureResult<void> resendEmailOtp({required String email});
  FutureResult<void> markObjectiveAsCompleted();
  FutureResult<bool> hasCompletedObjective();
  FutureResult<void> signOut();
  FutureResult<bool> validateSession();
  FutureResult<void> deleteAccount();
}
