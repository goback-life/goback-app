import 'package:dedecube_core/dedecube_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Contract for an authentication service that uses phone-based
/// authentication (OTP) and integrates with Supabase.
abstract class AuthServiceContract {
  /// Synchronous flag indicating whether a user is currently authenticated.
  ///
  /// Implementations should reflect the latest known authenticated state.
  bool get isAuthenticated;

  /// Stream that emits authentication state changes as boolean values.
  ///
  /// Useful for UI layers to react to sign-in/sign-out events.
  Stream<bool> get isAuthenticatedStream;

  /// Returns the currently authenticated Supabase [User].
  ///
  /// The result is wrapped in [FutureResult] to allow returning structured
  /// errors (for example, network failures) in a consistent way.
  FutureResult<User> getCurrentUser();

  /// Starts the sign-in flow for the provided phone number.
  ///
  /// This typically triggers sending an OTP/sms to the given `phone`.
  /// Returns a successful [FutureResult] when the request was accepted by
  /// the authentication backend, or a failure containing error information.
  ///
  /// Params:
  /// - `phoneNumber`: phone number in the format expected by the backend
  ///   (include country code if required).
  FutureResult<void> signIn({required String phoneNumber});

  /// Verifies a one-time password (OTP) previously sent to `phone`.
  ///
  /// On success returns an [AuthResponse] from Supabase containing session
  /// and user data. On failure returns a failed [FutureResult] with error
  /// details (invalid/expired OTP, network error, etc.).
  ///
  /// Params:
  /// - `phoneNumber`: the phone number that received the OTP.
  /// - `otp`: the one-time password code to verify.
  FutureResult<AuthResponse> verifyPhoneOtp({
    required String phoneNumber,
    required String otp,
  });

  /// Requests the backend to resend an OTP to the given `phoneNumber`.
  ///
  /// Returns success when the resend request is accepted or a failure
  /// describing why it couldn't be resent (rate limit, invalid phone, etc.).
  FutureResult<void> resendPhoneOtp({required String phoneNumber});

  /// Signs out the current authenticated user.
  ///
  /// Returns a successful [FutureResult] on successful sign-out or a
  /// failure if sign-out couldn't be completed.
  FutureResult<void> signOut();

  /// Validates that the current session is still valid by attempting to
  /// refresh it.
  ///
  /// This is useful to detect if a user was deleted externally (e.g., from
  /// Supabase dashboard) or if the session has been invalidated.
  ///
  /// Returns an [AuthResponse] with the refreshed session data on success,
  /// or throws an exception if the session is invalid.
  FutureResult<AuthResponse> validateSession();

  /// Deletes the current authenticated user account.
  ///
  /// This calls the Supabase function 'delete_current_user' to permanently
  /// delete the user account and all associated data.
  ///
  /// Returns a successful [FutureResult] on successful deletion or a
  /// failure if deletion couldn't be completed.
  FutureResult<void> deleteAccount();
}
