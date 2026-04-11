import 'dart:async';

import 'package:cloudless/core/exceptions/network_connection_exception.dart';
import 'package:cloudless/core/exceptions/request_timeout_exception.dart';
import 'package:cloudless/core/exceptions/too_many_requests_exception.dart';
import 'package:cloudless/core/features/auth/data/providers/auth_repository_provider.dart';
import 'package:cloudless/core/features/auth/data/storables/objective_completed_storable.dart';
import 'package:cloudless/core/features/lockout/data/storables/manual_lockout_storable.dart';
import 'package:cloudless/core/features/auth/domain/providers/is_authenticated_provider.dart';
import 'package:cloudless/core/features/auth/domain/providers/is_authenticated_stream_provider.dart';
import 'package:cloudless/core/features/calendar/domain/providers/calendar_posts_cache_provider.dart';
import 'package:cloudless/core/features/profile/data/storables/profile_completed_storable.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/has_completed_profile_provider.dart';
import 'package:cloudless/presentation/pages/create_profile/create_profile_routable.dart';
import 'package:cloudless/presentation/pages/manual_lockout/manual_lockout_routable.dart';
import 'package:cloudless/presentation/pages/objective/objective_routable.dart';
import 'package:cloudless/presentation/pages/otp/otp_routable.dart';
import 'package:cloudless/presentation/pages/sign_in/sign_in_routable.dart';
import 'package:cloudless/presentation/pages/tutorial/tutorial_routable.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/widgets.dart';

class AuthNavigationFlowMiddleware extends Middleware {
  AuthNavigationFlowMiddleware._();

  factory AuthNavigationFlowMiddleware() {
    return _instance ??= AuthNavigationFlowMiddleware._();
  }
  static AuthNavigationFlowMiddleware? _instance;
  bool _isListenerSetup = false;
  DateTime? _lastSessionCheck;
  Timer? _logoutDebounce;

  // Cache duration to avoid repeated session checks
  static const Duration _checkCooldown = Duration(seconds: 30);

  // Debounce to avoid reacting to transient auth state blips (e.g. during
  // OTP verification where Supabase may emit a momentary false).
  static const Duration _logoutDebounceDuration = Duration(seconds: 2);

  void _setupReactiveAuth() {
    if (_isListenerSetup) {
      return; // Avoid multiple listeners
    }
    _isListenerSetup = true;

    // Use a delayed setup to ensure Supabase and riverpodContainer are available
    Timer(const Duration(milliseconds: 100), () {
      try {
        final container = riverpodContainer();

        // Listen to auth changes and trigger navigation when user loses auth.
        // Uses a debounce to avoid reacting to transient false states during
        // sign-in/OTP verification.
        container.listen(isAuthenticatedStreamProvider, (previous, next) {
          next.whenData((isAuth) {
            if (!isAuth && (previous?.value == true)) {
              _logoutDebounce?.cancel();
              _logoutDebounce = Timer(_logoutDebounceDuration, () {
                // Re-check auth state after debounce — if it recovered, skip.
                final stillUnauthenticated = !container.read(
                  isAuthenticatedProvider,
                );
                if (!stillUnauthenticated) return;

                container
                    .read(calendarPostsCacheProvider.notifier)
                    .clearCache();
                container.invalidate(getProfileProvider);
                final _ = ProfileCompletedStorable()..set(false);

                router.go(const SignInRoutable());
              });
            } else if (isAuth) {
              // Auth recovered — cancel any pending logout redirect.
              _logoutDebounce?.cancel();
            }
          });
        });
      } catch (e) {
        // Retry after a longer delay if Supabase isn't ready
        Timer(const Duration(seconds: 2), _setupReactiveAuth);
      }
    });
  }

  @override
  List<Routable> get excludedRoutes => [
    const ObjectiveRoutable(),
    const SignInRoutable(),
    const OtpRoutable(),
    const CreateProfileRoutable(),
    const ManualLockoutRoutable(),
    const TutorialRoutable(),
  ];

  @override
  Future<Routable?> handle(
    BuildContext context,
    CustomRouterState state,
  ) async {
    final container = riverpodContainer();

    // Setup reactive auth listener on first handle() call (if not already setup)
    _setupReactiveAuth();

    final objectiveStorable = ObjectiveCompletedStorable();
    final hasCompletedObjective = await objectiveStorable.get(
      defaultValue: false,
    );

    if (!hasCompletedObjective) {
      return const ObjectiveRoutable();
    }

    final isAuthenticated = container.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      container.read(calendarPostsCacheProvider.notifier).clearCache();
      container.invalidate(getProfileProvider);

      // Reset local profile completed flag on sign out
      final profileCompletedStorable = ProfileCompletedStorable();
      await profileCompletedStorable.set(false);
      return const SignInRoutable();
    }

    // Validate session periodically to catch deleted users or expired sessions.
    // Skip the very first check — right after OTP verification the session
    // object may not be fully synchronised yet, and the isAuthenticated guard
    // above already confirmed currentUser != null.
    final now = DateTime.now();
    _lastSessionCheck ??= now;
    final needsCheck = now.difference(_lastSessionCheck!) > _checkCooldown;

    if (needsCheck) {
      _lastSessionCheck = now;

      // Validate session
      final authRepository = container.read(authRepositoryProvider);
      final sessionResult = await authRepository.validateSession();

      // Check if the session is invalid (user deleted or session expired)
      final shouldLogout = sessionResult.fold(
        (isValid) {
          return !isValid; // If not valid, logout is needed
        },
        (error) {
          return true; // Session invalid, logout needed
        },
      );

      if (shouldLogout) {
        container.read(calendarPostsCacheProvider.notifier).clearCache();
        container.invalidate(getProfileProvider);
        final profileCompletedStorable = ProfileCompletedStorable();
        await profileCompletedStorable.set(false);
        return const SignInRoutable();
      }
    }

    // Check if user is currently locked out (mirrors old TimeLimitMiddleware).
    final lockoutStorable = ManualLockoutStorable();
    final isLockedOut = await lockoutStorable.isLockedOut();
    if (isLockedOut) {
      return const ManualLockoutRoutable();
    }

    // Check local boolean first to avoid network calls
    final profileCompletedStorable = ProfileCompletedStorable();
    final localProfileCompleted = await profileCompletedStorable.get(
      defaultValue: false,
    );

    if (localProfileCompleted) {
      // Profile was previously completed, skip remote check
      return null;
    }

    // Fallback: perform remote check as before
    final hasCompletedProfileResult = await container.read(
      hasCompletedProfileProvider.future,
    );

    bool hasCompletedProfile = false;
    bool hasNetworkError = false;

    hasCompletedProfileResult.fold(
      (value) {
        hasCompletedProfile = value;
        // If remote confirms profile is completed, save locally for future offline access
        if (value) {
          profileCompletedStorable.set(true);
        }
      },
      (error) {
        if (error is NetworkConnectionException ||
            error is RequestTimeoutException ||
            error is TooManyRequestsException) {
          hasNetworkError = true;
        }

        hasCompletedProfile = false;
      },
    );

    // If there was a network error, don't force redirect to CreateProfile
    // This prevents the offline loop issue
    if (hasNetworkError) {
      return null; // Stay on current route or show offline indicator
    }

    if (!hasCompletedProfile) {
      return const CreateProfileRoutable();
    }

    return null;
  }
}
