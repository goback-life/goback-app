import 'package:cloudless/core/features/auth/domain/providers/is_authenticated_provider.dart';
import 'package:cloudless/core/features/auth/domain/providers/validate_session_provider.dart';
import 'package:cloudless/core/features/calendar/domain/providers/calendar_posts_cache_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/profile/data/storables/profile_completed_storable.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/presentation/pages/objective/objective_routable.dart';
import 'package:cloudless/presentation/pages/sign_in/sign_in_routable.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/widgets.dart';

class AuthenticationBackgroundHandler with WidgetsBindingObserver {
  AuthenticationBackgroundHandler(this.ref);
  final WidgetRef ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAuthenticationOnAppResume();
    }
  }

  Future<void> _checkAuthenticationOnAppResume() async {
    logger.info('App resume: checking authentication status');

    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      logger.info('App resume: user not authenticated');
      // Skip validation if already on auth screens
      if (router.stack.firstOrNull == const SignInRoutable().path ||
          router.stack.firstOrNull == const ObjectiveRoutable().path) {
        return;
      }
      // Clear calendar cache on logout
      ref.read(calendarPostsCacheProvider.notifier).clearCache();
      ref.invalidate(getProfileProvider);
      router.go(const SignInRoutable());
      return;
    }

    // User is authenticated, validate the session
    logger.info('App resume: user authenticated, validating session');

    final sessionResult = await ref.read(validateSessionProvider.future);
    sessionResult.fold(
      (isValid) {
        if (isValid) {
          logger.info('App resume: Session validated successfully');
          // Refresh circle members to re-fetch any failed avatars
          // This is especially important after network errors when app was in background
          ref.invalidate(getCircleMembersProvider);
        } else {
          _handleInvalidSession();
        }
      },
      (error) {
        logger.error('App resume: Session validation failed', exception: error);
        _handleInvalidSession();
      },
    );
  }

  Future<void> _handleInvalidSession() async {
    logger.info('Handling invalid session - clearing state and redirecting');

    // Clear calendar cache when session is invalid
    ref.read(calendarPostsCacheProvider.notifier).clearCache();
    ref.invalidate(getProfileProvider);

    final profileCompletedStorable = ProfileCompletedStorable();
    await profileCompletedStorable.set(false);

    router.go(const SignInRoutable());
  }
}
