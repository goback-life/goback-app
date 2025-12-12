import 'package:cloudless/core/exceptions/network_connection_exception.dart';
import 'package:cloudless/core/exceptions/request_timeout_exception.dart';
import 'package:cloudless/core/exceptions/too_many_requests_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_user_not_found_exception.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/core/features/supabase/domain/contracts/common_supabase_exception_ui_handler_contract.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/pages/sign_in/sign_in_routable.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class CommonSupabaseExceptionUIHandler
    implements CommonSupabaseExceptionUIHandlerContract {
  CommonSupabaseExceptionUIHandler();

  @override
  bool handleSupabaseException({
    required BuildContext context,
    required Exception exception,
  }) {
    switch (exception) {
      case AuthUserNotFoundException():
        logger.error('User not found - redirecting to sign in');
        _handleUserNotFound(context);
        return true;

      case TooManyRequestsException():
        logger.error('Too many requests');
        _showError(
          context: context,
          titleKey: 'components.alert.too_many_requests.title',
          contentKey: 'components.alert.too_many_requests.content',
        );
        return true;

      case NetworkConnectionException():
        logger.error('Network unreachable');
        _showError(
          context: context,
          titleKey: 'components.alert.connection_error.title',
          contentKey: 'components.alert.connection_error.content',
        );
        return true;

      case RequestTimeoutException():
        logger.error('Request timed out');
        _showError(
          context: context,
          titleKey: 'components.alert.connection_error.title',
          contentKey: 'components.alert.connection_error.content',
        );
        return true;

      default:
        return false;
    }
  }

  void _handleUserNotFound(BuildContext context) {
    // Show alert to inform user that session has expired
    _showError(
      context: context,
      titleKey: 'components.alert.session_expired.title',
      contentKey: 'components.alert.session_expired.content',
    );

    // Invalidate profile provider when session expires
    riverpodContainer().invalidate(getProfileProvider);

    // Navigate to sign in page after a brief delay to allow user to see the alert
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        router.go(const SignInRoutable());
      }
    });
  }

  void _showError({
    required BuildContext context,
    required String titleKey,
    required String contentKey,
    String? extra,
  }) {
    final title = translator.translate(titleKey);
    final contentBase = translator.translate(contentKey);
    final content = (extra == null || extra.trim().isEmpty)
        ? contentBase
        : '$contentBase\n\n$extra';

    MainAlert.showError(context: context, title: title, content: content);
  }
}
