import 'package:cloudless/core/models/user_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

/// Contract for an authentication repository that sits between the
/// data/services layer and higher-level domain/UI code.
///
/// Implementations should translate service results into domain models
/// (`UserModel`) and handle local persistence concerns (for example,
/// marking onboarding objectives as completed).
abstract class AuthRepositoryContract {
  /// Synchronous flag indicating whether a user is currently authenticated.
  ///
  /// Implementations typically reflect the underlying auth service state.
  bool get isAuthenticated;

  /// Stream that emits authentication state changes as boolean values.
  ///
  /// Useful for UI layers to react to sign-in/sign-out events.
  Stream<bool> get isAuthenticatedStream;

  /// Returns the currently authenticated user as a domain [UserModel].
  ///
  /// The result is wrapped in [FutureResult] to allow returning structured
  /// errors (for example, network failures) in a consistent way.
  FutureResult<UserModel> getCurrentUser();

  /// Starts the sign-in flow for the provided phone number.
  ///
  /// This typically triggers sending an OTP to the given `phoneNumber` through
  /// the underlying auth service. Returns success when the request was
  /// accepted or a failure with error information.
  FutureResult<void> signIn({required String phoneNumber});

  /// Verifies a one-time password (OTP) previously sent to `phone`.
  ///
  /// On success returns a [Result] containing a populated [UserModel]. On
  /// failure returns a failed [FutureResult] with error details (invalid/expired
  /// OTP, network error, etc.).
  ///
  /// Params:
  /// - `phoneNumber`: the phone number that received the OTP.
  /// - `otp`: the one-time password code to verify.
  Future<Result<bool>> verifyPhoneOtp({
    required String phoneNumber,
    required String otp,
  });

  /// Requests the backend to resend an OTP to the given `phoneNumber`.
  ///
  /// Returns success when the resend request is accepted or a failure
  /// describing why it couldn't be resent (rate limit, invalid phone, etc.).
  FutureResult<void> resendPhoneOtp({required String phoneNumber});

  /// Starts the sign-in flow for the provided email address (US fallback).
  FutureResult<void> signInWithEmail({required String email});

  /// Verifies a one-time password (OTP) previously sent to `email`.
  Future<Result<bool>> verifyEmailOtp({
    required String email,
    required String otp,
  });

  /// Requests the backend to resend an OTP to the given `email`.
  FutureResult<void> resendEmailOtp({required String email});

  /// Marks a local onboarding objective as completed.
  ///
  /// Implementations may persist this flag locally (device-only). If you
  /// need cross-device persistence, the implementation should sync this
  /// state with a backend user property instead.
  FutureResult<void> markObjectiveAsCompleted();

  /// Returns whether the onboarding objective has been completed locally.
  ///
  /// Useful to decide whether to show onboarding screens or tooltips.
  FutureResult<bool> hasCompletedObjective();

  /// Signs out the current authenticated user.
  ///
  /// Returns a successful [FutureResult] on successful sign-out or a
  /// failure if sign-out couldn't be completed.
  FutureResult<void> signOut();

  /// Validates that the current session is still valid.
  ///
  /// This is useful to detect if a user was deleted externally (e.g., from
  /// Supabase dashboard) or if the session has been invalidated.
  FutureResult<bool> validateSession();

  /// Deletes the current authenticated user account.
  ///
  /// This permanently deletes the user account and all associated data
  /// from the backend.
  ///
  /// Returns a successful [FutureResult] on successful deletion or a
  /// failure if deletion couldn't be completed.
  FutureResult<void> deleteAccount();
}
