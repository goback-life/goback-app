# Auth Feature

Provides authentication primitives (OTP sign-in, verification, resend, sign-out and auth state) used across the app. This feature wraps the Supabase auth client into a small, testable `AuthService`.

## Configuration

Requires the Supabase integration to be configured. The auth feature expects a working `SupabaseClient` to be provided by the app's dependency injection/startup system.

## Usage

Example with Riverpod providers for use-cases:

```dart
// Request OTP (use-case provider)
final signInResult = await ref.read(signInProvider.notifier).call('+391234567890');

// Verify OTP (use-case provider)
final verifyResult = await ref.read(verifyPhoneOtpProvider.notifier).call(
  # Auth Feature

  Provides authentication primitives (OTP sign-in, verification, resend, sign-out and auth state) used across the app. This feature wraps the Supabase auth client into a small, testable `AuthService`.

  ## Configuration

  Requires the Supabase integration to be configured. The auth feature expects a working `SupabaseClient` to be provided by the app's dependency injection/startup system.

  ## Usage

  Example with Riverpod providers for use-cases:

  ```dart
  // Request OTP (use-case provider)
  final signInResult = await ref.read(signInProvider.notifier).call('+391234567890');

  // Verify OTP (use-case provider)
  final verifyResult = await ref.read(verifyPhoneOtpProvider.notifier).call(
    '+391234567890',
    '123456',
  );

  // Resend OTP
  final resendResult = await ref.read(resendPhoneOtpProvider.notifier).call('+391234567890');

  // Sign out
  final signOutResult = await ref.read(signOutProvider.notifier).call();

  // Check auth state (sync)
  final bool isAuthenticated = ref.read(isAuthenticatedProvider);

  // Listen to auth changes (stream provider)
  ref.read(isAuthenticatedStreamProvider).listen((isAuth) {
    // react to auth changes
  });

  // Check if objective is completed (async Result)
  final hasCompletedObjectiveResult = await ref.read(hasCompletedObjectiveProvider.future);
  hasCompletedObjectiveResult.fold(
    (hasCompletedObjective) {
      // hasCompletedObjective is a bool
    },
    (error) {
      // Handle error
    },
  );

  // Get current user
  final currentUserResult = await ref.read(getCurrentUserProvider.future);
  currentUserResult.fold(
    # Auth Feature

    Provides authentication primitives (OTP sign-in, verification, resend, sign-out and auth state) used across the app. This feature wraps the Supabase auth client into a small, testable `AuthService`.

    ## Configuration

    Requires the Supabase integration to be configured. The auth feature expects a working `SupabaseClient` to be provided by the app's dependency injection/startup system.

    ## Usage

    Example with Riverpod providers for use-cases:

    ```dart
    // Request OTP (use-case provider)
    final signInResult = await ref.read(signInProvider.notifier).call('+391234567890');

    // Verify OTP (use-case provider)
    final verifyResult = await ref.read(verifyPhoneOtpProvider.notifier).call(
      '+391234567890',
      '123456',
    );

    // Resend OTP
    final resendResult = await ref.read(resendPhoneOtpProvider.notifier).call('+391234567890');

    // Sign out
    final signOutResult = await ref.read(signOutProvider.notifier).call();

    // Check auth state (sync)
    final bool isAuthenticated = ref.read(isAuthenticatedProvider);

    // Listen to auth changes (stream provider)
    ref.read(isAuthenticatedStreamProvider).listen((isAuth) {
      // react to auth changes
    });

    // Check if profile is completed (async Result)
    final hasCompletedProfileResult = await ref.read(hasCompletedProfileProvider.future);
    hasCompletedProfileResult.fold(
      (hasCompleted) {
        // hasCompleted is a bool
      },
      (error) {
        // Handle error
      },
    );

    // Get current user
    final currentUserResult = await ref.read(getCurrentUserProvider.future);
    currentUserResult.fold(
      (user) {
        if (user != null) {
          // Handle user found
          print('Current user ID: ${user.id}');
        } else {
          // No user logged in
        }
      },
      (error) {
        // Handle error
      },
    );
    ```

    ## Error handling

    The auth feature implements a comprehensive error handling system with multiple layers:

### Custom Domain Exceptions

- `AuthException` - Base class for all auth-related errors
- `InvalidPhoneException` - Thrown when the phone number format is invalid
- `OtpVerificationException` - Thrown when the OTP is invalid or expired    ### Result Pattern

    - All async methods return `Result<T>` instead of throwing exceptions
    - Success cases: `Result.success(value)`
    - Error cases: `Result.failure(exception)`

    ### Exception Mapping

    - Supabase exceptions are automatically mapped to domain exceptions via dedicated mappers

    ### Automatic UI Error Handling

    - Network errors (`SocketException`, `TimeoutException`) are handled by `CommonSupabaseExceptionUIHandler`
    - Rate limiting (`TooManyRequestsException`) is automatically detected and handled
    - UI shows appropriate error dialogs without manual intervention

    ### Usage Pattern

    ```dart
    final result = await ref.read(signInProvider.notifier).call(phone);
    result.fold(
      (value) => // handle success
      (error) => // handle failure
    );
    ```
